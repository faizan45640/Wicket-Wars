# Wicket Wars: Firebase + Flutter (for backend developers)

This document explains how the Wicket Wars Flutter app talks to Firebase, how the code is organised, and how that maps to concepts you already know from **Node.js** backends.

---

## The big picture

The app is a **client** (mobile/desktop/web UI) built with **Flutter** (Dart language). It does not run your game logic on a server you own unless you add Cloud Functions later. Today:

- **Firebase Authentication** verifies who the user is (email + password).
- **Cloud Firestore** is the database: documents and collections, queried from the app with security rules enforcing access.

Think of it as a **single-page app** that happens to be compiled to native UI, using Firebase instead of your own Express + Postgres stack for auth and data.

---

## Node.js analogies (mental map)

| Backend / Node mental model | What it is in this Flutter project |
|----------------------------|-------------------------------------|
| **Express `app.get/post`** routes | **`GoRouter`** in `lib/app_router.dart` — URL paths like `/login`, `/`, `/squad` map to **screens** (widgets), not JSON handlers. |
| **Session cookie / JWT middleware** | **Firebase Auth**: `FirebaseAuth.instance.currentUser` is “who is logged in”. `GoRouter`’s `redirect` sends guests to `/login`. **`go_router_auth_refresh.dart`** listens to `authStateChanges()` so the router updates after login/logout (similar to renewing session state). |
| **Service layer / repositories** | **`lib/data/repositories/`** — Dart **interfaces** (`UserRepository`, `SquadRepository`, …) with **implementations** that read/write Firestore. In Node you might have `userService.getProfile()`; here it is `userRepository.watchProfile(uid)`. |
| **Dependency injection** (e.g. passing `db` into services) | **Riverpod** `Provider`s in `lib/data/providers.dart`. They construct `FirebaseUserRepository()`, etc., so screens can `ref.watch(userProfileProvider)` without importing Firestore directly. Closest Node parallel: a small DI container or injecting services into route handlers. |
| **MongoDB / document DB** | **Firestore** — collections and documents, JSON-like fields, real-time listeners. |
| **`db.collection('x').onSnapshot()`** (live updates) | **`DocumentReference.snapshots()`** / **`Query.snapshots()`** in Dart — streams that emit whenever data changes. Riverpod often exposes these as `StreamProvider`s. |
| **`.env` + config** | **`firebase_options.dart`** (Dart constants) + Android **`google-services.json`**. Created from the Firebase project; tells the SDK which Firebase project to use. |
| **In-memory DB for tests** | **`lib/data/placeholder/`** — fake repositories (`PlaceholderUserRepository`, …). **`test/widget_test.dart`** **overrides** Riverpod providers so tests do not hit the real network/Firestore. |

---

## Flutter-specific ideas (short)

- **Widget** — A piece of UI (like a component). `StatelessWidget` / `ConsumerWidget` rebuild when their data changes.
- **`async`/`await`** — Same idea as in JavaScript; many Firebase calls return `Future`s.
- **Streams** — Async sequences (like RxJS observables or Node streams used for events). Firestore “live listeners” are exposed as streams in Dart.

---

## What we added for Firebase (auth + Firestore)

### 1. Dependencies (`pubspec.yaml`)

- **`firebase_core`** — Bootstraps Firebase in `main()`.
- **`firebase_auth`** — Sign up, sign in, sign out, `authStateChanges`.
- **`cloud_firestore`** — Read/write/listen to documents.

### 2. Startup (`lib/main.dart`)

Roughly equivalent to “connect to DB before listening on port”:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
3. `goRouterAuthRefresh.listenToAuth()` so navigation reacts to auth
4. `runApp(ProviderScope(child: MyApp()))`

### 3. Auth (`lib/data/repositories/auth_repository.dart`, `firebase_auth_repository.dart`)

