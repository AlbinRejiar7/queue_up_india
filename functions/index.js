const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const region = "asia-south1";
const AVAILABILITY_TTL_MINUTES = 5;
const PARTY_TTL_HOURS = 24;
const NOTIFICATION_CHANNEL_ID = "queueup_alerts_default_v1";
const SOLO_MATCH_REQUIRED_PLAYERS = 4;
const SOLO_MATCH_READY_SECONDS = 20;

function slugify(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function normalizeRankToSkillLevel(gameId, rankId) {
  const normalizedGame = String(gameId || "").trim().toLowerCase();
  const normalizedRank = String(rankId || "").trim().toLowerCase();

  if (normalizedGame === "pubg") {
    if (normalizedRank.startsWith("bronze")) return 2;
    if (normalizedRank.startsWith("silver")) return 3;
    if (normalizedRank.startsWith("gold")) return 4;
    if (normalizedRank.startsWith("platinum")) return 5;
    if (normalizedRank.startsWith("diamond")) return 6;
    if (normalizedRank.startsWith("crown")) return 7;
    if (normalizedRank.startsWith("ace")) return 8;
    if (normalizedRank.startsWith("conqueror")) return 10;
    return 4;
  }

  if (normalizedGame === "freefire") {
    if (normalizedRank.startsWith("bronze")) return 2;
    if (normalizedRank.startsWith("silver")) return 3;
    if (normalizedRank.startsWith("gold")) return 4;
    if (normalizedRank.startsWith("platinum")) return 5;
    if (normalizedRank.startsWith("diamond")) return 6;
    if (normalizedRank.startsWith("heroic")) return 8;
    if (normalizedRank.startsWith("grandmaster")) return 10;
    return 4;
  }

  if (normalizedRank.startsWith("iron")) return 1;
  if (normalizedRank.startsWith("bronze")) return 2;
  if (normalizedRank.startsWith("silver")) return 3;
  if (normalizedRank.startsWith("gold")) return 5;
  if (normalizedRank.startsWith("platinum")) return 6;
  if (normalizedRank.startsWith("diamond")) return 7;
  if (normalizedRank.startsWith("ascendant")) return 8;
  if (normalizedRank.startsWith("immortal")) return 9;
  if (normalizedRank.startsWith("radiant")) return 10;
  return 4;
}

function skillGroupForLevel(skillLevel) {
  if (skillLevel <= 3) {
    return "beginner";
  }
  if (skillLevel <= 6) {
    return "intermediate";
  }
  return "pro";
}

function buildBucketId({ gameId, languageId, skillLevel }) {
  return `${slugify(gameId)}_${slugify(languageId)}_${skillGroupForLevel(skillLevel)}`;
}

function estimateQueueSeconds(queueSize) {
  if (queueSize >= SOLO_MATCH_REQUIRED_PLAYERS) {
    return 5;
  }
  if (queueSize === 3) {
    return 12;
  }
  if (queueSize === 2) {
    return 20;
  }
  return 35;
}

function userMatchmakingRef(uid) {
  return db.collection("users").doc(uid).collection("private").doc("solo_matchmaking");
}

function queueMetadataRef(bucketId) {
  return db.collection("match_pool").doc(bucketId).collection("metadata").doc("stats");
}

async function resolveUserProfile(uid) {
  const [userDoc, authUser] = await Promise.all([
    db.collection("users").doc(uid).get(),
    getAuth().getUser(uid),
  ]);
  const data = userDoc.exists ? userDoc.data() : {};
  return {
    displayName:
      data.displayName ||
      authUser.displayName ||
      "QueuePlayer",
    avatarUrl:
      data.avatarUrl ||
      authUser.photoURL ||
      null,
  };
}

async function attemptSoloMatchmakingForBucket(bucketId) {
  while (true) {
    const matched = await db.runTransaction(async (tx) => {
      const bucketRef = db.collection("match_pool").doc(bucketId);
      const ticketQuery = bucketRef.collection("tickets").orderBy("joinedAt").limit(SOLO_MATCH_REQUIRED_PLAYERS);
      const ticketsSnap = await tx.get(ticketQuery);
      if (ticketsSnap.size < SOLO_MATCH_REQUIRED_PLAYERS) {
        return false;
      }

      const participants = ticketsSnap.docs.map((doc) => {
        const data = doc.data();
        return {
          uid: doc.id,
          displayName: data.displayName || "QueuePlayer",
          avatarUrl: data.avatarUrl || null,
          gameId: data.gameId || "",
          rankId: data.rankId || "",
          languageId: data.languageId || "",
          skillLevel: data.skillLevel || 1,
        };
      });
      const first = participants[0];
      const squadRef = db.collection("solo_squads").doc();
      const playerIds = participants.map((player) => player.uid);

      tx.set(squadRef, {
        bucketId,
        gameId: first.gameId,
        languageId: first.languageId,
        requiredPlayers: SOLO_MATCH_REQUIRED_PLAYERS,
        retryCount: 0,
        participants,
        playerIds,
        acceptedPlayerIds: [],
        status: "waiting",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        acceptDeadlineAt: Timestamp.fromMillis(Date.now() + SOLO_MATCH_READY_SECONDS * 1000),
      });

      ticketsSnap.docs.forEach((doc) => tx.delete(doc.ref));
      tx.set(
        queueMetadataRef(bucketId),
        {
          activeUsers: FieldValue.increment(-SOLO_MATCH_REQUIRED_PLAYERS),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      participants.forEach((participant) => {
        tx.set(
          userMatchmakingRef(participant.uid),
          {
            status: "waiting",
            bucketId,
            ticketId: participant.uid,
            squadId: squadRef.id,
            gameId: participant.gameId,
            rankId: participant.rankId,
            languageId: participant.languageId,
            skillLevel: participant.skillLevel,
            queueSize: SOLO_MATCH_REQUIRED_PLAYERS,
            estimatedSeconds: 0,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });

      return true;
    });

    if (!matched) {
      break;
    }
  }
}

function normalizeData(data) {
  const payload = {};
  if (!data) {
    return payload;
  }
  Object.entries(data).forEach(([key, value]) => {
    if (value === undefined || value === null) {
      return;
    }
    payload[key] = String(value);
  });
  return payload;
}

function buildPushPayload({ title, body, data }) {
  return {
    notification: {
      title,
      body
    },
    data: normalizeData(data),
    android: {
      priority: "high",
      notification: {
        channelId: NOTIFICATION_CHANNEL_ID,
        sound: "default"
      }
    },
    apns: {
      payload: {
        aps: {
          sound: "default"
        }
      }
    }
  };
}

function normalizePushPayload(payload) {
  if (!payload) {
    return payload;
  }
  const androidNotification = {
    ...(payload.android?.notification || {}),
    channelId: NOTIFICATION_CHANNEL_ID,
    sound: "default"
  };
  const android = {
    ...(payload.android || {}),
    priority: payload.android?.priority || "high",
    notification: androidNotification
  };

  const apnsPayload = {
    ...(payload.apns?.payload || {}),
    aps: {
      ...(payload.apns?.payload?.aps || {}),
      sound: "default"
    }
  };
  const apns = {
    ...(payload.apns || {}),
    payload: apnsPayload
  };

  return {
    ...payload,
    android,
    apns
  };
}

async function fetchUserTokens(uid) {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();
  return snapshot.docs.map((doc) => doc.id);
}

async function pruneInvalidTokens(uid, tokens, response) {
  if (!response || !response.responses) {
    return;
  }
  const batch = db.batch();
  response.responses.forEach((result, index) => {
    if (result.success) {
      return;
    }
    const code = result.error && result.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      batch.delete(
        db
          .collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .doc(tokens[index])
      );
    }
  });
  await batch.commit();
}

async function sendPushToUser(uid, payload) {
  const tokens = await fetchUserTokens(uid);
  if (!tokens.length) {
    console.log("[push] skip: no tokens for", uid);
    return;
  }
  const normalizedPayload = normalizePushPayload(payload);
  console.log("[push] sending", {
    uid,
    tokens: tokens.length,
    title: normalizedPayload?.notification?.title || "",
    body: normalizedPayload?.notification?.body || ""
  });
  const response = await messaging.sendEachForMulticast({
    tokens,
    ...normalizedPayload
  });
  console.log("[push] result", {
    uid,
    successCount: response.successCount,
    failureCount: response.failureCount
  });
  await pruneInvalidTokens(uid, tokens, response);
}

function clearSoloMatchmakingSession(tx, participant) {
  tx.set(
    userMatchmakingRef(participant.uid),
    {
      status: "idle",
      squadId: null,
      bucketId: null,
      ticketId: null,
      queueSize: 0,
      estimatedSeconds: 0,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

function queueSoloParticipant(tx, participant, bucketId, queueSize) {
  tx.set(
    db.collection("match_pool").doc(bucketId).collection("tickets").doc(participant.uid),
    {
      uid: participant.uid,
      displayName: participant.displayName || "QueuePlayer",
      avatarUrl: participant.avatarUrl || null,
      gameId: participant.gameId || "",
      rankId: participant.rankId || "",
      languageId: participant.languageId || "",
      skillLevel: participant.skillLevel || 1,
      joinedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }
  );
  tx.set(
    userMatchmakingRef(participant.uid),
    {
      status: "searching",
      bucketId,
      ticketId: participant.uid,
      squadId: null,
      gameId: participant.gameId || "",
      rankId: participant.rankId || "",
      languageId: participant.languageId || "",
      skillLevel: participant.skillLevel || 1,
      queueSize,
      estimatedSeconds: estimateQueueSeconds(queueSize),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function clearPartyUserReferences(partyId) {
  const [roomsSnapshot, currentPartyUsersSnapshot] = await Promise.all([
    db.collectionGroup("rooms").where("partyId", "==", partyId).get(),
    db.collection("users").where("currentPartyId", "==", partyId).get(),
  ]);

  const bulkWriter = db.bulkWriter();

  roomsSnapshot.docs.forEach((doc) => {
    bulkWriter.delete(doc.ref);
  });

  currentPartyUsersSnapshot.docs.forEach((doc) => {
    bulkWriter.set(
      doc.ref,
      {
        currentPartyId: null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  await bulkWriter.close();
}

async function deleteExpiredParty(partyRef) {
  const freshSnap = await partyRef.get();
  if (!freshSnap.exists) {
    return;
  }

  await clearPartyUserReferences(partyRef.id);
  await db.recursiveDelete(partyRef);
}

exports.joinParty = onCall({ region, invoker: "public" }, async (request) => {
  console.log("[joinParty] auth:", request.auth ? "present" : "missing");
  console.log(
    "[joinParty] auth header:",
    request.rawRequest?.headers?.authorization ? "present" : "missing"
  );
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { partyId, displayName, avatarUrl } = request.data || {};
  if (!partyId) {
    throw new HttpsError("invalid-argument", "Party ID is required.");
  }

  let partyData = null;
  await db.runTransaction(async (tx) => {
    const partyRef = db.collection("parties").doc(partyId);
    const partySnap = await tx.get(partyRef);
    if (!partySnap.exists) {
      throw new HttpsError("not-found", "Party not found.");
    }

    const party = partySnap.data();
    partyData = party;
    if (party.status === "closed") {
      throw new HttpsError("failed-precondition", "Party is closed.");
    }

    const memberRef = partyRef.collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    if (memberSnap.exists && memberSnap.data().status === "active") {
      return;
    }

    const currentPlayers = party.currentPlayers || 0;
    const maxPlayers = party.maxPlayers || party.neededPlayers || 0;
    if (maxPlayers > 0 && currentPlayers >= maxPlayers) {
      throw new HttpsError("failed-precondition", "Party is full.");
    }

    tx.set(
      memberRef,
      {
        uid,
        displayName: displayName || "QueuePlayer",
        avatarUrl: avatarUrl || null,
        role: "member",
        status: "active",
        joinedAt: FieldValue.serverTimestamp()
      },
      { merge: true }
    );

    const nextCount = currentPlayers + 1;
    tx.update(partyRef, {
      currentPlayers: nextCount,
      status: maxPlayers > 0 && nextCount >= maxPlayers ? "full" : "open"
    });

    const roomRef = db.collection("users").doc(uid).collection("rooms").doc(partyId);
    tx.set(
      roomRef,
      {
        partyId,
        role: "member",
        gameId: party.gameId || null,
        rankId: party.rankId || null,
        languageId: party.languageId || null,
        status: "active",
        lastMessageAt: party.lastMessageAt || null
      },
      { merge: true }
    );
  });

  if (partyData && partyData.hostId && partyData.hostId !== uid) {
    const senderName = displayName || "QueuePlayer";
    console.log("[push] party join -> host", {
      partyId,
      hostId: partyData.hostId,
      senderId: uid
    });
    await sendPushToUser(
      partyData.hostId,
      buildPushPayload({
        title: "Party update",
        body: `${senderName} joined your party.`,
        data: {
          type: "party_joined",
          partyId,
          senderId: uid
        }
      })
    );
  }

  return { ok: true };
});

exports.createParty = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const {
    name,
    gameId,
    rankId,
    languageId,
    maxPlayers,
    partyCode
  } = request.data || {};

  if (!name || !gameId || !rankId || !languageId) {
    throw new HttpsError("invalid-argument", "Missing party fields.");
  }

  if (!partyCode || String(partyCode).trim().length === 0) {
    throw new HttpsError("invalid-argument", "Party code is required.");
  }

  const partyRef = db.collection("parties").doc();
  await db.runTransaction(async (tx) => {
    tx.set(partyRef, {
      name,
      hostId: uid,
      gameId,
      rankId,
      languageId,
      maxPlayers: Number(maxPlayers) || 4,
      neededPlayers: Number(maxPlayers) || 4,
      currentPlayers: 1,
      partyCode: String(partyCode),
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    tx.set(partyRef.collection("members").doc(uid), {
      uid,
      displayName: request.auth?.token?.name || "QueuePlayer",
      avatarUrl: null,
      role: "host",
      status: "active",
      joinedAt: FieldValue.serverTimestamp()
    });

    tx.set(db.collection("users").doc(uid).collection("rooms").doc(partyRef.id), {
      partyId: partyRef.id,
      role: "host",
      gameId,
      rankId,
      languageId,
      status: "active",
      lastMessageAt: null
    }, { merge: true });

    tx.set(db.collection("users").doc(uid), {
      currentPartyId: partyRef.id,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
  });

  return { partyId: partyRef.id };
});

exports.startSoloMatchmaking = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { gameId, rankId, languageId } = request.data || {};
  if (!gameId || !rankId || !languageId) {
    throw new HttpsError("invalid-argument", "Game, rank, and language are required.");
  }

  const skillLevel = normalizeRankToSkillLevel(gameId, rankId);
  const bucketId = buildBucketId({ gameId, languageId, skillLevel });
  const profile = await resolveUserProfile(uid);

  await db.runTransaction(async (tx) => {
    const sessionRef = userMatchmakingRef(uid);
    const sessionSnap = await tx.get(sessionRef);
    if (sessionSnap.exists) {
      const sessionData = sessionSnap.data() || {};
      const currentStatus = sessionData.status || "idle";
      if (["searching", "waiting", "accepted_waiting", "confirmed"].includes(currentStatus)) {
        throw new HttpsError("failed-precondition", "You already have an active squad.");
      }
    }

    const userRef = db.collection("users").doc(uid);
    const userSnap = await tx.get(userRef);
    const userData = userSnap.exists ? userSnap.data() : {};
    if (userData?.currentPartyId) {
      throw new HttpsError("failed-precondition", "You are already in a party.");
    }

    const metadataRef = queueMetadataRef(bucketId);
    const metadataSnap = await tx.get(metadataRef);
    const activeUsers = metadataSnap.exists ? metadataSnap.data().activeUsers || 0 : 0;
    const nextQueueSize = Number(activeUsers || 0) + 1;

    tx.set(
      db.collection("match_pool").doc(bucketId).collection("tickets").doc(uid),
      {
        uid,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        gameId,
        rankId,
        languageId,
        skillLevel,
        joinedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }
    );

    tx.set(
      sessionRef,
      {
        status: "searching",
        bucketId,
        ticketId: uid,
        squadId: null,
        gameId,
        rankId,
        languageId,
        skillLevel,
        queueSize: nextQueueSize,
        estimatedSeconds: estimateQueueSeconds(nextQueueSize),
        joinedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    tx.set(
      metadataRef,
      {
        activeUsers: FieldValue.increment(1),
        recentJoins: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  await attemptSoloMatchmakingForBucket(bucketId);
  return { ok: true, bucketId };
});

exports.cancelSoloMatchmaking = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  let bucketToRetry = null;
  await db.runTransaction(async (tx) => {
    const sessionRef = userMatchmakingRef(uid);
    const sessionSnap = await tx.get(sessionRef);
    if (!sessionSnap.exists) {
      return;
    }
    const session = sessionSnap.data() || {};
    const status = session.status || "idle";
    const bucketId = session.bucketId || null;

    if (status === "searching" && bucketId) {
      tx.delete(db.collection("match_pool").doc(bucketId).collection("tickets").doc(uid));
      tx.set(
        queueMetadataRef(bucketId),
        {
          activeUsers: FieldValue.increment(-1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(
        sessionRef,
        {
          status: "idle",
          bucketId: null,
          ticketId: null,
          squadId: null,
          queueSize: 0,
          estimatedSeconds: 0,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return;
    }

    if (!bucketId || !session.squadId) {
      tx.set(
        sessionRef,
        {
          status: "idle",
          bucketId: null,
          ticketId: null,
          squadId: null,
          queueSize: 0,
          estimatedSeconds: 0,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return;
    }

    const squadRef = db.collection("solo_squads").doc(session.squadId);
    const squadSnap = await tx.get(squadRef);
    if (!squadSnap.exists) {
      tx.set(
        sessionRef,
        {
          status: "idle",
          bucketId: null,
          ticketId: null,
          squadId: null,
          queueSize: 0,
          estimatedSeconds: 0,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return;
    }

    const squad = squadSnap.data() || {};
    const participants = squad.participants || [];
    const queueSize = 1;
    participants.forEach((participant) => {
      if (!participant?.uid) {
        return;
      }
      if (participant.uid === uid) {
        clearSoloMatchmakingSession(tx, participant);
        return;
      }
      queueSoloParticipant(tx, participant, bucketId, queueSize);
      tx.set(
        queueMetadataRef(bucketId),
        {
          activeUsers: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });
    tx.update(squadRef, {
      status: "cancelled",
      rejectedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    bucketToRetry = bucketId;
  });

  if (bucketToRetry) {
    await attemptSoloMatchmakingForBucket(bucketToRetry);
  }
  return { ok: true };
});

exports.acceptSoloMatchmaking = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { squadId } = request.data || {};
  if (!squadId) {
    throw new HttpsError("invalid-argument", "Squad ID is required.");
  }

  await db.runTransaction(async (tx) => {
    const squadRef = db.collection("solo_squads").doc(squadId);
    const squadSnap = await tx.get(squadRef);
    if (!squadSnap.exists) {
      throw new HttpsError("not-found", "Squad not found.");
    }
    const squad = squadSnap.data() || {};
    if (!Array.isArray(squad.playerIds) || !squad.playerIds.includes(uid)) {
      throw new HttpsError("permission-denied", "You are not part of this squad.");
    }
    if (squad.status === "confirmed") {
      return;
    }
    if (squad.status !== "waiting") {
      throw new HttpsError("failed-precondition", "This squad is no longer waiting.");
    }
    const deadline = squad.acceptDeadlineAt?.toMillis ? squad.acceptDeadlineAt.toMillis() : null;
    if (deadline && deadline < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Match accept window expired.");
    }

    const acceptedIds = new Set(squad.acceptedPlayerIds || []);
    acceptedIds.add(uid);
    const acceptedPlayerIds = Array.from(acceptedIds);
    const participants = squad.participants || [];

    tx.update(squadRef, {
      acceptedPlayerIds,
      status: acceptedPlayerIds.length >= SOLO_MATCH_REQUIRED_PLAYERS ? "confirmed" : "waiting",
      updatedAt: FieldValue.serverTimestamp(),
      ...(acceptedPlayerIds.length >= SOLO_MATCH_REQUIRED_PLAYERS
        ? { confirmedAt: FieldValue.serverTimestamp() }
        : {}),
    });

    participants.forEach((participant) => {
      if (!participant?.uid) {
        return;
      }
      tx.set(
        userMatchmakingRef(participant.uid),
        {
          status: acceptedPlayerIds.length >= SOLO_MATCH_REQUIRED_PLAYERS
            ? "confirmed"
            : participant.uid === uid
              ? "accepted_waiting"
              : "waiting",
          squadId,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });
  });

  return { ok: true };
});

exports.rejectSoloMatchmaking = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { squadId } = request.data || {};
  if (!squadId) {
    throw new HttpsError("invalid-argument", "Squad ID is required.");
  }

  let bucketToRetry = null;
  await db.runTransaction(async (tx) => {
    const squadRef = db.collection("solo_squads").doc(squadId);
    const squadSnap = await tx.get(squadRef);
    if (!squadSnap.exists) {
      throw new HttpsError("not-found", "Squad not found.");
    }

    const squad = squadSnap.data() || {};
    if (!Array.isArray(squad.playerIds) || !squad.playerIds.includes(uid)) {
      throw new HttpsError("permission-denied", "You are not part of this squad.");
    }
    const bucketId = squad.bucketId || null;
    const participants = squad.participants || [];
    let requeueCount = 0;

    participants.forEach((participant) => {
      if (!participant?.uid) {
        return;
      }
      if (participant.uid === uid || !bucketId) {
        clearSoloMatchmakingSession(tx, participant);
        return;
      }
      requeueCount += 1;
      queueSoloParticipant(tx, participant, bucketId, requeueCount);
      tx.set(
        queueMetadataRef(bucketId),
        {
          activeUsers: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    tx.update(squadRef, {
      status: "cancelled",
      rejectedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    bucketToRetry = bucketId;
  });

  if (bucketToRetry) {
    await attemptSoloMatchmakingForBucket(bucketToRetry);
  }
  return { ok: true };
});

exports.leaveParty = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { partyId } = request.data || {};
  if (!partyId) {
    throw new HttpsError("invalid-argument", "Party ID is required.");
  }

  await db.runTransaction(async (tx) => {
    const partyRef = db.collection("parties").doc(partyId);
    const partySnap = await tx.get(partyRef);
    if (!partySnap.exists) {
      throw new HttpsError("not-found", "Party not found.");
    }

    const memberRef = partyRef.collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    if (!memberSnap.exists || memberSnap.data().status !== "active") {
      return;
    }

    const party = partySnap.data();
    const membersSnap = await tx.get(
      partyRef.collection("members").where("status", "==", "active")
    );
    const activeMembers = membersSnap.docs.map((doc) => ({
      id: doc.id,
      data: doc.data()
    }));
    const remainingMembers = activeMembers.filter((m) => m.id !== uid);
    const maxPlayers = party.maxPlayers || party.neededPlayers || 0;
    const nextCount = remainingMembers.length;

    const userRef = db.collection("users").doc(uid);
    const roomRef = userRef.collection("rooms").doc(partyId);

    if (nextCount === 0) {
      tx.delete(memberRef);
      tx.delete(partyRef);
      tx.set(roomRef, { status: "left" }, { merge: true });
      tx.set(
        userRef,
        { currentPartyId: null, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
      return;
    }

    const isHost = party.hostId === uid || memberSnap.data().role === "host";
    if (isHost) {
      const randomIndex = Math.floor(Math.random() * remainingMembers.length);
      const newHost = remainingMembers[randomIndex];
      const newHostId = newHost.id;
      const newHostRoomRef = db
        .collection("users")
        .doc(newHostId)
        .collection("rooms")
        .doc(partyId);

      tx.update(partyRef, {
        hostId: newHostId,
        hostDisplayName: newHost.data.displayName || "QueuePlayer",
        currentPlayers: nextCount,
        status: maxPlayers > 0 && nextCount >= maxPlayers ? "full" : "open",
        updatedAt: FieldValue.serverTimestamp()
      });
      tx.update(partyRef.collection("members").doc(newHostId), {
        role: "host"
      });
      tx.set(newHostRoomRef, { role: "host", status: "active" }, { merge: true });

      tx.update(memberRef, {
        status: "left",
        leftAt: FieldValue.serverTimestamp()
      });
      tx.set(roomRef, { status: "left" }, { merge: true });
      tx.set(
        userRef,
        { currentPartyId: null, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
      return;
    }

    tx.update(memberRef, {
      status: "left",
      leftAt: FieldValue.serverTimestamp()
    });
    tx.update(partyRef, {
      currentPlayers: nextCount,
      status: maxPlayers > 0 && nextCount >= maxPlayers ? "full" : "open",
      updatedAt: FieldValue.serverTimestamp()
    });
    tx.set(roomRef, { status: "left" }, { merge: true });
    tx.set(
      userRef,
      { currentPartyId: null, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });

  return { ok: true };
});

exports.setAvailability = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { isAvailable, gameId, rankId, languageId, displayName } = request.data || {};
  const docRef = db.collection("availability").doc(uid);

  if (!isAvailable) {
    await docRef.delete();
    return { ok: true };
  }

  if (!gameId || !rankId || !languageId) {
    throw new HttpsError("invalid-argument", "Missing availability fields.");
  }

  await docRef.set({
    uid,
    displayName: displayName || request.auth?.token?.name || "QueuePlayer",
    gameId,
    rankId,
    languageId,
    isAvailable: true,
    updatedAt: FieldValue.serverTimestamp()
  });

  return { ok: true };
});

exports.checkPhoneRegistered = onCall({ region, invoker: "public" }, async (request) => {
  const { phoneNumber } = request.data || {};
  const raw = String(phoneNumber || "").trim();
  if (!raw) {
    throw new HttpsError("invalid-argument", "Phone number is required.");
  }

  if (!raw.startsWith("+")) {
    throw new HttpsError("invalid-argument", "Phone number must be in E.164 format.");
  }

  try {
    await getAuth().getUserByPhoneNumber(raw);
    return { registered: true };
  } catch (error) {
    if (error?.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "Phone not registered");
    }
    throw new HttpsError("internal", "Unable to check phone right now.");
  }
});

exports.kickMember = onCall({ region, invoker: "public" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { partyId, memberId } = request.data || {};
  if (!partyId || !memberId) {
    throw new HttpsError("invalid-argument", "Party ID and member ID required.");
  }

  let partyData = null;
  await db.runTransaction(async (tx) => {
    const partyRef = db.collection("parties").doc(partyId);
    const partySnap = await tx.get(partyRef);
    if (!partySnap.exists) {
      throw new HttpsError("not-found", "Party not found.");
    }

    const party = partySnap.data();
    partyData = party;
    if (party.hostId !== uid) {
      throw new HttpsError("permission-denied", "Only the host can kick players.");
    }

    const memberRef = partyRef.collection("members").doc(memberId);
    const memberSnap = await tx.get(memberRef);
    if (!memberSnap.exists || memberSnap.data().status !== "active") {
      return;
    }

    const currentPlayers = party.currentPlayers || 0;
    const maxPlayers = party.maxPlayers || party.neededPlayers || 0;
    const nextCount = Math.max(currentPlayers - 1, 0);

    tx.update(memberRef, {
      status: "kicked",
      kickedAt: FieldValue.serverTimestamp()
    });

    tx.update(partyRef, {
      currentPlayers: nextCount,
      status: maxPlayers > 0 && nextCount >= maxPlayers ? "full" : "open"
    });

    const roomRef = db.collection("users").doc(memberId).collection("rooms").doc(partyId);
    tx.set(roomRef, { status: "kicked" }, { merge: true });
  });

  if (memberId) {
    const partyName = (partyData && partyData.name) || "party";
    console.log("[push] kicked member", {
      partyId,
      memberId
    });
    await sendPushToUser(
      memberId,
      buildPushPayload({
        title: "Party update",
        body: `You were removed from ${partyName}.`,
        data: {
          type: "party_kicked",
          partyId,
          senderId: uid
        }
      })
    );
  }

  return { ok: true };
});

exports.cleanupAvailability = onSchedule(
  { schedule: "every 5 minutes", region },
  async () => {
    const cutoff = Timestamp.fromMillis(
      Date.now() - AVAILABILITY_TTL_MINUTES * 60 * 1000
    );

    let lastDoc = null;
    while (true) {
      let query = db
        .collection("availability")
        .where("isAvailable", "==", true)
        .where("updatedAt", "<", cutoff)
        .orderBy("updatedAt")
        .limit(500);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }
  }
);

exports.cleanupSoloMatchmaking = onSchedule(
  { schedule: "every 1 minutes", region },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now());
    let lastDoc = null;

    while (true) {
      let query = db
        .collection("solo_squads")
        .orderBy("acceptDeadlineAt")
        .endAt(cutoff)
        .limit(50);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      for (const doc of snapshot.docs) {
        let bucketToRetry = null;
        await db.runTransaction(async (tx) => {
          const freshSnap = await tx.get(doc.ref);
          if (!freshSnap.exists) {
            return;
          }
          const squad = freshSnap.data() || {};
          if (squad.status !== "waiting") {
            return;
          }
          const deadline = squad.acceptDeadlineAt?.toMillis
            ? squad.acceptDeadlineAt.toMillis()
            : null;
          if (deadline && deadline > Date.now()) {
            return;
          }

          const bucketId = squad.bucketId || null;
          const participants = squad.participants || [];
          const acceptedIds = new Set(squad.acceptedPlayerIds || []);
          let requeueCount = 0;

          participants.forEach((participant) => {
            if (!participant?.uid) {
              return;
            }
            if (acceptedIds.has(participant.uid) && bucketId) {
              requeueCount += 1;
              queueSoloParticipant(tx, participant, bucketId, requeueCount);
              tx.set(
                queueMetadataRef(bucketId),
                {
                  activeUsers: FieldValue.increment(1),
                  updatedAt: FieldValue.serverTimestamp(),
                },
                { merge: true }
              );
            } else {
              clearSoloMatchmakingSession(tx, participant);
            }
          });

          tx.update(doc.ref, {
            status: "expired",
            updatedAt: FieldValue.serverTimestamp(),
          });
          bucketToRetry = bucketId;
        });

        if (bucketToRetry) {
          await attemptSoloMatchmakingForBucket(bucketToRetry);
        }
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }
  }
);

exports.cleanupExpiredParties = onSchedule(
  { schedule: "every 6 hours", region },
  async () => {
    const cutoff = Timestamp.fromMillis(
      Date.now() - PARTY_TTL_HOURS * 60 * 60 * 1000
    );
    let lastDoc = null;

    while (true) {
      let query = db
        .collection("parties")
        .orderBy("createdAt")
        .endAt(cutoff)
        .limit(20);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      for (const doc of snapshot.docs) {
        await deleteExpiredParty(doc.ref);
      }
    }
  }
);

exports.onPartyMessageCreate = onDocumentCreated(
  { document: "parties/{partyId}/messages/{messageId}", region },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data();
    const partyId = event.params.partyId;
    const partyRef = db.collection("parties").doc(partyId);
    await partyRef.update({
      lastMessage: data.text || "",
      lastMessageAt: FieldValue.serverTimestamp()
    });

    const partySnap = await partyRef.get();
    const partyName = partySnap.exists ? partySnap.data().name || "Party" : "Party";
    const senderId = data.senderId || null;
    const senderName = data.senderName || "Player";
    const messageText = data.text || "";
    const membersSnap = await partyRef
      .collection("members")
      .where("status", "==", "active")
      .get();

    const recipientIds = membersSnap.docs
      .map((doc) => doc.id)
      .filter((uid) => uid && uid !== senderId);

    console.log("[push] party message", {
      partyId,
      senderId,
      recipients: recipientIds.length
    });
    await Promise.all(
      recipientIds.map((uid) =>
        sendPushToUser(
          uid,
          buildPushPayload({
            title: `${senderName} • ${partyName}`,
            body: messageText,
            data: {
              type: "party_message",
              partyId,
              senderId: senderId || ""
            }
          })
        )
      )
    );
  }
);

exports.onDirectMessageCreate = onDocumentCreated(
  { document: "direct_chats/{chatId}/messages/{messageId}", region },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data();
    const chatId = event.params.chatId;
    const chatRef = db.collection("direct_chats").doc(chatId);
    const senderId = data.senderId || null;
    const chatSnap = await chatRef.get();
    let participants = chatSnap.exists
      ? chatSnap.data().participants || []
      : [];
    if (!participants.length && chatId.includes("_")) {
      participants = chatId.split("_");
    }

    const updates = {
      lastMessage: data.text || "",
      lastMessageAt: FieldValue.serverTimestamp(),
      lastMessageSenderId: senderId
    };

    participants.forEach((uid) => {
      if (!uid) return;
      if (senderId && uid === senderId) {
        updates[`unreadCounts.${uid}`] = 0;
        updates[`lastReadAt.${uid}`] = FieldValue.serverTimestamp();
      } else {
        updates[`unreadCounts.${uid}`] = FieldValue.increment(1);
      }
    });

    await chatRef.set(updates, { merge: true });

    const senderName = data.senderName || "Player";
    const messageText = data.text || "";
    const recipientIds = participants.filter(
      (uid) => uid && uid !== senderId
    );

    console.log("[push] direct message", {
      chatId,
      senderId,
      recipients: recipientIds.length
    });
    await Promise.all(
      recipientIds.map((uid) =>
        sendPushToUser(
          uid,
          buildPushPayload({
            title: senderName,
            body: messageText,
            data: {
              type: "direct_message",
              chatId,
              senderId: senderId || ""
            }
          })
        )
      )
    );
  }
);

exports.onUserNotificationCreate = onDocumentCreated(
  { document: "users/{uid}/notifications/{notificationId}", region },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }
    const data = snapshot.data();
    const type = data.type || "";
    if (type !== "chat_request" && type !== "chat_request_response") {
      return;
    }
    const uid = event.params.uid;
    console.log("[push] notification doc", {
      uid,
      type,
      status: data.status || ""
    });
    await sendPushToUser(
      uid,
      buildPushPayload({
        title: data.title || "Notification",
        body: data.body || "",
        data: {
          type,
          status: data.status || "",
          fromUserId: data.fromUserId || "",
          gameId: data.gameId || "",
          rankId: data.rankId || "",
          languageId: data.languageId || ""
        }
      })
    );
  }
);


