// Import the necessary modules
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Admin SDK
admin.initializeApp();

/**
 * HTTPS Callable function to securely set a user"s role claim.
 * Requires the caller to already be an administrator.
 */
exports.setAdminClaim = functions
    .region("asia-south1")
    .https.onCall(async (data, context) => {
      // --- STEP 1: Authorization Check ---
      // Deny access if not authenticated or if the caller is not an adminÒ
      if (!context.auth || context.auth.token.isAdmin !== true) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "You must be an administrator to perform this action.",
        );
      }

      // Get the target UID and boolean flag from the request
      const {targetUid, isAdmin} = data;

      if (!targetUid || typeof isAdmin !== "boolean") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing targetUid or invalid isAdmin value.",
        );
      }

      // Determine the claims object
      const claims = {isAdmin: isAdmin};

      // --- STEP 2: Set the Custom Claim ---
      try {
        await admin.auth().setCustomUserClaims(targetUid, claims);

        return {
          message: `Custom claim set successfully for user ${targetUid}`,
          status: "success",
        };
      } catch (error) {
        console.error("Error setting custom claim:", error);
        throw new functions.https.HttpsError(
            "internal",
            "An error occurred while setting the custom claim.",
        );
      }
    });
exports.createClientCredentials = functions
    .region("asia-south1")
    .https.onCall(async (data, context) => {
      // --- STEP 1: Authorization Check ---
      // Only allow administrators to create client accout
      if (!context.auth || context.auth.token.isAdmin !== true) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "You must be an administrator to create client credentials.",
        );
      }

      const {clientId, clientEmail, initialPassword} = data;

      if (!clientId || !clientEmail || !initialPassword) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required client ID, email, or password.",
        );
      }

      // --- STEP 2: Create the Firebase Auth User ---
      try {
        const userRecord = await admin.auth().createUser({
          uid: clientId, // Use Firestore ID as the Auth UID
          email: clientEmail,
          password: initialPassword,
          emailVerified: true, // Optional, set to true if admin verifies it
          disabled: false,
        });

        return {
          message: "Auth user created successfully for client: ${clientId}",
          uid: userRecord.uid,
        };
      } catch (error) {
        console.error("Error creating Auth user:", error);

        // Check for common errors like 'email-already-exists'
        if (error.code === "auth/email-already-exists") {
          throw new functions.https.HttpsError(
              "already-exists",
              "An Auth user already exists for email: ${clientEmail}",
          );
        }

        throw new functions.https.HttpsError(
            "internal",
            "Failed to create client credentials on the server.",
        );
      }
    });

