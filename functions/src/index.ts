import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

admin.initializeApp();
const db = admin.firestore();

/**
 * ============================================================================
 * PRODUCTION HARDENING LAYER
 * ============================================================================
 * These callable functions mirror the client-side repository logic in the
 * Flutter app (see lib/data/repositories/*.dart) but run with the Admin SDK,
 * which bypasses Firestore security rules entirely. Once these are deployed,
 * lock users/{uid}.coins and users/{uid}.cashPoints so clients can no longer
 * write them directly (remove the "coins"/"cashPoints" branch from the
 * `update` rule in firestore.rules), and switch the Flutter repositories to
 * call these functions via `cloud_functions` instead of writing to Firestore
 * directly. This closes the one gap noted in firestore.rules: a modified or
 * rooted client can no longer grant itself coins/cash points no matter what
 * it sends, because the server independently re-validates the game/task/day
 * and the completion record before crediting anything.
 * ============================================================================
 */

function requireAuth(request: { auth?: { uid: string } | null }): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  return request.auth.uid;
}

function todayKey(): string {
  return new Date().toISOString().slice(0, 10); // yyyy-MM-dd (UTC)
}

/** Claim a game reward — validates the game exists/is active and that the
 * user hasn't already claimed it (today, for daily games), then atomically
 * credits coins + writes the completion + transaction records. */
