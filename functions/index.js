"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const REGION = "us-central1";
const GOOGLE_AI_API_KEY = defineSecret("GOOGLE_AI_API_KEY");
const GOOGLE_AI_MODELS = (process.env.GOOGLE_AI_MODELS || "gemini-2.0-flash-lite,gemma-4-26b-a4b-it,gemma-4-31b-it")
  .split(",")
  .map((model) => model.trim())
  .filter(Boolean);
const ROOM_CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const MAX_BALLS = 120;
const MAX_WICKETS = 10;
const TAIL_LIMIT = 30;
const LLM_TIMEOUT_MS = 1400;
const STARTER_PACK_LLM_TIMEOUT_MS = 25000;
const PLAYER_ROLES = new Set(["batter", "bowler", "allRounder", "wicketKeeper"]);
const PREMIUM_CATALOG = [
  {
    id: "babar_azam",
    displayName: "Babar Azam",
    role: "batter",
    country: "Pakistan",
    battingStyle: "Right-hand bat",
    bowlingStyle: "Part-time off spin",
    attributes: { batting: 88, bowling: 36, fielding: 76, stamina: 82, consistency: 88 },
    generatedBio: "Premium catalog pull: elite top-order run scorer.",
  },
  {
    id: "virat_kohli",
    displayName: "Virat Kohli",
    role: "batter",
    country: "India",
    battingStyle: "Right-hand bat",
    bowlingStyle: "Right-arm medium",
    attributes: { batting: 89, bowling: 34, fielding: 84, stamina: 86, consistency: 89 },
    generatedBio: "Premium catalog pull: chase-master batting anchor.",
  },
  {
    id: "shaheen_afridi",
    displayName: "Shaheen Afridi",
    role: "bowler",
    country: "Pakistan",
    battingStyle: "Left-hand bat",
    bowlingStyle: "Left-arm fast",
    attributes: { batting: 48, bowling: 88, fielding: 72, stamina: 84, consistency: 82 },
    generatedBio: "Premium catalog pull: new-ball wicket threat.",
  },
  {
    id: "rashid_khan",
    displayName: "Rashid Khan",
    role: "allRounder",
    country: "Afghanistan",
    battingStyle: "Right-hand bat",
    bowlingStyle: "Right-arm leg spin",
    attributes: { batting: 70, bowling: 90, fielding: 80, stamina: 84, consistency: 87 },
    generatedBio: "Premium catalog pull: elite spin all-rounder.",
  },
  {
    id: "jasprit_bumrah",
    displayName: "Jasprit Bumrah",
    role: "bowler",
    country: "India",
    battingStyle: "Right-hand bat",
    bowlingStyle: "Right-arm fast",
    attributes: { batting: 38, bowling: 91, fielding: 74, stamina: 82, consistency: 89 },
    generatedBio: "Premium catalog pull: death-over specialist.",
  },
];

exports.createMatchRoom = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  for (let i = 0; i < 12; i++) {
    const code = generateRoomCode();
    const ref = roomRef(code);
    const created = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return null;
      const room = {
        roomId: code,
        roomCode: code,
        status: "waitingGuest",
        pitch: "balanced",
        hostUid: uid,
        guestUid: null,
        hostPlayingXi: [],
        guestPlayingXi: [],
        hostXiLocked: false,
        guestXiLocked: false,
        hostRuns: 0,
        guestRuns: 0,
        hostWickets: 0,
        guestWickets: 0,
        hostLegalBalls: 0,
        guestLegalBalls: 0,
        inningsNumber: 1,
        hostBatFirst: null,
        chaseTarget: null,
        completedAt: null,
        winnerUid: null,
        resultAppliedUids: [],
        deliveryNumber: 0,
        commentaryTail: [],
      };
      tx.set(ref, room);
      return room;
    });
    if (created) return { roomId: code, roomCode: code };
  }
  throw new HttpsError("resource-exhausted", "Could not allocate a room code.");
});

exports.joinMatchRoom = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const roomCode = normalizeRoomCode(request.data && request.data.roomCode);
  await db.runTransaction(async (tx) => {
    const ref = roomRef(roomCode);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "No room with that code.");
    const room = snap.data();
    if (room.hostUid === uid) {
      throw new HttpsError("failed-precondition", "Host cannot join their own room.");
    }
    if (room.guestUid && room.guestUid !== uid) {
      throw new HttpsError("failed-precondition", "Room already has a guest.");
    }
    if (room.status === "completed") {
      throw new HttpsError("failed-precondition", "Room is already completed.");
    }
    tx.set(ref, { guestUid: uid, status: "selectingXi" }, { merge: true });
  });
  return { roomId: roomCode };
});

exports.lockStrongestXi = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const roomId = normalizeRoomCode(request.data && request.data.roomId);
  const requestedIds = Array.isArray(request.data && request.data.playerIds)
    ? request.data.playerIds.map((id) => String(id || "").trim()).filter(Boolean)
    : [];
  const squad = requestedIds.length > 0
    ? await getSelectedXiByIds(uid, requestedIds)
    : await getStrongestXi(uid);
  if (squad.length < 11) {
    throw new HttpsError("failed-precondition", "You need 11 available players to start.");
  }
  await db.runTransaction(async (tx) => {
    const ref = roomRef(roomId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Room not found.");
    const room = snap.data();
    if (!isParticipant(room, uid)) {
      throw new HttpsError("permission-denied", "Only room players can lock an XI.");
    }
    if (room.status === "completed" || room.status === "inProgress") return;
    const isHost = room.hostUid === uid;
    const patch = isHost
      ? { hostPlayingXi: squad.map((p) => p.id), hostXiLocked: true }
      : { guestPlayingXi: squad.map((p) => p.id), guestXiLocked: true };
    const next = { ...room, ...patch };
    patch.status = next.hostXiLocked && next.guestXiLocked ? "inProgress" : "selectingXi";
    if (patch.status === "inProgress" && !room.hostBatFirst) {
      Object.assign(patch, startMatchPatch());
    }
    tx.set(ref, patch, { merge: true });
  });
  return { ok: true };
});

