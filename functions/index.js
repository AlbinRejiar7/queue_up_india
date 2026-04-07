const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const region = "asia-south1";
const AVAILABILITY_TTL_MINUTES = 5;
const PARTY_TTL_HOURS = 3;
const NOTIFICATION_CHANNEL_ID = "queueup_alerts_default_v1";
const SOLO_MATCH_REQUIRED_PLAYERS = 4;
const SOLO_MATCH_READY_SECONDS = 20;
const DUMMY_ADMIN_KEY = defineSecret("DUMMY_ADMIN_KEY");
const DUMMY_SEED_VERSION = "v1";
const DUMMY_GAMES = ["valorant", "pubg", "freefire"];
const DUMMY_AVAILABILITY_TARGET_PER_GAME = 16;
const DUMMY_PARTY_REFRESH_MINUTES = 90;
const DUMMY_LANGUAGE_POOL = [
  "Hindi",
  "Malayalam",
  "Tamil",
  "Telugu",
  "Kannada",
  "Marathi",
  "Bengali",
  "Punjabi",
  "Gujarati",
  "Urdu",
  "English",
];
const DUMMY_RANKS = {
  valorant: ["Silver 3", "Gold 2", "Platinum 1", "Diamond 1", "Ascendant 1"],
  pubg: ["Gold", "Platinum", "Diamond", "Crown", "Ace"],
  freefire: ["Gold", "Platinum", "Diamond", "Heroic", "Grandmaster"],
};
const DUMMY_PROFILE_SEEDS = [
  { username: "delhi_dynamo", displayName: "DelhiDynamo", languageId: "Hindi" },
  { username: "kochi_clutch", displayName: "KochiClutch", languageId: "Malayalam" },
  { username: "chennai_check", displayName: "ChennaiCheck", languageId: "Tamil" },
  { username: "hyd_havoc", displayName: "HydHavoc", languageId: "Telugu" },
  { username: "blr_blitz", displayName: "BlrBlitz", languageId: "Kannada" },
  { username: "mumbai_mech", displayName: "MumbaiMech", languageId: "Marathi" },
  { username: "kolkata_kraken", displayName: "KolkataKraken", languageId: "Bengali" },
  { username: "punjab_peek", displayName: "PunjabPeek", languageId: "Punjabi" },
  { username: "surat_sniper", displayName: "SuratSniper", languageId: "Gujarati" },
  { username: "lucknow_lagx", displayName: "LucknowLagX", languageId: "Urdu" },
  { username: "goa_glitch", displayName: "GoaGlitch", languageId: "English" },
  { username: "vizag_vortex", displayName: "VizagVortex", languageId: "Telugu" },
  { username: "madurai_monk", displayName: "MaduraiMonk", languageId: "Tamil" },
  { username: "thrissur_tap", displayName: "ThrissurTap", languageId: "Malayalam" },
  { username: "pune_pusher", displayName: "PunePusher", languageId: "Marathi" },
  { username: "patna_ping", displayName: "PatnaPing", languageId: "Hindi" },
  { username: "rajkot_rush", displayName: "RajkotRush", languageId: "Gujarati" },
  { username: "amritsar_ace", displayName: "AmritsarAce", languageId: "Punjabi" },
  { username: "mysore_matrix", displayName: "MysoreMatrix", languageId: "Kannada" },
  { username: "siliguri_storm", displayName: "SiliguriStorm", languageId: "Bengali" },
  { username: "nagpur_nova", displayName: "NagpurNova", languageId: "Marathi" },
  { username: "jaipur_jett", displayName: "JaipurJett", languageId: "Hindi" },
  { username: "noida_nexus", displayName: "NoidaNexus", languageId: "English" },
  { username: "guwahati_ghost", displayName: "GuwahatiGhost", languageId: "English" },
  ...buildAdditionalDummyProfileSeeds(),
];
const DUMMY_PROFILES = DUMMY_PROFILE_SEEDS.map((seed, index) => ({
  uid: `dummy_v1_${String(index + 1).padStart(3, "0")}`,
  ...seed,
  avatarUrl: buildDummyAvatarUrl(seed.displayName),
}));
const DUMMY_PARTY_BLUEPRINTS = [
  {
    partyId: "dummy_party_v1_hindi",
    languageId: "Hindi",
    gameId: "pubg",
    rankId: "Crown",
    name: "Hindi Rank Rush",
    partyCode: "HIN123",
    maxPlayers: 4,
    extraMembers: 2,
  },
  {
    partyId: "dummy_party_v1_malayalam",
    languageId: "Malayalam",
    gameId: "valorant",
    rankId: "Platinum 1",
    name: "Malayalam Night Stack",
    partyCode: "MAL456",
    maxPlayers: 5,
    extraMembers: 1,
  },
  {
    partyId: "dummy_party_v1_tamil",
    languageId: "Tamil",
    gameId: "freefire",
    rankId: "Heroic",
    name: "Tamil Push Squad",
    partyCode: "TAM789",
    maxPlayers: 4,
    extraMembers: 2,
  },
  {
    partyId: "dummy_party_v1_telugu",
    languageId: "Telugu",
    gameId: "pubg",
    rankId: "Ace",
    name: "Telugu Late Night Room",
    partyCode: "TEL234",
    maxPlayers: 4,
    extraMembers: 1,
  },
  {
    partyId: "dummy_party_v1_kannada",
    languageId: "Kannada",
    gameId: "valorant",
    rankId: "Gold 2",
    name: "Kannada Chill Queue",
    partyCode: "KAN567",
    maxPlayers: 5,
    extraMembers: 2,
  },
  {
    partyId: "dummy_party_v1_marathi",
    languageId: "Marathi",
    gameId: "freefire",
    rankId: "Diamond",
    name: "Marathi Grind Room",
    partyCode: "MAR890",
    maxPlayers: 4,
    extraMembers: 1,
  },
  {
    partyId: "dummy_party_v1_bengali",
    languageId: "Bengali",
    gameId: "pubg",
    rankId: "Diamond",
    name: "Bengali Duo to Squad",
    partyCode: "BEN321",
    maxPlayers: 4,
    extraMembers: 2,
  },
  {
    partyId: "dummy_party_v1_punjabi",
    languageId: "Punjabi",
    gameId: "valorant",
    rankId: "Ascendant 1",
    name: "Punjabi Rank Push",
    partyCode: "PUN654",
    maxPlayers: 5,
    extraMembers: 1,
  },
  {
    partyId: "dummy_party_v1_gujarati",
    languageId: "Gujarati",
    gameId: "freefire",
    rankId: "Grandmaster",
    name: "Gujarati Clash Room",
    partyCode: "GUJ987",
    maxPlayers: 4,
    extraMembers: 1,
  },
  {
    partyId: "dummy_party_v1_urdu",
    languageId: "Urdu",
    gameId: "pubg",
    rankId: "Platinum",
    name: "Urdu Evening Squad",
    partyCode: "URD741",
    maxPlayers: 4,
    extraMembers: 1,
  },
];
const DUMMY_REPLY_MESSAGES = [
  "I am in. Send the party code.",
  "Yes bro, I can play now.",
  "Queue in 2 minutes?",
  "I am ready. What server are you on?",
  "Let us run one match first.",
  "I can join. Send your ID.",
  "Sounds good. Invite me.",
  "I am online now, let us play.",
  "Okay, I am up for it.",
  "Yes, we can queue now.",
];

