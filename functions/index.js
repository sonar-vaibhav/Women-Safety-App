const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Send panic alert notifications to emergency contacts
exports.sendPanicAlert = functions.firestore
    .document("users/{userId}/alerts/{alertId}")
    .onCreate(async (snap, context) => {
      const alert = snap.data();
      const userId = context.params.userId;

      // Only send for panic alerts
      if (alert.type !== "panic") {
        return null;
      }

      try {
        // Get user info (for sender's name)
        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();
        const userData = userDoc.data() || {};
        const userName = userData.fullName || "Unknown User";

        // Get emergency contacts' FCM tokens
        const alertedContacts = alert.alerted_contacts || [];

        if (alertedContacts.length === 0) {
          console.log("No alerted contacts to notify");
          return null;
        }

        // Collect FCM tokens from all alerted contacts
        const fcmTokens = [];
        for (const contact of alertedContacts) {
          try {
            const contactNumber = contact.alerted_contact_number;

            if (!contactNumber) {
              console.log("No contact number found in alert");
              continue;
            }

            const contactSnapshot = await admin
                .firestore()
                .collection("users")
                .where("phoneNumber", "==", contactNumber)
                .get();

            if (!contactSnapshot.empty) {
              const contactData = contactSnapshot.docs[0].data();
              const tokens = contactData.fcmTokens || [];
              // eslint-disable-next-line max-len
              console.log(`Found ${tokens.length} FCM tokens for ${contactNumber}`);
              fcmTokens.push(...tokens);
            } else {
              // eslint-disable-next-line max-len
              console.log(`No user found with phoneNumber: ${contactNumber}`);
            }
          } catch (error) {
            console.log(`Error fetching tokens for contact: ${error}`);
          }
        }

        if (fcmTokens.length === 0) {
          console.log("No FCM tokens found for contacts");
          return null;
        }

        // Create notification payload
        const messages = fcmTokens.map((token) => ({
          token: token,
          notification: {
            title: "🚨 PANIC ALERT!",
            body: `${userName} triggered panic alert! Tap to view location.`,
          },
          data: {
            alertId: context.params.alertId,
            userId: userId,
            userName: userName,
            alertType: "panic",
            safetyCode: alert.safety_code || "",
          },
          android: {
            priority: "high",
            notification: {
              "sound": "default",
              "clickAction": "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: {
              aps: {
                "sound": "default",
                "mutable-content": true,
              },
            },
          },
        }));

        // Send notifications in batches
        const result = await admin.messaging().sendMulticast(messages);

        console.log(`Successfully sent ${result.successCount} panic alerts`);
        if (result.failureCount > 0) {
          console.log(`Failed to send ${result.failureCount} panic alerts`);
        }

        return {
          success: true,
          sent: result.successCount,
          failed: result.failureCount,
        };
      } catch (error) {
        console.error("Error sending panic alert:", error);
        return null;
      }
    });

// Send Track Me notifications to emergency contacts
exports.sendTrackMeAlert = functions.firestore
    .document("users/{userId}/alerts/{alertId}")
    .onCreate(async (snap, context) => {
      const alert = snap.data();
      const userId = context.params.userId;

      // Only send for track me alerts
      if (alert.type !== "trackMe") {
        return null;
      }

      try {
        // Get user info
        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();
        const userData = userDoc.data() || {};
        const userName = userData.fullName || "Unknown User";

        // Get alerted contacts
        const alertedContacts = alert.alerted_contacts || [];

        if (alertedContacts.length === 0) {
          console.log("No alerted contacts for Track Me");
          return null;
        }

        // Collect FCM tokens
        const fcmTokens = [];
        for (const contact of alertedContacts) {
          try {
            const contactNumber = contact.contact_number ||
                contact.alerted_contact_number;

            if (!contactNumber) {
              console.log("No contact number found in alert");
              continue;
            }

            const contactSnapshot = await admin
                .firestore()
                .collection("users")
                .where("phoneNumber", "==", contactNumber)
                .get();

            if (!contactSnapshot.empty) {
              const contactData = contactSnapshot.docs[0].data();
              const tokens = contactData.fcmTokens || [];
              // eslint-disable-next-line max-len
              console.log(`Found ${tokens.length} FCM tokens for ${contactNumber}`);
              fcmTokens.push(...tokens);
            } else {
              // eslint-disable-next-line max-len
              console.log(`No user found with phoneNumber: ${contactNumber}`);
            }
          } catch (error) {
            // eslint-disable-next-line max-len
            console.log(`Error fetching tokens for Track Me contact: ${error}`);
          }
        }

        if (fcmTokens.length === 0) {
          console.log("No FCM tokens found for Track Me contacts");
          console.log("Alerted contacts:", JSON.stringify(alertedContacts));
          return null;
        }

        // Create Track Me notification payload
        const trackMeLimit = alert.track_me_limit || "1";
        let duration = "1 hour";
        if (trackMeLimit === "8") duration = "8 hours";
        if (trackMeLimit === "always") duration = "unlimited";

        const messages = fcmTokens.map((token) => ({
          token: token,
          notification: {
            title: "📍 Location Sharing Started",
            body: `${userName} sharing location for ${duration}. Tap to view.`,
          },
          data: {
            alertId: context.params.alertId,
            userId: userId,
            userName: userName,
            alertType: "trackMe",
            duration: duration,
          },
          android: {
            priority: "high",
            notification: {
              "sound": "default",
              "clickAction": "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: {
              aps: {
                "sound": "default",
                "mutable-content": true,
              },
            },
          },
        }));

        // Send notifications
        const result = await admin.messaging().sendMulticast(messages);

        console.log(`Successfully sent ${result.successCount} Track Me alerts`);
        if (result.failureCount > 0) {
          console.log(`Failed to send ${result.failureCount} Track Me alerts`);
        }

        return {
          success: true,
          sent: result.successCount,
          failed: result.failureCount,
        };
      } catch (error) {
        console.error("Error sending Track Me alert:", error);
        return null;
      }
    });