exports.advanceDelivery = onCall({
  region: REGION,
  secrets: [GOOGLE_AI_API_KEY],
}, async (request) => {
  const uid = requireUid(request);
  const roomId = normalizeRoomCode(request.data && request.data.roomId);
  const roomSnap = await roomRef(roomId).get();
  if (!roomSnap.exists) throw new HttpsError("not-found", "Room not found.");
  const room = roomSnap.data();
  if (!isParticipant(room, uid)) {
    throw new HttpsError("permission-denied", "Only room players can advance the match.");
  }
  const [hostPlayers, guestPlayers] = await Promise.all([
    getSelectedPlayers(room.hostUid, room.hostPlayingXi || []),
    getSelectedPlayers(room.guestUid, room.guestPlayingXi || []),
  ]);

  const delivery = await db.runTransaction(async (tx) => {
    const ref = roomRef(roomId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Room not found.");
    const current = snap.data();
    if (!isParticipant(current, uid)) {
      throw new HttpsError("permission-denied", "Only room players can advance the match.");
    }
    if (current.status === "completed") return;
    if (!current.hostXiLocked || !current.guestXiLocked) {
      throw new HttpsError("failed-precondition", "Both players must lock XIs first.");
    }
    let next = current.hostBatFirst ? current : { ...current, ...startMatchPatch() };
    if (isFinishedScoreState(next)) {
      tx.set(ref, completePatch(next), { merge: true });
      return null;
    }
    const applied = applyOneDelivery(next, hostPlayers, guestPlayers);
    next = applied.room;
    tx.set(ref, isFinishedScoreState(next) ? completePatch(next) : next, { merge: true });
    return {
      roomId,
      room: next,
      fallbackLine: applied.fallbackLine,
      context: applied.context,
      deliveryNumber: next.deliveryNumber,
    };
  });
  if (delivery && delivery.fallbackLine && delivery.context) {
    await tryPolishDeliveryCommentary(delivery).catch(() => {});
  }
  return { ok: true };
});

exports.generatePlayer = onCall({
  region: REGION,
  secrets: [GOOGLE_AI_API_KEY],
}, async (request) => {
  const uid = requireUid(request);
  const prompt = String((request.data && request.data.prompt) || "").trim();
  const tier = request.data && request.data.premium ? "premium" : "free";
  const generated = await generateSquadPlayerWithLlm(prompt).catch(() =>
    fallbackGeneratedPlayer(prompt),
  );
  const player = sanitizeGeneratedPlayer(generated, tier);
  const ref = userRef(uid).collection("players").doc(player.id);
  await ref.set(player, { merge: true });
  return { player };
});

exports.openStarterPack = onCall({
  region: REGION,
  secrets: [GOOGLE_AI_API_KEY],
}, async (request) => {
  const uid = requireUid(request);
  const forceReopen = request.data && request.data.force === true;
  const profileRef = userRef(uid);
  const precheck = await profileRef.get();
  const profile = precheck.exists ? precheck.data() : defaultProfile(uid);
  if (profile.starterPackOpened === true && !forceReopen) {
    const existing = await profileRef.collection("players").limit(15).get();
    return {
      alreadyOpened: true,
      generationSource: "alreadyOpened",
      players: existing.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    };
  }

  const premium = premiumCatalogCard();
  let generationSource = "gemma";
  let generated;
  try {
    const generatedPack = await generateStarterPackBasics();
    generationSource = generatedPack.generationSource;
    generated = generatedPack.players;
  } catch (error) {
    console.warn("Starter pack Gemma generation failed; using fallback.", {
      message: error && error.message ? error.message : String(error),
    });
    generationSource = "fallback";
    generated = fallbackStarterPackBasics();
  }
  const players = [
    premium,
    ...generated.slice(0, 14).map((raw) => sanitizeGeneratedPlayer(raw, "free")),
  ];
  while (players.length < 15) {
    players.push(sanitizeGeneratedPlayer(fallbackGeneratedPlayer("starter pack"), "free"));
  }

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(profileRef);
    const current = snap.exists ? snap.data() : defaultProfile(uid);
    if (current.starterPackOpened === true && !forceReopen) {
      throw new HttpsError("already-exists", "Starter pack already opened.");
    }
    if (forceReopen && !isLocalDevRequest(request)) {
      throw new HttpsError("permission-denied", "Starter pack reset is local-dev only.");
    }
    tx.set(profileRef, {
      ...current,
      uid,
      starterPackOpened: true,
      createdAt: current.createdAt || new Date().toISOString(),
    }, { merge: true });
    tx.set(leaderboardRef(uid), {
      uid,
      displayName: current.displayName || "Player",
      rankingPoints: num(current.rankingPoints),
      wins: num(current.wins),
    }, { merge: true });
    for (const player of players) {
      tx.set(profileRef.collection("players").doc(player.id), player, { merge: true });
    }
  });
  return { alreadyOpened: false, generationSource, players };
});

