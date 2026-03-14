const {onRequest} = require("firebase-functions/v2/https");
const {
onDocumentCreated,
onDocumentDeleted,
onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {onValueCreated} = require("firebase-functions/v2/database");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

async function getUserDoc(uid) {
if (!uid) {
return null;
}

const userDoc = await admin.firestore().collection("users").doc(uid).get();
return userDoc.exists ? userDoc : null;
}

async function isFirestoreAdmin(uid) {
const userDoc = await getUserDoc(uid);
if (!userDoc) {
return false;
}

const userData = userDoc.data() || {};
return userData.isAdmin === true;
}

async function requireAdminHttpRequest(req, res) {
const authHeader = req.get("Authorization") || "";
const match = authHeader.match(/^Bearer (.+)$/);

if (!match) {
res.status(401).json({error: "Missing bearer token"});
return null;
}

try {
const decodedToken = await admin.auth().verifyIdToken(match[1]);
const uid = decodedToken.uid || "";

if (!(await isFirestoreAdmin(uid))) {
  res.status(403).json({error: "Admin access required"});
  return null;
}

return decodedToken;
} catch (error) {
logger.warn("Admin HTTP auth failed", {error: error.message});
res.status(401).json({error: "Invalid bearer token"});
return null;
}
}

async function sendPushToUser(uid, title, body, data = {}) {
if (!uid) {
logger.warn("Missing uid for push send");
return;
}

const userDoc = await getUserDoc(uid);

if (!userDoc) {
logger.warn("User doc not found", {uid});
return;
}

const userData = userDoc.data() || {};
const token = userData.fcmToken;

if (!token) {
logger.warn("No FCM token found for user", {uid});
return;
}

const message = {
token,
notification: {
title,
body,
},
data: {
click_action: "FLUTTER_NOTIFICATION_CLICK",
...Object.fromEntries(
Object.entries(data).map(([key, value]) => [key, String(value)])
),
},
};

const response = await admin.messaging().send(message);
logger.info("Push notification sent", {uid, response});
}

exports.sendTestNotification = onRequest(async (req, res) => {
try {
if (req.method !== "POST") {
return res.status(405).json({error: "Method not allowed"});
}

const decodedToken = await requireAdminHttpRequest(req, res);
if (!decodedToken) {
  return;
}

const {token, title, body} = req.body || {};

if (!token) {
  return res.status(400).json({error: "Missing token"});
}

const message = {
  token,
  notification: {
    title: title || "Test Notification",
    body: body || "Your Firebase push notification is working.",
  },
  data: {
    type: "test",
    click_action: "FLUTTER_NOTIFICATION_CLICK",
  },
};

const response = await admin.messaging().send(message);

logger.info("Push notification sent successfully", {
  response,
  requestedBy: decodedToken.uid,
});

return res.status(200).json({
  success: true,
  messageId: response,
});
} catch (error) {
logger.error("Error sending push notification", error);
return res.status(500).json({
success: false,
error: error.message,
});
}
});

exports.onTransactionCreated = onDocumentCreated(
"transactions/{transactionId}",
async (event) => {
try {
const snapshot = event.data;
if (!snapshot) return;

  const data = snapshot.data() || {};

  await sendPushToUser(
    data.hostId,
    "New Rental Request",
    `${data.renterName || "Someone"} sent a request for ${data.itemName || "your item"}.`,
    {
      type: "rental_request_sent",
      transactionId: event.params.transactionId,
      rentalId: data.rentalId || "",
    }
  );
} catch (error) {
  logger.error("onTransactionCreated failed", error);
}
}
);

exports.onTransactionUpdated = onDocumentUpdated(
"transactions/{transactionId}",
async (event) => {
try {
const beforeData = event.data.before.data() || {};
const afterData = event.data.after.data() || {};

  const beforeStatus = beforeData.status;
  const afterStatus = afterData.status;

  if (beforeStatus === afterStatus) {
    return;
  }

  if (afterStatus === "Accepted") {
    await sendPushToUser(
      afterData.renterId,
      "Request Accepted",
      `${afterData.hostName || "Host"} accepted your request for ${afterData.itemName || "the item"}.`,
      {
        type: "rental_request_accepted",
        transactionId: event.params.transactionId,
        rentalId: afterData.rentalId || "",
      }
    );
  }

  if (afterStatus === "Rejected") {
    await sendPushToUser(
      afterData.renterId,
      "Request Rejected",
      `${afterData.hostName || "Host"} rejected your request for ${afterData.itemName || "the item"}.`,
      {
        type: "rental_request_rejected",
        transactionId: event.params.transactionId,
        rentalId: afterData.rentalId || "",
      }
    );
  }
} catch (error) {
  logger.error("onTransactionUpdated failed", error);
}
}
);

exports.onRentalDeleted = onDocumentDeleted(
"rentals/{rentalId}",
async (event) => {
const rentalId = event.params.rentalId;
const firestore = admin.firestore();
const batch = firestore.batch();

try {
  const [transactionSnapshot, favoriteSnapshot, chatRoomSnapshot] =
    await Promise.all([
      firestore
          .collection("transactions")
          .where("rentalId", "==", rentalId)
          .get(),
      firestore
          .collectionGroup("favorites")
          .where("rentalId", "==", rentalId)
          .get(),
      firestore
          .collection("chat_rooms")
          .where("itemId", "==", rentalId)
          .get(),
    ]);

  transactionSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
  favoriteSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
  chatRoomSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

  if (!transactionSnapshot.empty ||
      !favoriteSnapshot.empty ||
      !chatRoomSnapshot.empty) {
    await batch.commit();
  }

  const rtdbDeletes = {};
  chatRoomSnapshot.docs.forEach((doc) => {
    rtdbDeletes[`messages/${doc.id}`] = null;
    rtdbDeletes[`typing/${doc.id}`] = null;
  });

  if (Object.keys(rtdbDeletes).length > 0) {
    await admin.database().ref().update(rtdbDeletes);
  }

  logger.info("Rental cleanup completed", {
    rentalId,
    transactionsDeleted: transactionSnapshot.size,
    favoritesDeleted: favoriteSnapshot.size,
    chatRoomsDeleted: chatRoomSnapshot.size,
  });
} catch (error) {
  logger.error("onRentalDeleted failed", {rentalId, error});
}
}
);

exports.onChatMessageCreated = onValueCreated(
"/messages/{chatRoomId}/{messageId}",
async (event) => {
try {
const msgData = event.data.val();
if (!msgData) return;

  const {senderId, receiverId, text, messageType, imageUrl} = msgData;
  const chatRoomId = event.params.chatRoomId;

  if (!senderId || !receiverId) {
    return;
  }

  const isImageMessage =
    messageType === "image" ||
    (typeof imageUrl === "string" && imageUrl.trim() !== "");
  const notificationBody = isImageMessage ?
    "Sent an image" :
    (typeof text === "string" ? text.trim() : "");

  if (!notificationBody) {
    return;
  }

  const roomDoc = await admin.firestore()
      .collection("chat_rooms")
      .doc(chatRoomId)
      .get();

  if (!roomDoc.exists) {
    logger.warn("Chat room metadata not found", {chatRoomId});
    return;
  }

  const roomData = roomDoc.data() || {};
  const participants = Array.isArray(roomData.participants) ?
    roomData.participants.filter((value) => typeof value === "string") :
    [];

  if (
    !participants.includes(senderId) ||
    !participants.includes(receiverId) ||
    senderId === receiverId
  ) {
    logger.warn("Chat message participants did not match room metadata", {
      chatRoomId,
      senderId,
      receiverId,
    });
    return;
  }

  let senderName = "Someone";
  let senderImage = "";

  if (senderId === roomData.ownerId) {
    senderName = roomData.ownerName || "Item Owner";
    senderImage = roomData.ownerImage || "";
  } else if (senderId === roomData.renterId) {
    senderName = roomData.renterName || "Renter";
    senderImage = roomData.renterImage || "";
  }

  const payloadData = {
    type: "chat_message",
    chatRoomId: chatRoomId,
    senderId: senderId,
    receiverId: receiverId,
    otherUserId: senderId,
    otherUserName: senderName,
    otherUserImage: senderImage,
    itemTitle: roomData.itemTitle || "Item Inquiry",
    itemImage: roomData.itemImage || "",
    messageType: messageType || (isImageMessage ? "image" : "text"),
  };

  await sendPushToUser(
    receiverId,
    senderName,
    notificationBody,
    payloadData
  );
} catch (error) {
  logger.error("onChatMessageCreated failed", error);
}
}
);