function buildDummyAvatarUrl(seed) {
  return `https://api.dicebear.com/9.x/adventurer-neutral/png?seed=${encodeURIComponent(seed)}`;
}

function buildAdditionalDummyProfileSeeds() {
  const groups = [
    {
      languageId: "Hindi",
      cities: ["Kanpur", "Varanasi", "Ranchi", "Prayagraj"],
    },
    {
      languageId: "Malayalam",
      cities: ["Kozhikode", "Kannur", "Kottayam", "Palakkad"],
    },
    {
      languageId: "Tamil",
      cities: ["Coimbatore", "Trichy", "Salem", "Tirunelveli"],
    },
    {
      languageId: "Telugu",
      cities: ["Vijayawada", "Guntur", "Warangal", "Nellore"],
    },
    {
      languageId: "Kannada",
      cities: ["Mysuru", "Hubli", "Mangaluru", "Belagavi"],
    },
    {
      languageId: "Marathi",
      cities: ["Nashik", "Kolhapur", "Aurangabad", "Solapur"],
    },
    {
      languageId: "Bengali",
      cities: ["Howrah", "Durgapur", "SiliguriX", "Kharagpur"],
    },
    {
      languageId: "Punjabi",
      cities: ["Ludhiana", "Jalandhar", "Mohali", "Bathinda"],
    },
    {
      languageId: "Gujarati",
      cities: ["Ahmedabad", "Vadodara", "Bhavnagar", "Jamnagar"],
    },
    {
      languageId: "Urdu",
      cities: ["Aligarh", "BhopalX", "HyderUr", "Rampur"],
    },
    {
      languageId: "English",
      cities: ["Shillong", "Aizawl", "Imphal", "Chandigarh"],
    },
  ];
  const suffixes = [
    "Pulse",
    "Nova",
    "Rush",
    "Scope",
    "Strike",
    "Flick",
    "Quest",
    "Phantom",
  ];
  const seeds = [];
  let suffixIndex = 0;

  groups.forEach((group) => {
    group.cities.forEach((city) => {
      const suffix = suffixes[suffixIndex % suffixes.length];
      suffixIndex += 1;
      const rawName = `${city}${suffix}`;
      const username = slugify(rawName).replace(/_/g, "").slice(0, 18);
      seeds.push({
        username,
        displayName: rawName,
        languageId: group.languageId,
      });
    });
  });
  return seeds;
}