exports.forceCompleteMatch = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const roomId = normalizeRoomCode(request.data && request.data.roomId);
  await db.runTransaction(async (tx) => {
    const ref = roomRef(roomId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Room not found.");
    const room = snap.data();
    if (!isParticipant(room, uid)) {
      throw new HttpsError("permission-denied", "Only room players can end the match.");
    }
    if (room.status === "completed") return;
    tx.set(ref, completePatch(room), { merge: true });
  });
  return { ok: true };
});

exports.claimMatchResult = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const roomId = normalizeRoomCode(request.data && request.data.roomId);
  await db.runTransaction(async (tx) => {
    const ref = roomRef(roomId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Room not found.");
    const room = snap.data();
    if (!isParticipant(room, uid)) {
      throw new HttpsError("permission-denied", "Only room players can claim this result.");
    }
    if (room.status !== "completed") {
      throw new HttpsError("failed-precondition", "Match is not completed yet.");
    }
    const claimed = room.resultAppliedUids || [];
    if (claimed.includes(uid)) return;
    const profileRef = userRef(uid);
    const profileSnap = await tx.get(profileRef);
    const profile = profileSnap.exists ? profileSnap.data() : defaultProfile(uid);
    const opponentUid = room.hostUid === uid ? room.guestUid : room.hostUid;
    const opponentSnap = opponentUid ? await tx.get(userRef(opponentUid)) : null;
    const opponent = opponentSnap && opponentSnap.exists ? opponentSnap.data() : null;
    const stats = rewardStats(room, uid);
    const completedAt = room.completedAt || new Date().toISOString();

    tx.set(profileRef, {
      ...profile,
      uid,
      wins: num(profile.wins) + (stats.won ? 1 : 0),
      losses: num(profile.losses) + (!stats.won && !stats.tie ? 1 : 0),
      matchesPlayed: num(profile.matchesPlayed) + 1,
      coins: num(profile.coins) + stats.coins,
      rankingPoints: num(profile.rankingPoints) + stats.xp,
      totalRunsScored: num(profile.totalRunsScored) + stats.runsFor,
    }, { merge: true });
    tx.set(leaderboardRef(uid), {
      uid,
      displayName: profile.displayName || "Player",
      rankingPoints: num(profile.rankingPoints) + stats.xp,
      wins: num(profile.wins) + (stats.won ? 1 : 0),
    }, { merge: true });
    tx.set(profileRef.collection("matchHistory").doc(roomId), {
      matchId: roomId,
      completedAt,
      opponentDisplayName: opponent && opponent.displayName ? opponent.displayName : "Opponent",
      won: stats.won,
      runsFor: stats.runsFor,
      runsAgainst: stats.runsAgainst,
      coinsEarned: stats.coins,
      xpEarned: stats.xp,
    });
    tx.set(ref, { resultAppliedUids: [...claimed, uid] }, { merge: true });
  });
  return { ok: true };
});

function requireUid(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  return request.auth.uid;
}

function isLocalDevRequest(request) {
  const token = request.data && request.data.devResetToken;
  return process.env.WICKET_WARS_DEV_RESET_TOKEN &&
    token === process.env.WICKET_WARS_DEV_RESET_TOKEN;
}

function normalizeRoomCode(value) {
  const code = String(value || "").trim().toUpperCase();
  if (!/^[A-Z0-9]{4,12}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Invalid room code.");
  }
  return code;
}

function roomRef(id) {
  return db.collection("matchRooms").doc(id);
}

function userRef(uid) {
  return db.collection("users").doc(uid);
}

function leaderboardRef(uid) {
  return db.collection("leaderboard").doc(uid);
}

function generateRoomCode() {
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += ROOM_CODE_CHARS[Math.floor(Math.random() * ROOM_CODE_CHARS.length)];
  }
  return code;
}

function isParticipant(room, uid) {
  return room && (room.hostUid === uid || room.guestUid === uid);
}

function startMatchPatch() {
  const hostBatFirst = Math.random() < 0.5;
  return {
    status: "inProgress",
    hostBatFirst,
    inningsNumber: 1,
    chaseTarget: null,
    hostRuns: 0,
    guestRuns: 0,
    hostWickets: 0,
    guestWickets: 0,
    hostLegalBalls: 0,
    guestLegalBalls: 0,
    deliveryNumber: 0,
    commentaryTail: [
      `Toss - ${hostBatFirst ? "Host" : "Guest"} bats first. T20: 20 overs per innings.`,
    ],
  };
}

async function getStrongestXi(uid) {
  const snap = await userRef(uid).collection("players").get();
  return snap.docs
    .map((doc) => normalizePlayer({ id: doc.id, ...doc.data() }))
    .filter((p) => !p.training || p.training.isComplete === true)
    .sort((a, b) => overall(b.attributes) - overall(a.attributes))
    .slice(0, 11);
}

async function getSelectedXiByIds(uid, ids) {
  const uniqueIds = [...new Set(ids)];
  if (uniqueIds.length !== 11) {
    throw new HttpsError("invalid-argument", "Select exactly 11 unique players.");
  }
  const snap = await userRef(uid).collection("players").get();
  const byId = new Map(
    snap.docs.map((doc) => {
      const p = normalizePlayer({ id: doc.id, ...doc.data() });
      return [p.id, p];
    }),
  );
  const players = uniqueIds.map((id) => byId.get(id));
  if (players.some((p) => !p)) {
    throw new HttpsError("invalid-argument", "One or more selected players are not in your squad.");
  }
  if (players.some((p) => p.training && p.training.isComplete !== true)) {
    throw new HttpsError("failed-precondition", "Training players cannot be selected.");
  }
  return players;
}

