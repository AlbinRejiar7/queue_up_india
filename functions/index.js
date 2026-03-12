const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const region = "asia-south1";
const AVAILABILITY_TTL_MINUTES = 5;

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

  await db.runTransaction(async (tx) => {
    const partyRef = db.collection("parties").doc(partyId);
    const partySnap = await tx.get(partyRef);
    if (!partySnap.exists) {
      throw new HttpsError("not-found", "Party not found.");
    }

    const party = partySnap.data();
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
    const isHost = party.hostId === uid || memberSnap.data().role === "host";
    const currentPlayers = party.currentPlayers || 0;
    const maxPlayers = party.maxPlayers || party.neededPlayers || 0;
    const nextCount = Math.max(currentPlayers - 1, 0);

    if (isHost) {
      tx.update(partyRef, {
        status: "closed",
        updatedAt: FieldValue.serverTimestamp()
      });
      tx.delete(memberRef);
    } else {
      tx.update(memberRef, {
        status: "left",
        leftAt: FieldValue.serverTimestamp()
      });
      tx.update(partyRef, {
        currentPlayers: nextCount,
        status: maxPlayers > 0 && nextCount >= maxPlayers ? "full" : "open"
      });
      const roomRef = db
        .collection("users")
        .doc(uid)
        .collection("rooms")
        .doc(partyId);
      tx.set(roomRef, { status: "left" }, { merge: true });
    }
  });

  const partyRef = db.collection("parties").doc(partyId);
  const partySnap = await partyRef.get();
  if (partySnap.exists && partySnap.data().status === "closed") {
    const membersSnap = await partyRef
      .collection("members")
      .where("status", "==", "active")
      .get();

    const batch = db.batch();
    membersSnap.docs.forEach((doc) => {
      const memberId = doc.id;
      batch.set(
        db.collection("users").doc(memberId).collection("rooms").doc(partyId),
        { status: "closed" },
        { merge: true }
      );
      batch.set(
        db.collection("users").doc(memberId),
        { currentPartyId: null, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
      batch.delete(doc.ref);
    });
    await batch.commit();
    await partyRef.delete();
  }

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

  await db.runTransaction(async (tx) => {
    const partyRef = db.collection("parties").doc(partyId);
    const partySnap = await tx.get(partyRef);
    if (!partySnap.exists) {
      throw new HttpsError("not-found", "Party not found.");
    }

    const party = partySnap.data();
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
  }
);
