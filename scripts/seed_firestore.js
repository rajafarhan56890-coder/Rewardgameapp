/**
 * One-time setup script: seeds Firestore with the remote app config
 * (conversion rate, minimum withdrawal, daily reward base, referral bonus)
 * plus a few starter games and cash tasks so the app isn't empty on first
 * run.
 *
 * Usage:
 *   1. npm install firebase-admin
 *   2. Download a service account key from Firebase Console ->
 *      Project Settings -> Service Accounts -> Generate new private key.
 *      Save it as ./serviceAccountKey.json (DO NOT commit this file).
 *   3. node scripts/seed_firestore.js
 */

const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seed() {
  // ---- Remote, changeable-without-app-update configuration ----
  await db.collection("config").doc("app_config").set({
    cashPointsPerUnit: 200, // 200 cash points
    cashUnitValuePkr: 50, // = Rs. 50
    minWithdrawalPkr: 100,
    dailyBaseCoins: 10,
    referralBonusCoins: 100,
    maintenanceMode: false,
  });
  console.log("✔ config/app_config seeded");

  // ---- Starter games (coins) ----
  const games = [
    {
      id: "spin_wheel",
      title: "Lucky Spin Wheel",
      description: "Spin the wheel once a day for a chance to win bonus coins.",
      iconUrl: "",
      rewardCoins: 25,
      isActive: true,
      cooldownType: "daily",
    },
    {
      id: "quiz_challenge",
      title: "Daily Quiz Challenge",
      description: "Answer 5 trivia questions correctly to earn coins.",
      iconUrl: "",
      rewardCoins: 40,
      isActive: true,
      cooldownType: "daily",
    },
    {
      id: "match_puzzle",
      title: "Match-3 Puzzle",
      description: "Complete one puzzle level to claim your reward.",
      iconUrl: "",
      rewardCoins: 30,
      isActive: true,
      cooldownType: "daily",
    },
    {
      id: "welcome_task",
      title: "Complete Your Profile",
      description: "One-time reward for adding a profile picture and username.",
      iconUrl: "",
      rewardCoins: 50,
      isActive: true,
      cooldownType: "once",
    },
  ];
  for (const game of games) {
    const { id, ...data } = game;
    await db.collection("games").doc(id).set(data);
  }
  console.log(`✔ ${games.length} games seeded`);

  // ---- Starter cash tasks (cash points) ----
  const cashTasks = [
    {
      id: "survey_1",
      title: "Complete a Short Survey",
      description: "Share your feedback in a 2-minute survey.",
      iconUrl: "",
      rewardCashPoints: 40,
      isActive: true,
      cooldownType: "once",
    },
    {
      id: "watch_ad_offer",
      title: "Watch & Earn",
      description: "Watch a short rewarded video to earn cash points.",
      iconUrl: "",
      rewardCashPoints: 10,
      isActive: true,
      cooldownType: "daily",
    },
    {
      id: "app_install_offer",
      title: "Try a Partner App",
      description: "Install and open a partner app to earn a larger cash reward.",
      iconUrl: "",
      rewardCashPoints: 150,
      isActive: true,
      cooldownType: "once",
    },
  ];
  for (const task of cashTasks) {
    const { id, ...data } = task;
    await db.collection("cash_tasks").doc(id).set(data);
  }
  console.log(`✔ ${cashTasks.length} cash tasks seeded`);

  console.log("\nAll done! Your app now has starter config, games, and cash tasks.");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