function randomFrom(items) {
  return items[Math.floor(Math.random() * items.length)];
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function shuffle(items) {
  const values = [...items];
  for (let index = values.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1));
    const temp = values[index];
    values[index] = values[swapIndex];
    values[swapIndex] = temp;
  }
  return values;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isDummyData(data) {
  return data?.isDummy === true && data?.dummySeed === DUMMY_SEED_VERSION;
}

function pickDummyGameId() {
  return randomFrom(["valorant", "pubg", "freefire"]);
}

function pickDummyRankId(gameId) {
  return randomFrom(DUMMY_RANKS[gameId] || DUMMY_RANKS.valorant);
}

function dummyUserIds() {
  return DUMMY_PROFILES.map((profile) => profile.uid);
}

function findDummyProfile(uid) {
  return DUMMY_PROFILES.find((profile) => profile.uid === uid) || null;
}

function isDummyUid(uid) {
  return String(uid || "").startsWith("dummy_v1_");
}

async function ensureDummyUsers() {
  const writer = db.bulkWriter();
  DUMMY_PROFILES.forEach((profile) => {
    writer.set(
      db.collection("users").doc(profile.uid),
      {
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        preferredLanguageId: profile.languageId,
        isDummy: true,
        dummySeed: DUMMY_SEED_VERSION,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
  await writer.close();
  return { users: DUMMY_PROFILES.length };
}

async function fetchDummyUserDocs() {
  return db.collection("users").where("dummySeed", "==", DUMMY_SEED_VERSION).get();
}

async function syncDummyAvailability() {
  const activeAssignments = new Map();
  const shuffled = shuffle(DUMMY_PROFILES);
  let cursor = 0;

  DUMMY_GAMES.forEach((gameId) => {
    const perGameProfiles = shuffled.slice(
      cursor,
      cursor + DUMMY_AVAILABILITY_TARGET_PER_GAME
    );
    cursor += DUMMY_AVAILABILITY_TARGET_PER_GAME;
    perGameProfiles.forEach((profile) => {
      activeAssignments.set(profile.uid, {
        gameId,
        rankId: pickDummyRankId(gameId),
        languageId:
          Math.random() < 0.8 ? profile.languageId : randomFrom(DUMMY_LANGUAGE_POOL),
        updatedAt: Timestamp.fromMillis(
          Date.now() - randomInt(1, 8) * 60 * 1000
        ),
      });
    });
  });
  const writer = db.bulkWriter();
  DUMMY_PROFILES.forEach((profile) => {
    const docRef = db.collection("availability").doc(profile.uid);
    const assignment = activeAssignments.get(profile.uid);
    if (!assignment) {
      writer.delete(docRef);
      return;
    }
    writer.set(
      docRef,
      {
        uid: profile.uid,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        gameId: assignment.gameId,
        rankId: assignment.rankId,
        languageId: assignment.languageId,
        isAvailable: true,
        isDummy: true,
        dummySeed: DUMMY_SEED_VERSION,
        availableSince: assignment.updatedAt,
        updatedAt: assignment.updatedAt,
      },
      { merge: true }
    );
  });
  await writer.close();
  return {
    available: activeAssignments.size,
    perGame: DUMMY_GAMES.reduce((acc, gameId) => {
      acc[gameId] = DUMMY_AVAILABILITY_TARGET_PER_GAME;
      return acc;
    }, {}),
  };
}

async function clearDummyUserPartyState() {
  const dummyUsersSnapshot = await fetchDummyUserDocs();
  const writer = db.bulkWriter();
  await Promise.all(
    dummyUsersSnapshot.docs.map(async (userDoc) => {
      const roomsSnapshot = await db
        .collection("users")
        .doc(userDoc.id)
        .collection("rooms")
        .get();
      roomsSnapshot.docs.forEach((doc) => writer.delete(doc.ref));
      writer.set(
        db.collection("users").doc(userDoc.id),
        {
          currentPartyId: null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    })
  );
  await writer.close();
}

function shouldRefreshDummyParties(snapshot) {
  if (snapshot.size !== DUMMY_PARTY_BLUEPRINTS.length) {
    return true;
  }
  const cutoff = Date.now() - DUMMY_PARTY_REFRESH_MINUTES * 60 * 1000;
  return snapshot.docs.some((doc) => {
    const createdAt = doc.data()?.createdAt;
    return !createdAt || typeof createdAt.toMillis !== "function" || createdAt.toMillis() < cutoff;
  });
}

async function syncDummyParties({ forceRefresh = false } = {}) {
  const snapshot = await db
    .collection("parties")
    .where("dummySeed", "==", DUMMY_SEED_VERSION)
    .get();

  if (!forceRefresh && !shouldRefreshDummyParties(snapshot)) {
    return { parties: snapshot.size, refreshed: false };
  }

  await clearDummyUserPartyState();
  for (const doc of snapshot.docs) {
    await db.recursiveDelete(doc.ref);
  }

  const memberPool = [...DUMMY_PROFILES.slice(DUMMY_PARTY_BLUEPRINTS.length)];
  let memberCursor = 0;
  const writer = db.bulkWriter();

  DUMMY_PARTY_BLUEPRINTS.forEach((blueprint, index) => {
    const host = DUMMY_PROFILES[index];
    const extraMembers = memberPool.slice(
      memberCursor,
      memberCursor + blueprint.extraMembers
    );
    memberCursor += blueprint.extraMembers;
    const participants = [host, ...extraMembers];
    const createdAt = Timestamp.fromMillis(
      Date.now() - randomInt(12, 96) * 60 * 1000
    );
    const currentPlayers = participants.length;
    const partyStatus = currentPlayers >= blueprint.maxPlayers ? "full" : "open";
    const partyRef = db.collection("parties").doc(blueprint.partyId);

    writer.set(partyRef, {
      name: blueprint.name,
      hostId: host.uid,
      hostDisplayName: host.displayName,
      gameId: blueprint.gameId,
      rankId: blueprint.rankId,
      languageId: blueprint.languageId,
      maxPlayers: blueprint.maxPlayers,
      neededPlayers: blueprint.maxPlayers,
      currentPlayers,
      partyCode: blueprint.partyCode,
      status: partyStatus,
      createdAt,
      updatedAt: createdAt,
      isDummy: true,
      dummySeed: DUMMY_SEED_VERSION,
    });

    participants.forEach((participant) => {
      const isHost = participant.uid === host.uid;
      writer.set(partyRef.collection("members").doc(participant.uid), {
        uid: participant.uid,
        displayName: participant.displayName,
        avatarUrl: participant.avatarUrl,
        role: isHost ? "host" : "member",
        status: "active",
        joinedAt: createdAt,
        isDummy: true,
        dummySeed: DUMMY_SEED_VERSION,
      });
      writer.set(
        db.collection("users").doc(participant.uid).collection("rooms").doc(blueprint.partyId),
        {
          partyId: blueprint.partyId,
          role: isHost ? "host" : "member",
          gameId: blueprint.gameId,
          rankId: blueprint.rankId,
          languageId: blueprint.languageId,
          status: "active",
          lastMessageAt: null,
          isDummy: true,
          dummySeed: DUMMY_SEED_VERSION,
        },
        { merge: true }
      );
      writer.set(
        db.collection("users").doc(participant.uid),
        {
          currentPartyId: blueprint.partyId,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });
  });

  await writer.close();
  return { parties: DUMMY_PARTY_BLUEPRINTS.length, refreshed: true };
}

async function countDummyDirectChats() {
  const refs = new Set();
  await Promise.all(
    dummyUserIds().map(async (uid) => {
      const snapshot = await db
        .collection("direct_chats")
        .where("participants", "array-contains", uid)
        .get();
      snapshot.docs.forEach((doc) => refs.add(doc.ref.path));
    })
  );
  return refs.size;
}

async function fetchDummyDataStatus() {
  const [usersSnapshot, availabilitySnapshot, partiesSnapshot, directChats] =
    await Promise.all([
      db.collection("users").where("dummySeed", "==", DUMMY_SEED_VERSION).get(),
      db.collection("availability").where("dummySeed", "==", DUMMY_SEED_VERSION).get(),
      db.collection("parties").where("dummySeed", "==", DUMMY_SEED_VERSION).get(),
      countDummyDirectChats(),
    ]);

  return {
    users: usersSnapshot.size,
    availability: availabilitySnapshot.size,
    parties: partiesSnapshot.size,
    directChats,
  };
}

async function seedDummyData({
  forcePartyRefresh = true,
  includeStatus = true,
} = {}) {
  const users = await ensureDummyUsers();
  const availability = await syncDummyAvailability();
  const parties = await syncDummyParties({ forceRefresh: forcePartyRefresh });
  if (!includeStatus) {
    return { ...users, ...availability, ...parties };
  }
  const status = await fetchDummyDataStatus();
  return { ...users, ...availability, ...parties, status };
}

async function cleanupDummyDirectChats() {
  const refs = new Map();
  await Promise.all(
    dummyUserIds().map(async (uid) => {
      const snapshot = await db
        .collection("direct_chats")
        .where("participants", "array-contains", uid)
        .get();
      snapshot.docs.forEach((doc) => {
        refs.set(doc.ref.path, doc.ref);
      });
    })
  );

  for (const ref of refs.values()) {
    await db.recursiveDelete(ref);
  }
  return refs.size;
}

async function cleanupDummyData() {
  const dummyUsersSnapshot = await fetchDummyUserDocs();
  const availabilityWriter = db.bulkWriter();
  dummyUsersSnapshot.docs.forEach((userDoc) => {
    availabilityWriter.delete(db.collection("availability").doc(userDoc.id));
  });
  await availabilityWriter.close();

  await clearDummyUserPartyState();

  const partySnapshot = await db
    .collection("parties")
    .where("dummySeed", "==", DUMMY_SEED_VERSION)
    .get();
  for (const doc of partySnapshot.docs) {
    await db.recursiveDelete(doc.ref);
  }

  const directChatsDeleted = await cleanupDummyDirectChats();

  for (const userDoc of dummyUsersSnapshot.docs) {
    await db.recursiveDelete(userDoc.ref);
  }

  return {
    usersDeleted: dummyUsersSnapshot.size,
    partiesDeleted: partySnapshot.size,
    directChatsDeleted,
  };
}

async function maybeSendDummyDirectReply({
  chatRef,
  chatId,
  senderId,
  recipientIds,
  messageData,
}) {
  const messageText = String(messageData?.text || "").trim();
  if (!senderId || !recipientIds.length || !messageText) {
    return;
  }
  if (messageData?.isDummyAutoReply === true || isDummyUid(senderId)) {
    return;
  }

  const dummyRecipientId = recipientIds.find((uid) => isDummyUid(uid));
  if (!dummyRecipientId) {
    return;
  }

  const dummyProfile = findDummyProfile(dummyRecipientId);
  if (!dummyProfile) {
    return;
  }

  const dummyUserSnap = await db.collection("users").doc(dummyRecipientId).get();
  if (!isDummyData(dummyUserSnap.data())) {
    return;
  }

  await sleep(randomInt(4, 10) * 1000);

  await chatRef.collection("messages").add({
    senderId: dummyRecipientId,
    senderName: dummyProfile.displayName,
    text: randomFrom(DUMMY_REPLY_MESSAGES),
    createdAt: FieldValue.serverTimestamp(),
    isDummyAutoReply: true,
    dummySeed: DUMMY_SEED_VERSION,
  });

  console.log("[dummy] replied to direct chat", {
    chatId,
    senderId,
    dummyRecipientId,
  });
}

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

function applyQueueMetadataDelta(tx, bucketId, delta) {
  if (!bucketId || !delta) {
    return;
  }
  tx.set(
    queueMetadataRef(bucketId),
    {
      activeUsers: FieldValue.increment(delta),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

function parseDirectChatParticipants(chatId) {
  const parts = String(chatId || "").split("_").filter(Boolean);
  return parts.length === 2 ? parts : [];
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
      applyQueueMetadataDelta(tx, bucketId, -SOLO_MATCH_REQUIRED_PLAYERS);

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

function queuePartySystemMessage(tx, partyRef, { actorId, actorName, text }) {
  const messageRef = partyRef.collection("messages").doc();
  tx.set(messageRef, {
    senderId: actorId || "",
    senderName: actorName || "System",
    text,
    messageType: "system",
    createdAt: FieldValue.serverTimestamp()
  });
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

function buildPrimaryTokenFields(token, platform) {
  return {
    primaryFcmToken: token,
    primaryFcmPlatform: platform || "unknown",
    primaryFcmUpdatedAt: FieldValue.serverTimestamp(),
  };
}

function buildClearPrimaryTokenFields() {
  return {
    primaryFcmToken: FieldValue.delete(),
    primaryFcmPlatform: FieldValue.delete(),
    primaryFcmUpdatedAt: FieldValue.delete(),
  };
}

function isInvalidTokenErrorCode(code) {
  return (
    code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token"
  );
}

async function fetchUserPushTargets(uid, excludedTokens = []) {
  const userSnap = await db.collection("users").doc(uid).get();
  const userData = userSnap.exists ? userSnap.data() || {} : {};
  const primaryToken = String(userData.primaryFcmToken || "").trim();
  const excluded = new Set(
    excludedTokens
      .map((token) => String(token || "").trim())
      .filter(Boolean)
  );

  if (primaryToken && !excluded.has(primaryToken)) {
    return {
      tokens: [primaryToken],
      source: "primary",
      primaryToken,
    };
  }

  const tokens = (await fetchUserTokens(uid)).filter(
    (token) => token && !excluded.has(token)
  );

  return {
    tokens: [...new Set(tokens)],
    source: "subcollection",
    primaryToken,
  };
}

async function pruneInvalidTokens(uid, tokens, response, options = {}) {
  if (!response || !response.responses) {
    return;
  }
  const primaryToken = String(options.primaryToken || "").trim();
  const batch = db.batch();
  let hasWrites = false;
  response.responses.forEach((result, index) => {
    if (result.success) {
      return;
    }
    const code = result.error && result.error.code;
    if (isInvalidTokenErrorCode(code)) {
      const invalidToken = String(tokens[index] || "").trim();
      if (!invalidToken) {
        return;
      }
      batch.delete(
        db
          .collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .doc(invalidToken)
      );
      hasWrites = true;
      if (primaryToken && invalidToken === primaryToken) {
        batch.set(
          db.collection("users").doc(uid),
          buildClearPrimaryTokenFields(),
          { merge: true }
        );
      }
    }
  });
  if (hasWrites) {
    await batch.commit();
  }
}

async function sendPushToUser(uid, payload) {
  const normalizedPayload = normalizePushPayload(payload);
  let target = await fetchUserPushTargets(uid);
  if (!target.tokens.length) {
    console.log("[push] skip: no tokens for", uid);
    return;
  }
  console.log("[push] sending", {
    uid,
    tokens: target.tokens.length,
    source: target.source,
    title: normalizedPayload?.notification?.title || "",
    body: normalizedPayload?.notification?.body || ""
  });
  let response = await messaging.sendEachForMulticast({
    tokens: target.tokens,
    ...normalizedPayload
  });
  console.log("[push] result", {
    uid,
    successCount: response.successCount,
    failureCount: response.failureCount
  });
  await pruneInvalidTokens(uid, target.tokens, response, {
    primaryToken: target.primaryToken,
  });

  const shouldRetryWithFallback =
    target.source === "primary" &&
    target.tokens.length === 1 &&
    response.responses.length === 1 &&
    !response.responses[0].success &&
    isInvalidTokenErrorCode(response.responses[0].error && response.responses[0].error.code);

  if (!shouldRetryWithFallback) {
    return;
  }

  target = await fetchUserPushTargets(uid, target.tokens);
  if (!target.tokens.length) {
    console.log("[push] no fallback tokens for", uid);
    return;
  }

  console.log("[push] retrying with fallback tokens", {
    uid,
    tokens: target.tokens.length,
  });
  response = await messaging.sendEachForMulticast({
    tokens: target.tokens,
    ...normalizedPayload
  });
  console.log("[push] fallback result", {
    uid,
    successCount: response.successCount,
    failureCount: response.failureCount
  });
  await pruneInvalidTokens(uid, target.tokens, response, {
    primaryToken: target.primaryToken,
  });
}

exports.claimFcmToken = onCall({ region, invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const uid = request.auth.uid;
  const token = String(request.data?.token || "").trim();
  const platform = String(request.data?.platform || "").trim() || "unknown";

  if (!token) {
    throw new HttpsError("invalid-argument", "token is required.");
  }

  const snapshot = await db
    .collectionGroup("fcmTokens")
    .where("token", "==", token)
    .get();

  const batch = db.batch();
  let removedFrom = 0;
  const ownerRefsToCheck = new Map();

  snapshot.docs.forEach((doc) => {
    const ownerRef = doc.ref.parent.parent;
    const ownerUid = ownerRef ? ownerRef.id : "";
    if (ownerUid && ownerUid !== uid) {
      batch.delete(doc.ref);
      removedFrom += 1;
      ownerRefsToCheck.set(ownerUid, ownerRef);
    }
  });

  const ownerSnaps = await Promise.all(
    Array.from(ownerRefsToCheck.values()).map((ref) => ref.get())
  );
  ownerSnaps.forEach((ownerSnap) => {
    const ownerData = ownerSnap.exists ? ownerSnap.data() || {} : {};
    if (String(ownerData.primaryFcmToken || "").trim() === token) {
      batch.set(ownerSnap.ref, buildClearPrimaryTokenFields(), { merge: true });
    }
  });

  batch.set(
    db.collection("users").doc(uid).collection("fcmTokens").doc(token),
    {
      token,
      platform,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  batch.set(
    db.collection("users").doc(uid),
    buildPrimaryTokenFields(token, platform),
    { merge: true }
  );

  await batch.commit();
  return { claimed: true, removedFrom };
});

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

function partyExpiryCutoffMillis() {
  return Date.now() - PARTY_TTL_HOURS * 60 * 60 * 1000;
}

function isExpiredPartyData(data) {
  const createdAt = data?.createdAt;
  return !!createdAt &&
    typeof createdAt.toMillis === "function" &&
    createdAt.toMillis() <= partyExpiryCutoffMillis();
}

async function deleteExpiredParty(partyRef) {
  const freshSnap = await partyRef.get();
  if (!freshSnap.exists) {
    return false;
  }

  if (!isExpiredPartyData(freshSnap.data())) {
    return false;
  }

  await clearPartyUserReferences(partyRef.id);
  await db.recursiveDelete(partyRef);
  return true;
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
  const actorName = String(displayName || "QueuePlayer").trim() || "QueuePlayer";

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
    queuePartySystemMessage(tx, partyRef, {
      actorId: uid,
      actorName,
      text: `${actorName} joined the party.`,
    });
  });

  if (partyData && partyData.hostId && partyData.hostId !== uid) {
    console.log("[push] party join -> host", {
      partyId,
      hostId: partyData.hostId,
      senderId: uid
    });
    await sendPushToUser(
        partyData.hostId,
        buildPushPayload({
          title: "Party update",
          body: `${actorName} joined your party.`,
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
      applyQueueMetadataDelta(tx, bucketId, -1);
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
    let requeueCount = 0;
    participants.forEach((participant) => {
      if (!participant?.uid) {
        return;
      }
      if (participant.uid === uid) {
        clearSoloMatchmakingSession(tx, participant);
        return;
      }
      requeueCount += 1;
      queueSoloParticipant(tx, participant, bucketId, requeueCount);
    });
    applyQueueMetadataDelta(tx, bucketId, requeueCount);
    tx.update(squadRef, {
      status: "cancelled",
      rejectedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (bucketId && requeueCount > 0) {
      bucketToRetry = bucketId;
    }
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
    });
    applyQueueMetadataDelta(tx, bucketId, requeueCount);

    tx.update(squadRef, {
      status: "cancelled",
      rejectedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (bucketId && requeueCount > 0) {
      bucketToRetry = bucketId;
    }
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
    const actorName =
      String(memberSnap.data().displayName || "QueuePlayer").trim() ||
      "QueuePlayer";
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
      queuePartySystemMessage(tx, partyRef, {
        actorId: uid,
        actorName,
        text: `${actorName} left the party.`,
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
    queuePartySystemMessage(tx, partyRef, {
      actorId: uid,
      actorName,
      text: `${actorName} left the party.`,
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
    if (memberId === uid) {
      throw new HttpsError("failed-precondition", "Host cannot kick themselves.");
    }

    const memberRef = partyRef.collection("members").doc(memberId);
    const memberSnap = await tx.get(memberRef);
    if (!memberSnap.exists || memberSnap.data().status !== "active") {
      return;
    }
    if (memberSnap.data().role === "host" || party.hostId === memberId) {
      throw new HttpsError("failed-precondition", "Host cannot be kicked.");
    }

    const activeMembersSnap = await tx.get(
      partyRef.collection("members").where("status", "==", "active")
    );
    const activeMemberIds = activeMembersSnap.docs.map((doc) => doc.id);
    const nextCount = activeMemberIds.filter((activeId) => activeId !== memberId).length;
    const maxPlayers = party.maxPlayers || party.neededPlayers || 0;

    tx.update(memberRef, {
      status: "kicked",
      kickedAt: FieldValue.serverTimestamp()
    });

    tx.update(partyRef, {
      currentPlayers: nextCount,
      status: maxPlayers > 0 && nextCount >= maxPlayers ? "full" : "open",
      updatedAt: FieldValue.serverTimestamp()
    });

    const roomRef = db.collection("users").doc(memberId).collection("rooms").doc(partyId);
    tx.set(roomRef, { status: "kicked" }, { merge: true });
    tx.set(
      db.collection("users").doc(memberId),
      { currentPartyId: null, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
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

exports.cleanupSoloMatchmaking = onSchedule(
  { schedule: "every 1 minutes", region },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now());
    let lastDoc = null;
    const bucketsToRetry = new Set();

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
            } else {
              clearSoloMatchmakingSession(tx, participant);
            }
          });
          applyQueueMetadataDelta(tx, bucketId, requeueCount);

          tx.update(doc.ref, {
            status: "expired",
            updatedAt: FieldValue.serverTimestamp(),
          });
          if (bucketId && requeueCount > 0) {
            bucketToRetry = bucketId;
          }
        });

        if (bucketToRetry) {
          bucketsToRetry.add(bucketToRetry);
        }
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    for (const bucketId of bucketsToRetry) {
      await attemptSoloMatchmakingForBucket(bucketId);
    }
  }
);

exports.cleanupExpiredPartiesOnOpen = onCall(
  { region, invoker: "public" },
  async (request) => {
    const requestedPartyId = String(request.data?.partyId || "").trim();

    if (requestedPartyId) {
      const deleted = await deleteExpiredParty(
        db.collection("parties").doc(requestedPartyId)
      );
      return { cleaned: deleted ? 1 : 0 };
    }

    const cutoff = Timestamp.fromMillis(partyExpiryCutoffMillis());
    const snapshot = await db
      .collection("parties")
      .orderBy("createdAt")
      .endAt(cutoff)
      .limit(20)
      .get();

    let cleaned = 0;
    for (const doc of snapshot.docs) {
      if (await deleteExpiredParty(doc.ref)) {
        cleaned += 1;
      }
    }

    return { cleaned };
  }
);

exports.manageDummyData = onRequest(
  { region, secrets: [DUMMY_ADMIN_KEY] },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Use POST." });
      return;
    }

    const providedKey = String(request.get("x-dummy-admin-key") || "").trim();
    const expectedKey = String(DUMMY_ADMIN_KEY.value() || "").trim();
    if (!providedKey || !expectedKey || providedKey !== expectedKey) {
      response.status(403).json({ error: "Forbidden." });
      return;
    }

    const action = String(request.body?.action || "").trim().toLowerCase();
    try {
      if (action === "cleanup") {
        const result = await cleanupDummyData();
        const status = await fetchDummyDataStatus();
        response.json({ ok: true, action, result, status });
        return;
      }
      if (action === "status") {
        const status = await fetchDummyDataStatus();
        response.json({ ok: true, action, status });
        return;
      }

      const result = await seedDummyData({
        forcePartyRefresh: true,
        includeStatus: true,
      });
      response.json({ ok: true, action: action || "seed", result });
    } catch (error) {
      console.error("[dummy] manageDummyData failed", error);
      response.status(500).json({
        ok: false,
        action,
        error: error?.message || "Unknown error",
      });
    }
  }
);

exports.maintainDummyPresence = onSchedule(
  {
    schedule: "every 10 minutes",
    region,
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const result = await seedDummyData({
      forcePartyRefresh: false,
      includeStatus: false,
    });
    console.log("[dummy] maintenance", result);
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
    const isSystemMessage = data.messageType === "system";
    await partyRef.update({
      lastMessage: data.text || "",
      lastMessageAt: FieldValue.serverTimestamp()
    });

    if (isSystemMessage) {
      return;
    }

    const partyName = String(data.partyName || "").trim() || "Party";
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
    const clientSynced = data.clientSynced === true;
    let participants = parseDirectChatParticipants(chatId);
    if (!participants.length) {
      const chatSnap = await chatRef.get();
      participants = chatSnap.exists
        ? chatSnap.data().participants || []
        : [];
    }

    if (!clientSynced) {
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

    await maybeSendDummyDirectReply({
      chatRef,
      chatId,
      senderId,
      recipientIds,
      messageData: data,
    });
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