async function getSelectedPlayers(uid, ids) {
  if (!uid) return [];
  const strongest = await getStrongestXi(uid);
  if (!ids || ids.length === 0) return strongest;
  const byId = new Map(strongest.map((p) => [p.id, p]));
  return ids.map((id) => byId.get(id)).filter(Boolean);
}

function normalizePlayer(player) {
  const attributes = {
    batting: rating(player.attributes && player.attributes.batting),
    bowling: rating(player.attributes && player.attributes.bowling),
    fielding: rating(player.attributes && player.attributes.fielding),
    stamina: rating(player.attributes && player.attributes.stamina),
    consistency: rating(player.attributes && player.attributes.consistency),
  };
  return {
    id: player.id || "",
    displayName: player.displayName || "Player",
    role: normalizeRole(player.role, attributes),
    country: safeShortText(player.country, "Unknown", 28),
    battingStyle: safeShortText(player.battingStyle, "", 40),
    bowlingStyle: safeShortText(player.bowlingStyle, "", 40),
    generatedBio: safeShortText(player.generatedBio, "", 180),
    avatarUrl: safeShortText(player.avatarUrl, "", 500),
    cardImageAsset: safeShortText(player.cardImageAsset, "", 200),
    attributes,
    training: player.training || null,
  };
}

function applyOneDelivery(room, hostPlayers, guestPlayers) {
  if (room.status === "completed" || room.hostBatFirst == null) {
    return { room, fallbackLine: null, context: null };
  }
  const battingHost = battingIsHost(room);
  const br = battingHost ? num(room.hostRuns) : num(room.guestRuns);
  const bw = battingHost ? num(room.hostWickets) : num(room.guestWickets);
  const bb = battingHost ? num(room.hostLegalBalls) : num(room.guestLegalBalls);
  if (bw >= MAX_WICKETS || bb >= MAX_BALLS) {
    return { room, fallbackLine: null, context: null };
  }
  if (room.inningsNumber === 2 && room.chaseTarget && br >= room.chaseTarget) {
    return { room, fallbackLine: null, context: null };
  }

  const battingLineup = battingHost ? hostPlayers : guestPlayers;
  const bowlingLineup = battingHost ? guestPlayers : hostPlayers;
  const batter = selectBatter(battingLineup, bw, bb);
  const bowler = selectBowler(bowlingLineup, bb);
  const result = simulateBall({
    pitch: room.pitch || "balanced",
    legalBallsInInnings: bb,
    wicketsDown: bw,
    runsScoredThisInnings: br,
    isChaseInnings: room.inningsNumber === 2,
    chaseTarget: room.chaseTarget,
    battingRating: batter ? batter.attributes.batting : averageRating(battingLineup, "batting"),
    bowlingRating: bowler ? bowler.attributes.bowling : averageRating(bowlingLineup, "bowling"),
    fieldingRating: averageRating(bowlingLineup, "fielding"),
    staminaRating: batter ? batter.attributes.stamina : averageRating(battingLineup, "stamina"),
    consistencyRating: batter ? batter.attributes.consistency : averageRating(battingLineup, "consistency"),
  });

  const next = { ...room };
  if (battingHost) {
    next.hostRuns = num(next.hostRuns) + result.runs;
    next.hostWickets = num(next.hostWickets) + result.wicket;
    next.hostLegalBalls = num(next.hostLegalBalls) + 1;
  } else {
    next.guestRuns = num(next.guestRuns) + result.runs;
    next.guestWickets = num(next.guestWickets) + result.wicket;
    next.guestLegalBalls = num(next.guestLegalBalls) + 1;
  }

  const over = formatOvers(battingHost ? next.hostLegalBalls : next.guestLegalBalls);
  const who = battingHost ? "Host" : "Guest";
  const batterName = batter ? batter.displayName : who;
  const bowlerName = bowler ? ` vs ${bowler.displayName}` : "";
  const line = `${over} · ${batterName}${bowlerName}: ${result.runs > 0 ? result.runs : "dot"}${result.wicket > 0 ? " · OUT!" : ""}`;
  next.commentaryTail = trimTail([...(room.commentaryTail || []), line]);

  const newBr = battingHost ? next.hostRuns : next.guestRuns;
  const newBw = battingHost ? next.hostWickets : next.guestWickets;
  const newBb = battingHost ? next.hostLegalBalls : next.guestLegalBalls;
  if (next.inningsNumber === 1 && (newBw >= MAX_WICKETS || newBb >= MAX_BALLS)) {
    next.chaseTarget = newBr + 1;
    next.inningsNumber = 2;
    next.commentaryTail = trimTail([
      ...next.commentaryTail,
      `-- End of 1st innings (${newBr}/${newBw}). Target: ${next.chaseTarget} --`,
    ]);
  }
  next.deliveryNumber = num(next.deliveryNumber) + 1;
  return {
    room: next,
    fallbackLine: line,
    context: {
      over,
      battingSide: who,
      batter: playerForPrompt(batter, who),
      bowler: playerForPrompt(bowler, "Bowler"),
      result,
      pitch: room.pitch || "balanced",
      inningsNumber: next.inningsNumber,
      chaseTarget: next.chaseTarget || null,
      hostScore: `${num(next.hostRuns)}/${num(next.hostWickets)}`,
      guestScore: `${num(next.guestRuns)}/${num(next.guestWickets)}`,
      hostBatFirst: !!next.hostBatFirst,
      ballsRemaining: MAX_BALLS - (battingHost ? num(next.hostLegalBalls) : num(next.guestLegalBalls)),
    },
  };
}