export const claimGameReward = onCall(async (request) => {
  const uid = requireAuth(request);
  const gameId = request.data?.gameId as string;
  if (!gameId) throw new HttpsError("invalid-argument", "gameId is required.");

  const gameSnap = await db.collection("games").doc(gameId).get();
  if (!gameSnap.exists || gameSnap.data()?.isActive !== true) {
    throw new HttpsError("not-found", "This game is not available.");
  }
  const game = gameSnap.data()!;
  const cooldownType = game.cooldownType === "once" ? "once" : "daily";
  const completionId = cooldownType === "once" ? `${uid}_${gameId}` : `${uid}_${gameId}_${todayKey()}`;
  const completionRef = db.collection("game_completions").doc(completionId);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (txn) => {
    const [completionDoc, userDoc] = await Promise.all([txn.get(completionRef), txn.get(userRef)]);
    if (completionDoc.exists) {
      throw new HttpsError("already-exists", "You have already claimed this reward.");
    }
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User profile not found.");
    }

    const reward = Number(game.rewardCoins) || 0;
    const currentCoins = Number(userDoc.data()?.coins) || 0;

    txn.set(completionRef, {
      uid,
      gameId,
      gameTitle: game.title ?? "",
      rewardCoins: reward,
      cooldownType,
      dateKey: todayKey(),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    txn.update(userRef, { coins: currentCoins + reward });
    txn.set(userRef.collection("transactions").doc(), {
      currency: "coins",
      direction: "credit",
      amount: reward,
      title: game.title ?? "Game Reward",
      description: `Reward for completing "${game.title ?? "a game"}"`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

/** Claim a daily check-in reward with server-validated streak logic. */
export const claimDailyReward = onCall(async (request) => {
  const uid = requireAuth(request);

  const configSnap = await db.collection("config").doc("app_config").get();
  const dailyBaseCoins = Number(configSnap.data()?.dailyBaseCoins) || 10;

  const dailyRef = db.collection("daily_rewards").doc(uid);
  const userRef = db.collection("users").doc(uid);

  const rewardAmount = await db.runTransaction(async (txn) => {
    const [dailyDoc, userDoc] = await Promise.all([txn.get(dailyRef), txn.get(userRef)]);
    if (!userDoc.exists) throw new HttpsError("not-found", "User profile not found.");

    const now = new Date();
    const data = dailyDoc.data();
    const lastClaim: Date | null = data?.lastClaimDate?.toDate() ?? null;
    const currentStreak = Number(data?.streak) || 0;

    if (lastClaim && isSameUtcDay(lastClaim, now)) {
      throw new HttpsError("already-exists", "You have already claimed today's reward.");
    }

    const newStreak = lastClaim && isYesterdayUtc(lastClaim, now) ? currentStreak + 1 : 1;
    const dayInCycle = ((newStreak - 1) % 7) + 1;
    const amount = dailyBaseCoins * dayInCycle;

    txn.set(dailyRef, { lastClaimDate: admin.firestore.FieldValue.serverTimestamp(), streak: newStreak }, { merge: true });
    const currentCoins = Number(userDoc.data()?.coins) || 0;
    txn.update(userRef, { coins: currentCoins + amount });
    txn.set(userRef.collection("transactions").doc(), {
      currency: "coins",
      direction: "credit",
      amount,
      title: "Daily Check-in",
      description: `Day ${newStreak} streak reward`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return amount;
  });

  return { success: true, rewardAmount };
});

function isSameUtcDay(a: Date, b: Date): boolean {
  return a.getUTCFullYear() === b.getUTCFullYear() && a.getUTCMonth() === b.getUTCMonth() && a.getUTCDate() === b.getUTCDate();
}

function isYesterdayUtc(last: Date, now: Date): boolean {
  const yesterday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 1));
  return isSameUtcDay(last, yesterday);
}

/** When an admin (via console/admin panel) marks a withdrawal as approved
 * or rejected, notify the user. Rejections also refund the deducted cash
 * points automatically. */
export const onWithdrawalStatusChange = onDocumentUpdated("withdrawals/{withdrawalId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;

  const uid = after.uid as string;
  const userRef = db.collection("users").doc(uid);

  if (after.status === "rejected") {
    await db.runTransaction(async (txn) => {
      const userDoc = await txn.get(userRef);
      if (!userDoc.exists) return;
      const currentCash = Number(userDoc.data()?.cashPoints) || 0;
      const refund = Number(after.cashPointsDeducted) || 0;
      txn.update(userRef, { cashPoints: currentCash + refund });
      txn.set(userRef.collection("transactions").doc(), {
        currency: "cashPoints",
        direction: "credit",
        amount: refund,
        title: "Withdrawal Rejected — Refund",
        description: after.adminNote || "Your withdrawal request was rejected and refunded.",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }

  await userRef.collection("notifications").add({
    title: after.status === "approved" ? "Withdrawal Approved 🎉" : "Withdrawal Rejected",
    body:
      after.status === "approved"
        ? `Your withdrawal of Rs. ${after.amountPkr} via ${after.method} has been approved and processed.`
        : `Your withdrawal request was rejected. ${after.adminNote ? "Reason: " + after.adminNote : "Your cash points have been refunded."}`,
    type: "withdrawal",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Withdrawal ${event.params.withdrawalId} status changed to ${after.status} for user ${uid}`);
});

/** When a referred user completes their first ever reward (game or cash
 * task), mark the referral as 'rewarded' and credit the referrer's bonus
 * coins from config/app_config.referralBonusCoins. */
export const onFirstRewardCheckReferral = onDocumentUpdated("users/{uid}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const uid = event.params.uid;
  const firstEverEarn = (before.coins ?? 0) === 0 && (before.cashPoints ?? 0) === 0 &&
    ((after.coins ?? 0) > 0 || (after.cashPoints ?? 0) > 0);
  if (!firstEverEarn || !after.referredBy) return;

  const referralQuery = await db
    .collection("referrals")
    .where("referredUid", "==", uid)
    .where("status", "==", "pending")
    .limit(1)
    .get();
  if (referralQuery.empty) return;

  const referralDoc = referralQuery.docs[0];
  const referrerUid = referralDoc.data().referrerUid as string;
  const configSnap = await db.collection("config").doc("app_config").get();
  const bonus = Number(configSnap.data()?.referralBonusCoins) || 100;
  const referrerRef = db.collection("users").doc(referrerUid);

  await db.runTransaction(async (txn) => {
    const referrerDoc = await txn.get(referrerRef);
    if (!referrerDoc.exists) return;
    const currentCoins = Number(referrerDoc.data()?.coins) || 0;
    const currentCount = Number(referrerDoc.data()?.referralCount) || 0;
    txn.update(referrerRef, { coins: currentCoins + bonus, referralCount: currentCount + 1 });
    txn.update(referralDoc.ref, { status: "rewarded" });
    txn.set(referrerRef.collection("transactions").doc(), {
      currency: "coins",
      direction: "credit",
      amount: bonus,
      title: "Referral Bonus",
      description: "Your referred friend completed their first task",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    txn.set(referrerRef.collection("notifications").doc(), {
      title: "Referral Bonus Earned! 🎉",
      body: `You earned ${bonus} coins because your friend completed their first task.`,
      type: "referral",
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
});