- Interface: `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `signOut`, `watchAuthState`.
- **`FirebaseAuthRepository`** implements it with `FirebaseAuth`.
- **`go_router`** redirect uses **`FirebaseAuth.instance.currentUser != null`** as “logged in”.

### 4. Firestore paths (schema-ish)

Canonical paths live in **`lib/data/firestore_paths.dart`** (like a shared constants file for table names):

| Path | Purpose |
|------|---------|
| `users/{uid}` | User profile (coins, `dailyStreak`, `lastDailyRewardClaimAt`, league, stats, …). Claiming daily reward may also **`upsert` a squad player** on every 4th streak day. |
| `users/{uid}/players/{playerId}` | Squad cards. Fields include `isRealPlayer`, `playerTier` (`free` \| `premium`), optional `catalogPlayerId`, `attributes`, optional `training`. |
| `players_catalog/{catalogId}` | Read-only templates for licensed / premium cards (seed in Console). Clients listen via **`FirebasePlayersCatalogRepository`**. |
| `users/{uid}/matchHistory/{matchId}` | Past matches for that user |
| `matchRooms/{roomId}` | Online match lobby / room state |
| `leaderboard/{uid}` | One row per user for ranking (denormalised from profile on write) |

### 5. Firestore implementations (`lib/data/repositories/firebase_*_repository.dart`)

- **`FirebaseUserRepository`** — Reads/writes `users/{uid}`. If the profile doc is missing, it **seeds** default stats once and **merges** a **`leaderboard/{uid}`** row (so new users can appear on the leaderboard).
- **`FirebaseSquadRepository`** — `users/{uid}/players` subcollection.
- **`FirebasePlayersCatalogRepository`** — `players_catalog`; **read-only** for app users (writes via Console or Admin SDK).
- **`FirebaseMatchRepository`** — `matchRooms/{roomId}`; `createRoom` generates a short code and avoids collisions with retries. **`transactRoom`** runs a Firestore **transaction** so concurrent “next delivery” taps from two devices merge correctly (retry on contention).
- **`FirebaseLeaderboardRepository`** — Queries `leaderboard` ordered by `rankingPoints` descending.
- **`FirebaseMatchHistoryRepository`** — `users/{uid}/matchHistory`, ordered by `completedAt`.

**Timestamp handling:** Firestore stores dates as `Timestamp`. **`lib/data/firestore/firestore_codec.dart`** converts them to ISO strings so existing `fromMap` factories (written for JSON-style data) keep working — similar to normalising a row in a repository before returning a domain object.

**Typed refs:** **`lib/data/firestore/firestore_refs.dart`** adds extension methods on `FirebaseFirestore` so paths are not copy-pasted (like a thin table accessor).

### 6. Wiring the UI to live data

- **`HomeScreen`** — `ConsumerWidget`; uses **`userProfileProvider`** (backed by `FirebaseUserRepository.watchProfile`).
- **`SquadScreen`** / **`PlayerDetailScreen`** — **`squadProvider(uid)`**; only **`playerTier: free`** and **`isRealPlayer: false`** may use train / coin-upgrade in the UI (premium and real cards are stat-locked).
- **`LeaderboardScreen`** — **GLOBAL** uses **`leaderboardTopProvider`**; **FRIENDS** lists you plus opponents from **`matchHistoryProvider`**, with points taken from global rows when **display names** match.

### 7. Riverpod (`lib/data/providers.dart`)

Production providers return **`Firebase*Repository`**. For **widget tests**, **`test/widget_test.dart`** uses **`ProviderScope(overrides: [...])`** to inject **`Placeholder*Repository`** so the CI machine does not need Firestore or real credentials — same idea as mocking `userService` in a Jest test.

---

## Firestore security rules (you must set these in Firebase Console)

The app will be **denied** reads/writes if rules default to “closed”. A **starting point** for development (tighten before production):

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /players/{playerId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /matchHistory/{mId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    match /matchRooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }

    match /leaderboard/{entryId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == entryId;
    }

    // Seed from Firebase Console / Admin SDK only — clients must not create fake catalog entries.
    match /players_catalog/{catalogId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### Example `players_catalog` document

Create a document ID (e.g. `ace_batter_01`) with fields aligned to **`CatalogPlayer`** / **`CricketPlayer`** maps:

```json
{
  "displayName": "Demo Licensed Ace",
  "isRealPlayer": true,
  "playerTier": "premium",
  "cardImageAsset": null,
  "attributes": {
    "batting": 84,
    "bowling": 68,
    "fielding": 78,
    "stamina": 80,
    "consistency": 76
  }
}
```

When you add an **unlock** or **copy-to-squad** flow, create `users/{uid}/players/{newId}` with the same shape plus **`catalogPlayerId`** set to the catalog doc id.

**Production** should narrow `matchRooms` updates (e.g. only `hostUid` / `guestUid`) and decide if `leaderboard` is readable by everyone or only signed-in users.

---

## Indexes

Firestore may prompt you to create a **composite index** if you add queries that combine filters and `orderBy`. The leaderboard query uses **`orderBy('rankingPoints', descending: true)`** — usually fine with automatic single-field indexing. Match history uses **`orderBy('completedAt', descending: true)`** on a subcollection — create the index if the console link appears in an error message.

---

## Summary

- **Auth** = who you are (`FirebaseAuth`).
- **Firestore** = JSON documents + real-time listeners (`snapshots()`).
- **Repositories** = your “data access layer”; **Riverpod** = how the UI gets them.
- **Node analogy**: replace Express routes + session + `UserService` + Mongo driver with **GoRouter + FirebaseAuth + Repositories + Firestore**.

If you add **Cloud Functions** later, that is your place for trusted server logic (anti-cheat, aggregates, webhooks) — the Flutter app stays a thin client talking to Auth, Firestore, and HTTPS callable functions.