function simulateBall(ctx) {
  let pDot = 0.36;
  let p1 = 0.28;
  let p2 = 0.12;
  let p3 = 0.02;
  let p4 = 0.10;
  let p6 = 0.08;
  let pW = 0.04;
  const battingEdge = clamp((ctx.battingRating - ctx.bowlingRating) / 100, -0.5, 0.5);
  const fieldingEdge = clamp((ctx.fieldingRating - 60) / 100, -0.4, 0.4);
  const staminaEdge = clamp((ctx.staminaRating - 60) / 100, -0.4, 0.4);
  const consistencyEdge = clamp((ctx.consistencyRating - 60) / 100, -0.4, 0.4);
  pDot *= 1 - battingEdge * 0.35 - consistencyEdge * 0.12;
  p1 *= 1 + consistencyEdge * 0.10;
  p2 *= 1 + battingEdge * 0.12 + staminaEdge * 0.10;
  p4 *= 1 + battingEdge * 0.55;
  p6 *= 1 + battingEdge * 0.70;
  pW *= 1 - battingEdge * 0.45 + fieldingEdge * 0.22 - consistencyEdge * 0.12;
  if (ctx.pitch === "flat") {
    pDot *= 0.92; p4 *= 1.12; p6 *= 1.15; pW *= 0.88;
  } else if (ctx.pitch === "grassy") {
    pDot *= 1.08; pW *= 1.22; p4 *= 0.9; p6 *= 0.85;
  }
  if (ctx.legalBallsInInnings >= 90) {
    pDot *= 0.92; p4 *= 1.08; p6 *= 1.1; pW *= 1.06;
  }
  if (ctx.wicketsDown >= 7) {
    pDot *= 1.06; p6 *= 0.88; pW *= 0.94;
  }
  if (ctx.isChaseInnings && ctx.chaseTarget) {
    const need = ctx.chaseTarget - ctx.runsScoredThisInnings;
    const ballsLeft = clamp(MAX_BALLS - ctx.legalBallsInInnings, 1, MAX_BALLS);
    const rrr = need <= 0 ? 0 : (need / ballsLeft) * 6;
    if (rrr >= 11) {
      pDot *= 0.9; p4 *= 1.1; p6 *= 1.18; pW *= 1.08;
    } else if (rrr <= 5 && ctx.legalBallsInInnings > 60) {
      pDot *= 1.05; p6 *= 0.92; pW *= 0.96;
    }
  }
  const probs = [pDot, p1, p2, p3, p4, p6, pW];
  const sum = probs.reduce((a, b) => a + b, 0);
  const u = Math.random();
  let c = 0;
  for (let i = 0; i < probs.length; i++) {
    c += probs[i] / sum;
    if (u <= c) {
      if (i === 0) return { runs: 0, wicket: 0 };
      if (i === 1) return { runs: 1, wicket: 0 };
      if (i === 2) return { runs: 2, wicket: 0 };
      if (i === 3) return { runs: 3, wicket: 0 };
      if (i === 4) return { runs: 4, wicket: 0 };
      if (i === 5) return { runs: 6, wicket: 0 };
      return { runs: 0, wicket: 1 };
    }
  }
  return { runs: 0, wicket: 0 };
}

function isFinishedScoreState(room) {
  if (room.inningsNumber !== 2) return false;
  const battingHost = battingIsHost(room);
  const score = battingHost ? num(room.hostRuns) : num(room.guestRuns);
  if (room.chaseTarget && score >= room.chaseTarget) return true;
  const wickets = battingHost ? num(room.hostWickets) : num(room.guestWickets);
  const balls = battingHost ? num(room.hostLegalBalls) : num(room.guestLegalBalls);
  return wickets >= MAX_WICKETS || balls >= MAX_BALLS;
}

function completePatch(room) {
  const winnerUid = winnerFor(room);
  const tail = trimTail([
    ...(room.commentaryTail || []),
    winnerUid == null
      ? `Match tied - ${num(room.hostRuns)} runs each.`
      : `Match complete - ${num(room.hostRuns)}/${num(room.hostWickets)} vs ${num(room.guestRuns)}/${num(room.guestWickets)}.`,
  ]);
  return {
    ...room,
    status: "completed",
    winnerUid,
    completedAt: new Date().toISOString(),
    commentaryTail: tail,
  };
}

function winnerFor(room) {
  if (num(room.hostRuns) === num(room.guestRuns)) return null;
  return num(room.hostRuns) > num(room.guestRuns) ? room.hostUid : room.guestUid;
}

function rewardStats(room, uid) {
  const youHost = room.hostUid === uid;
  const runsFor = youHost ? num(room.hostRuns) : num(room.guestRuns);
  const runsAgainst = youHost ? num(room.guestRuns) : num(room.hostRuns);
  const tie = runsFor === runsAgainst;
  const won = !tie && runsFor > runsAgainst;
  return {
    runsFor,
    runsAgainst,
    tie,
    won,
    coins: tie ? 35 + Math.floor(runsFor / 3) : 40 + (won ? 90 : 15) + Math.floor(runsFor / 3),
    xp: tie ? 18 : (won ? 30 : 12),
  };
}

function battingIsHost(room) {
  return room.inningsNumber === 1 ? !!room.hostBatFirst : !room.hostBatFirst;
}

