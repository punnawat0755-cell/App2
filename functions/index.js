const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const TOPIC_ALL_USERS = "all_users";

exports.sendToAllUsersTopic = onCall(
  {
    region: "asia-southeast1",
    timeoutSeconds: 30,
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const data = request.data || {};
    const title = typeof data.title === "string" ? data.title.trim() : "";
    const body = typeof data.body === "string" ? data.body.trim() : "";

    if (!title || !body) {
      throw new HttpsError(
        "invalid-argument",
        "Both title and body are required."
      );
    }

    const payload = {
      notification: {
        title,
        body,
      },
      data: {
        title,
        body,
        sentBy: request.auth.uid,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      topic: TOPIC_ALL_USERS,
      android: {
        priority: "high",
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const messageId = await admin.messaging().send(payload);
    logger.info("Sent topic message", {
      topic: TOPIC_ALL_USERS,
      messageId,
      fromUid: request.auth.uid,
    });

    return {
      ok: true,
      topic: TOPIC_ALL_USERS,
      messageId,
    };
  }
);
