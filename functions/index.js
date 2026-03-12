const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onValueCreated} = require("firebase-functions/v2/database");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

async function sendPushToUser(uid, title, body, data = {}) {
  if (!uid) {
    logger.warn("Missing uid for push send");
    return;
  }

  const userDoc = await admin.firestore().collection("users").doc(uid).get();

  if (!userDoc.exists) {
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
    const {token, title, body} = req.body;

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

    logger.info("Push notification sent successfully", {response});

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

// --- NEW: Chat Message Push Notification Trigger ---
exports.onChatMessageCreated = onValueCreated(
  "/messages/{chatRoomId}/{messageId}",
  async (event) => {
    try {
      const msgData = event.data.val();
      if (!msgData) return;

      const { senderId, receiverId, text, messageType, imageUrl } = msgData;
      const chatRoomId = event.params.chatRoomId;

      if (!senderId || !receiverId) {
        return;
      }

      const isImageMessage =
        messageType === "image" ||
        (typeof imageUrl === "string" && imageUrl.trim() !== "");
      const notificationBody = isImageMessage ?
        "📷 Sent an image" :
        (typeof text === "string" ? text.trim() : "");

      if (!notificationBody) {
        return;
      }

      // Fetch chat room metadata from Firestore
      const roomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
      
      if (!roomDoc.exists) {
        logger.warn("Chat room metadata not found", { chatRoomId });
        return;
      }

      const roomData = roomDoc.data();

      // Determine sender identity to populate the "other user" fields for the receiver
      let senderName = "Someone";
      let senderImage = "";

      if (senderId === roomData.ownerId) {
        senderName = roomData.ownerName || "Item Owner";
        senderImage = roomData.ownerImage || "";
      } else if (senderId === roomData.renterId) {
        senderName = roomData.renterName || "Renter";
        senderImage = roomData.renterImage || "";
      }

      // Build payload
      const payloadData = {
        type: "chat_message",
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        otherUserId: senderId, // To the receiver, the sender is the "other user"
        otherUserName: senderName,
        otherUserImage: senderImage,
        itemTitle: roomData.itemTitle || "Item Inquiry",
        itemImage: roomData.itemImage || "",
        messageType: messageType || (isImageMessage ? "image" : "text"),
      };

      // Send the push notification to the receiver
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