function selectBatter(lineup, wicketsDown, balls) {
  if (!lineup.length) return null;
  if (balls < 6 && lineup.length > 1) return lineup[balls % 2 === 0 ? 0 : 1];
  return lineup[Math.min(wicketsDown, lineup.length - 1)];
}

function selectBowler(lineup, balls) {
  if (!lineup.length) return null;
  const sorted = [...lineup].sort((a, b) => b.attributes.bowling - a.attributes.bowling);
  return sorted[Math.floor(balls / 6) % sorted.length];
}

function averageRating(players, key) {
  if (!players.length) return 60;
  return rating(players.reduce((sum, p) => sum + p.attributes[key], 0) / players.length);
}

async function tryPolishDeliveryCommentary(delivery) {
  const polished = await generateDeliveryCommentary(delivery.context);
  if (!polished || polished === delivery.fallbackLine) return;
  await db.runTransaction(async (tx) => {
    const ref = roomRef(delivery.roomId);
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const room = snap.data();
    if (num(room.deliveryNumber) !== num(delivery.deliveryNumber)) return;
    const tail = [...(room.commentaryTail || [])];
    const index = tail.lastIndexOf(delivery.fallbackLine);
    if (index < 0) return;
    tail[index] = polished;
    tx.set(ref, { commentaryTail: trimTail(tail) }, { merge: true });
  });
}

async function generateDeliveryCommentary(context) {
  const prompt = [
    "Write one live cricket commentary line for a mobile game.",
    "Keep it under 22 words. No markdown. No quotes.",
    "Make it energetic but not unrealistic.",
    `Over: ${context.over}`,
    `Pitch: ${context.pitch}`,
    `Innings: ${context.inningsNumber}`,
    `Score: Host ${context.hostScore}, Guest ${context.guestScore}`,
    context.chaseTarget ? `Target: ${context.chaseTarget}` : "First innings",
    `Batter: ${context.batter.name}, ${context.batter.role}, ${context.batter.battingStyle}`,
    `Bowler: ${context.bowler.name}, ${context.bowler.role}, ${context.bowler.bowlingStyle}`,
    `Ball result: ${context.result.wicket ? "wicket" : `${context.result.runs} run(s)`}`,
  ].join("\n");
  const text = await callGemmaText({
    system: "You are a concise cricket commentator for Wicket Wars.",
    prompt,
    maxTokens: 60,
    temperature: 0.85,
  });
  return cleanOneLine(text, 140);
}

async function generateSquadPlayerWithLlm(prompt) {
  const content = [
    "Generate one fictional cricket player for Wicket Wars.",
    "Return JSON only. No markdown.",
    "Schema:",
    "{\"displayName\":\"string\",\"role\":\"batter|bowler|allRounder|wicketKeeper\",\"country\":\"string\",\"battingStyle\":\"string\",\"bowlingStyle\":\"string\",\"attributes\":{\"batting\":0,\"bowling\":0,\"fielding\":0,\"stamina\":0,\"consistency\":0},\"generatedBio\":\"string\"}",
    "Rules: fictional names only, attributes 35-88, bio under 130 chars.",
    prompt ? `User theme: ${prompt}` : "User theme: balanced starter prospect",
  ].join("\n");
  const text = await callGemmaText({
    system: "You return strict JSON for a cricket game backend.",
    prompt: content,
    maxTokens: 260,
    temperature: 0.9,
    json: true,
  });
  return parseJsonObject(text);
}

async function generateStarterPackBasics() {
  let generationSource = "google-ai";
  const prompt = [
    "Generate 14 fictional basic cricket players for a Wicket Wars starter pack.",
    "Return JSON only with this shape: {\"players\":[...]}",
    "Each player schema:",
    "{\"displayName\":\"string\",\"role\":\"batter|bowler|allRounder|wicketKeeper\",\"country\":\"string\",\"battingStyle\":\"string\",\"bowlingStyle\":\"string\",\"attributes\":{\"batting\":0,\"bowling\":0,\"fielding\":0,\"stamina\":0,\"consistency\":0},\"generatedBio\":\"string\"}",
    "Rules: fictional names only, no real players, at least 4 batters, 4 bowlers, 2 allRounders, 1 wicketKeeper.",
    "Attributes should be 38-76. Bios under 110 chars.",
  ].join("\n");
  const text = await callGemmaText({
    system: "You return strict JSON for a cricket card game backend.",
    prompt,
    maxTokens: 1800,
    temperature: 0.9,
    json: true,
    timeoutMs: STARTER_PACK_LLM_TIMEOUT_MS,
    onModel: (model) => {
      generationSource = model;
    },
  });
  const parsed = parseJsonObject(text);
  const players = Array.isArray(parsed.players) ? parsed.players : [];
  if (players.length < 10) throw new Error("Starter pack JSON did not include enough players.");
  return { players, generationSource };
}

function premiumCatalogCard() {
  const template = PREMIUM_CATALOG[Math.floor(Math.random() * PREMIUM_CATALOG.length)];
  return {
    id: `premium_${template.id}_${Date.now()}`,
    catalogPlayerId: template.id,
    displayName: template.displayName,
    isRealPlayer: true,
    playerTier: "premium",
    role: template.role,
    country: template.country,
    battingStyle: template.battingStyle,
    bowlingStyle: template.bowlingStyle,
    generatedBio: template.generatedBio,
    avatarUrl: "",
    cardImageAsset: "",
    attributes: template.attributes,
    training: null,
  };
}

