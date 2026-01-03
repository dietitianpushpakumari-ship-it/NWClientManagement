const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Admin SDK (For your Master Project)
admin.initializeApp();

/**
 * HTTPS Callable function to securely set a user"s role claim.
 * Requires the caller to already be an administrator.
 */
exports.setAdminClaim = functions
    .region("asia-south1")
    .https.onCall(async (data, context) => {
      if (!context.auth || context.auth.token.isAdmin !== true) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "You must be an administrator to perform this action.",
        );
      }

      const {targetUid, isAdmin} = data;

      if (!targetUid || typeof isAdmin !== "boolean") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing targetUid or invalid isAdmin value.",
        );
      }

      const claims = {isAdmin: isAdmin};

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

      try {
        const userRecord = await admin.auth().createUser({
          uid: clientId,
          email: clientEmail,
          password: initialPassword,
          emailVerified: true,
          disabled: false,
        });

        return {
          message: `Auth user created successfully for client: ${clientId}`,
          uid: userRecord.uid,
        };
      } catch (error) {
        console.error("Error creating Auth user:", error);
        if (error.code === "auth/email-already-exists") {
          throw new functions.https.HttpsError(
              "already-exists",
              `An Auth user already exists for email: ${clientEmail}`,
          );
        }
        throw new functions.https.HttpsError(
            "internal",
            "Failed to create client credentials on the server.",
        );
      }
    });

// ============================================================================
// 🎯 NEW FUNCTION: Create Clinic Admin (Pooled Database Architecture)
// Creates the user in Auth, sets Custom Claims, and updates user_directory.
// ============================================================================
exports.createClinicAdmin = functions
    .region("asia-south1")
    .https.onCall(async (data, context) => {
      const {email, password, tenantId, firstName, lastName} = data;

      try {
        // 1. Create the Auth User
        const userRecord = await admin.auth().createUser({
          email: email,
          password: password,
          displayName: `${firstName} ${lastName}`,
        });

        // 2. Set Custom Claims (The "Key" to the Tenant Data)
        await admin.auth().setCustomUserClaims(userRecord.uid, {
          tenantId: tenantId,
          role: "clinicAdmin",
        });

        // 3. Update User Directory (The "Map" for Login Routing)
        // We store "temp_password" here so the Super Admin can email it.
        await admin.firestore().collection("user_directory").doc(email).set({
          email: email,
          uid: userRecord.uid,
          tenantId: tenantId,
          role: "clinicAdmin",
          firstName: firstName,
          lastName: lastName,
          isEnabled: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          temp_password: password, // Stored for "Resend Invite" functionality
        });

        return {success: true, uid: userRecord.uid};
      } catch (error) {
        console.error("Error creating clinic admin:", error);

        // Handle specific Auth errors
        if (error.code === "auth/email-already-exists") {
          // Optional: If user exists, you could choose to link them to this
          // new tenant here, or just throw an error.
          throw new functions.https.HttpsError(
              "already-exists",
              "This email is already registered.",
          );
        }

        throw new functions.https.HttpsError("internal", error.message);
      }
    });
