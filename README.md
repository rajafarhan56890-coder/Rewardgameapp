# CoinVault Rewards

A premium, dark-themed Flutter + Firebase rewards app: users earn **coins**
(via games) and **cash points** (via cash tasks) as two fully separate
currencies, check in daily for streak bonuses, refer friends, and withdraw
cash points to JazzCash / Easypaisa / bank transfer at an admin-configurable
conversion rate.

---

## 1. Architecture

```
lib/
  core/            Theme, constants, validators, Result<T> error handling, shared widgets
  data/
    models/        Plain Dart models (UserModel, TransactionModel, GameModel, ...)
    repositories/  All Firebase access — the only layer that talks to Firebase
  presentation/
    providers/     ChangeNotifier state classes (Provider package)
    screens/       UI, organized by feature
```

This is a standard **clean architecture / layered** approach:
`UI -> Provider -> Repository -> Firebase`. Screens never call Firebase
directly; they call a Provider method, which calls a Repository method,
which returns a `Result<T>` (never throws), so the UI layer only ever
handles a success/failure pair.

---

## 2. Firebase setup (required before running)

1. Create a Firebase project at https://console.firebase.google.com.
2. Add an Android app with package name `com.coinvault.rewards_app`
   (or change `applicationId`/`namespace` in `android/app/build.gradle`
   and the Kotlin package folder to your own).
3. Download `google-services.json` and place it at
   `android/app/google-services.json`.
4. In the Firebase Console, enable:
   - **Authentication** → Email/Password provider
   - **Cloud Firestore** → create database (production mode)
   - **Storage** → create default bucket
   - **Cloud Messaging** → no setup needed, works automatically once the app is registered
5. Deploy the security rules and indexes included in this repo:
   ```
   npm install -g firebase-tools
   firebase login
   firebase use --add        # select your project
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```
6. Seed starter data (app config + sample games/tasks):
   ```
   cd scripts
   npm init -y && npm install firebase-admin
   # place your service account key as scripts/serviceAccountKey.json
   node seed_firestore.js
   ```
7. Install Flutter deps and run:
   ```
   flutter pub get
   flutter run
   ```

That's it — no `firebase_options.dart` is needed for Android-only builds;
`firebase_core` reads configuration from `google-services.json` automatically
via the Google Services Gradle plugin already wired into
`android/build.gradle` / `android/app/build.gradle`.

---

## 3. Firestore data model

| Collection | Purpose |
|---|---|
| `users/{uid}` | profile, `coins` (int), `cashPoints` (double), referral info |
| `users/{uid}/transactions/{id}` | append-only ledger for both currencies |
| `users/{uid}/notifications/{id}` | in-app notification feed |
| `games/{id}` | admin-managed game catalog (coins) |
| `cash_tasks/{id}` | admin-managed cash-task catalog (cash points) |
| `game_completions/{uid_gameId[_date]}` | deterministic-ID duplicate-claim guard |
| `cash_task_completions/{uid_taskId[_date]}` | same, for cash tasks |
| `withdrawals/{id}` | withdrawal requests, `status: pending/approved/rejected` |
| `referrals/{id}` | referral relationships, `status: pending/rewarded` |
| `daily_rewards/{uid}` | `lastClaimDate`, `streak` |
| `config/app_config` | **live-editable** conversion rate & reward config (see below) |

### Changing the conversion rate without an app update
Edit `config/app_config` in the Firebase Console (or via the seed script):
```json
{ "cashPointsPerUnit": 200, "cashUnitValuePkr": 50 }
```
means 200 cash points = Rs. 50. The app streams this document live, so
existing installs update immediately — no release required.

---

## 4. Security model — what's enforced where, and the one honest gap

- **Firestore rules** (`firestore.rules`) block all cross-user reads/writes,
  make transaction/notification history append-only, and — critically —
  make `game_completions` / `cash_task_completions` **create-only** documents
  with deterministic IDs (`{uid}_{itemId}` or `{uid}_{itemId}_{date}`). That
  ID scheme is what actually prevents duplicate reward claims: a second
  "create" for the same key is rejected by Firestore itself, not just by a
  client-side check.
- **Firestore transactions** in every repository method (`WalletRepository`,
  `GamesRepository`, `DailyRewardRepository`, `WithdrawalRepository`) make
  balance reads+writes atomic, preventing race conditions like two
  withdrawal requests overdrawing the same balance.
- **The honest gap:** pure client-side Firestore rules cannot fully stop a
  modified/rooted client from writing an arbitrary number to
  `users/{uid}.coins` directly, because rules can express "who can write"
  and basic shape/diff constraints, but not full custom business logic. The
  `functions/` folder in this repo contains a **complete, ready-to-deploy**
  Cloud Functions layer (`claimGameReward`, `claimDailyReward`,
  `onWithdrawalStatusChange`, `onFirstRewardCheckReferral`) that closes this
  gap entirely — once deployed, lock the `coins`/`cashPoints` fields out of
  client `update` rules (see the comment at the top of `firestore.rules`)
  and switch the app to call these functions instead of writing directly.
  This is the standard production pattern for any real-money rewards app;
  it's provided but not force-enabled by default so the app also works
  fully offline-from-a-backend-team, using pure client+rules security, for
  demos/prototyping.

---

## 5. Admin panel (not included, by design)

This repo is the **user-facing app**. Approving/rejecting withdrawals,
managing the games/cash-task catalog, and editing `config/app_config` are
all designed to be done via the **Firebase Console** directly today (every
collection is plain, flat, and console-editable), and are structured so a
future admin web panel (e.g. a small React/Flutter-Web app using the Admin
SDK or these same Cloud Functions) can be bolted on without touching this
app's code or data model.

---

## 6. What you still need to do before shipping to the Play Store

- Replace the placeholder launcher icon (`android/app/src/main/res/mipmap-*`)
  and splash logo (`assets/images/splash_logo.png`) with your real brand
  assets — the included ones are simple generated placeholders.
- Generate a real upload keystore and wire it into
  `android/app/build.gradle`'s `signingConfigs.release` (currently signs
  release builds with the debug key so `flutter build apk --release` works
  out of the box for testing).
- Run `flutter pub get`, `flutter analyze`, and test on a real device/
  emulator — this was written and reviewed carefully but not compiled in
  this environment (no Flutter SDK / Android toolchain available here), so
  treat the first `flutter run` as your integration test pass.
- Populate real game/cash-task content — the seed script gives you four
  starter games and three starter cash tasks as examples.
- Decide on your JazzCash/Easypaisa/bank payout process — this app collects
  and stores withdrawal requests; actually disbursing funds is a manual or
  separately-integrated process, same as most reward apps at this stage.
- If you want push notifications to actually reach devices (not just be
  stored in Firestore), send them via the Firebase Console's Cloud
  Messaging composer, or extend `functions/src/index.ts` to call
  `admin.messaging().send(...)` using each user's stored `fcmToken`.

---

## 7. Tech stack

Flutter (Dart) · Firebase Auth · Cloud Firestore · Firebase Storage ·
Firebase Cloud Messaging · Provider (state management) · Cloud Functions
(optional, recommended for production balance security)