function fallbackStarterPackBasics() {
  return [
    { displayName: "Aarav Striker", role: "batter", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Part-time off spin", attributes: { batting: 72, bowling: 42, fielding: 61, stamina: 64, consistency: 66 }, generatedBio: "Aggressive starter batter with clean boundary timing." },
    { displayName: "Bilal Swing", role: "bowler", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Right-arm fast medium", attributes: { batting: 44, bowling: 73, fielding: 59, stamina: 68, consistency: 64 }, generatedBio: "New-ball mover built for early wickets." },
    { displayName: "Zain Finisher", role: "batter", country: "Generated", battingStyle: "Left-hand bat", bowlingStyle: "Does not bowl", attributes: { batting: 70, bowling: 38, fielding: 62, stamina: 67, consistency: 61 }, generatedBio: "Late-over hitter with sharp finishing instincts." },
    { displayName: "Hamza Cutter", role: "bowler", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Left-arm medium", attributes: { batting: 45, bowling: 70, fielding: 63, stamina: 66, consistency: 65 }, generatedBio: "Clever cutter bowler who varies pace well." },
    { displayName: "Rayyan Keeper", role: "wicketKeeper", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Wicket keeper", attributes: { batting: 66, bowling: 38, fielding: 74, stamina: 66, consistency: 64 }, generatedBio: "Reliable keeper-batter with quick hands." },
    { displayName: "Arjun Anchor", role: "batter", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Leg spin", attributes: { batting: 69, bowling: 48, fielding: 62, stamina: 70, consistency: 70 }, generatedBio: "Steady anchor who keeps innings together." },
    { displayName: "Kabir Spin", role: "bowler", country: "Generated", battingStyle: "Left-hand bat", bowlingStyle: "Right-arm leg spin", attributes: { batting: 42, bowling: 72, fielding: 60, stamina: 65, consistency: 66 }, generatedBio: "Attacking spinner with a useful wrong one." },
    { displayName: "Usman Pace", role: "bowler", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Right-arm fast", attributes: { batting: 40, bowling: 74, fielding: 58, stamina: 70, consistency: 62 }, generatedBio: "Raw pace option with hard lengths." },
    { displayName: "Ibrahim Cover", role: "allRounder", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Right-arm medium", attributes: { batting: 64, bowling: 62, fielding: 68, stamina: 66, consistency: 63 }, generatedBio: "Balanced all-rounder with safe fielding." },
    { displayName: "Rohan Sweep", role: "batter", country: "Generated", battingStyle: "Left-hand bat", bowlingStyle: "Slow left arm", attributes: { batting: 68, bowling: 45, fielding: 61, stamina: 63, consistency: 62 }, generatedBio: "Spin-hitter who loves the sweep shot." },
    { displayName: "Daniyal Yorker", role: "bowler", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Right-arm death pace", attributes: { batting: 41, bowling: 73, fielding: 60, stamina: 68, consistency: 64 }, generatedBio: "Death-over bowler with a toe-crushing yorker." },
    { displayName: "Nihal Glide", role: "allRounder", country: "Generated", battingStyle: "Left-hand bat", bowlingStyle: "Off spin", attributes: { batting: 62, bowling: 61, fielding: 66, stamina: 65, consistency: 65 }, generatedBio: "Utility all-rounder who fills lineup gaps." },
    { displayName: "Taimur Point", role: "batter", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Part-time medium", attributes: { batting: 65, bowling: 46, fielding: 70, stamina: 62, consistency: 60 }, generatedBio: "Compact batter and lively point fielder." },
    { displayName: "Sahil Drift", role: "bowler", country: "Generated", battingStyle: "Right-hand bat", bowlingStyle: "Left-arm orthodox", attributes: { batting: 43, bowling: 69, fielding: 63, stamina: 64, consistency: 68 }, generatedBio: "Accurate spinner with subtle drift." },
  ];
}

async function callGemmaText({
  system,
  prompt,
  maxTokens = 120,
  temperature = 0.7,
  json = false,
  timeoutMs = LLM_TIMEOUT_MS,
  onModel = null,
}) {
  const apiKey = getGoogleAiApiKey();
  if (!apiKey) throw new Error("GOOGLE_AI_API_KEY is not configured.");
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const body = {
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature,
        maxOutputTokens: maxTokens,
      },
    };
    if (system) {
      body.systemInstruction = { parts: [{ text: system }] };
    }
    if (json) {
      body.generationConfig.responseMimeType = "application/json";
    }
    let lastError = null;
    for (const model of GOOGLE_AI_MODELS) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
      if (!response.ok) {
        const detail = await response.text().catch(() => "");
        lastError = new Error(`Google AI ${response.status} for ${model}${detail ? `: ${detail.slice(0, 180)}` : ""}`);
        if (response.status === 404) continue;
        throw lastError;
      }
      const data = await response.json();
      const parts = data && data.candidates && data.candidates[0] &&
        data.candidates[0].content && data.candidates[0].content.parts;
      if (!Array.isArray(parts)) return "";
      if (typeof onModel === "function") onModel(model);
      return parts.map((part) => part.text || "").join("").trim();
    }
    throw lastError || new Error("No Gemma models configured.");
  } finally {
    clearTimeout(timer);
  }
}

function getGoogleAiApiKey() {
  try {
    return GOOGLE_AI_API_KEY.value() || process.env.GOOGLE_AI_API_KEY || "";
  } catch (_) {
    return process.env.GOOGLE_AI_API_KEY || "";
  }
}

function parseJsonObject(text) {
  const trimmed = String(text || "").trim();
  if (!trimmed) throw new Error("Empty model response.");
  try {
    return JSON.parse(trimmed);
  } catch (_) {
    const start = trimmed.indexOf("{");
    const end = trimmed.lastIndexOf("}");
    if (start >= 0 && end > start) {
      return JSON.parse(trimmed.slice(start, end + 1));
    }
    throw new Error("Model did not return JSON.");
  }
}

function sanitizeGeneratedPlayer(raw, tier) {
  const attrs = raw && raw.attributes ? raw.attributes : {};
  const attributes = {
    batting: clamp(rating(attrs.batting), 35, 88),
    bowling: clamp(rating(attrs.bowling), 35, 88),
    fielding: clamp(rating(attrs.fielding), 35, 88),
    stamina: clamp(rating(attrs.stamina), 35, 88),
    consistency: clamp(rating(attrs.consistency), 35, 88),
  };
  return {
    id: `gen_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    displayName: safeShortText(raw && raw.displayName, "Generated Player", 28),
    isRealPlayer: false,
    playerTier: tier === "premium" ? "premium" : "free",
    role: normalizeRole(raw && raw.role, attributes),
    country: safeShortText(raw && raw.country, "Generated", 28),
    battingStyle: safeShortText(raw && raw.battingStyle, "Right-hand bat", 40),
    bowlingStyle: safeShortText(raw && raw.bowlingStyle, "Right-arm medium", 40),
    generatedBio: safeShortText(raw && raw.generatedBio, "A generated Wicket Wars prospect.", 180),
    avatarUrl: safeShortText(raw && raw.avatarUrl, "", 500),
    cardImageAsset: safeShortText(raw && raw.cardImageAsset, "", 200),
    attributes,
    training: null,
  };
}

function fallbackGeneratedPlayer(prompt) {
  const names = ["Ayaan Volt", "Zayan Crest", "Rahil Storm", "Sameer Glide", "Nilan Edge"];
  const roles = ["batter", "bowler", "allRounder", "wicketKeeper"];
  const role = roles[Math.floor(Math.random() * roles.length)];
  const battingBias = role === "batter" || role === "wicketKeeper" ? 12 : 0;
  const bowlingBias = role === "bowler" ? 14 : role === "allRounder" ? 6 : 0;
  const name = names[Math.floor(Math.random() * names.length)];
  return {
    displayName: name,
    role,
    country: "Generated",
    battingStyle: role === "wicketKeeper" ? "Left-hand bat" : "Right-hand bat",
    bowlingStyle: role === "wicketKeeper" ? "Wicket keeper" : "Right-arm medium",
    generatedBio: prompt
      ? `Generated from your brief: ${safeShortText(prompt, "custom prospect", 70)}.`
      : "A generated Wicket Wars prospect.",
    attributes: {
      batting: 56 + battingBias + Math.floor(Math.random() * 12),
      bowling: 50 + bowlingBias + Math.floor(Math.random() * 12),
      fielding: 55 + Math.floor(Math.random() * 14),
      stamina: 55 + Math.floor(Math.random() * 14),
      consistency: 54 + Math.floor(Math.random() * 14),
    },
  };
}

function playerForPrompt(player, fallbackName) {
  if (!player) {
    return {
      name: fallbackName,
      role: "player",
      battingStyle: "",
      bowlingStyle: "",
      country: "",
    };
  }
  return {
    name: player.displayName,
    role: player.role || normalizeRole(null, player.attributes),
    battingStyle: player.battingStyle || "",
    bowlingStyle: player.bowlingStyle || "",
    country: player.country || "",
  };
}

function normalizeRole(value, attributes) {
  const raw = String(value || "").trim();
  if (PLAYER_ROLES.has(raw)) return raw;
  if (raw === "all-rounder" || raw === "ALL" || raw === "AR") return "allRounder";
  if (raw === "BAT") return "batter";
  if (raw === "BWL") return "bowler";
  if (raw === "WK" || raw === "wicket-keeper") return "wicketKeeper";
  const batting = attributes ? num(attributes.batting) : 60;
  const bowling = attributes ? num(attributes.bowling) : 60;
  if (batting - bowling >= 12) return "batter";
  if (bowling - batting >= 12) return "bowler";
  return "allRounder";
}

function cleanOneLine(value, maxLength) {
  return safeShortText(String(value || "").replace(/\s+/g, " "), "", maxLength)
    .replace(/^["'`]+|["'`]+$/g, "")
    .trim();
}

function safeShortText(value, fallback, maxLength) {
  const text = String(value || "").replace(/\s+/g, " ").trim();
  if (!text) return fallback;
  return text.length > maxLength ? text.slice(0, maxLength).trim() : text;
}

function overall(attrs) {
  return Math.round((attrs.batting * 3 + attrs.bowling * 3 + attrs.fielding + attrs.stamina + attrs.consistency) / 9);
}

function defaultProfile(uid) {
  return {
    uid,
    displayName: "Player",
    coins: 0,
    rankingPoints: 0,
    leagueTier: "ROOKIE LEAGUE",
    wins: 0,
    losses: 0,
    matchesPlayed: 0,
    dailyStreak: 0,
    totalRunsScored: 0,
  };
}

function trimTail(lines) {
  return lines.slice(Math.max(0, lines.length - TAIL_LIMIT));
}

function formatOvers(balls) {
  return `${Math.floor(balls / 6)}.${balls % 6}`;
}

function rating(value) {
  return clamp(Math.round(num(value) || 0), 0, 100);
}

function num(value) {
  return Number.isFinite(Number(value)) ? Number(value) : 0;
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}
