const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

const TOPIC_ALL_USERS = "all_users";
const N8N_MODERATION_WEBHOOK = defineSecret("N8N_MODERATION_WEBHOOK");

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

exports.moderateMessage = onCall(
  {
    region: "asia-southeast1",
    timeoutSeconds: 15,
    cors: true,
    secrets: [N8N_MODERATION_WEBHOOK],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const data = request.data || {};
    const text = typeof data.message === "string" ? data.message.trim() : "";
    const chatId = typeof data.chatId === "string" ? data.chatId.trim() : "";
    const receiverId =
      typeof data.receiverId === "string" ? data.receiverId.trim() : "";

    if (!text) {
      return {
        allowed: true,
        status: "allow",
        cleanMessage: "",
        isProfane: false,
        reason: "empty-message",
      };
    }

    const webhook = N8N_MODERATION_WEBHOOK.value();
    if (!webhook) {
      logger.error("N8N_MODERATION_WEBHOOK is missing");
      return {
        allowed: true,
        status: "allow",
        cleanMessage: text,
        isProfane: false,
        reason: "webhook-missing",
      };
    }

    try {
      const response = await fetch(webhook, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "content_moderate",
          chatId,
          senderId: request.auth.uid,
          receiverId,
          message: text,
          text,
          timestamp: new Date().toISOString(),
        }),
      });

      let payload = {};
      try {
        payload = await response.json();
      } catch (_) {
        payload = {};
      }

      const status = String(payload.status || "")
        .toLowerCase()
        .trim();
      const allowedRaw = payload.allowed;
      const cleanMessage = String(
        payload.cleanMessage || payload.message || text
      ).trim();
      const isProfane =
        payload.isProfane === true ||
        status === "block" ||
        status === "blocked" ||
        status === "reject";

      let allowed = true;
      if (typeof allowedRaw === "boolean") {
        allowed = allowedRaw;
      } else if (isProfane) {
        allowed = false;
      } else if (status) {
        allowed = ["allow", "allowed", "ok", "mask"].includes(status);
      }

      return {
        allowed,
        status: allowed ? "allow" : "block",
        cleanMessage,
        isProfane: !allowed,
        reason: String(payload.reason || ""),
      };
    } catch (error) {
      logger.error("moderateMessage failed", error);
      return {
        allowed: true,
        status: "allow",
        cleanMessage: text,
        isProfane: false,
        reason: "fallback-allow",
      };
    }
  }
);
