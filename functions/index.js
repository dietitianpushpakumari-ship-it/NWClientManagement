const functions = require("firebase-functions");
const admin = require("firebase-admin");

// 🎯 NEW IMPORTS: For connecting to Client/Tenant Projects dynamically
// We use the Web SDK because it allows API Key connections
const {initializeApp, deleteApp} = require("firebase/app");
const {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword, // <--- ADD THIS
} = require("firebase/auth");
const {getFirestore, doc, setDoc, serverTimestamp} =
require("firebase/firestore");

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
// 🎯 NEW FUNCTION: Cross-Project Provisioning
// Uses Web SDK to create admins in ANY Firebase project given an API Key
// ============================================================================
// ... existing imports ...

// 🚀 Function B: PROVISION ADMIN (Smart Retry Version)
exports.provisionTenantAdmin = functions
    .region("asia-south1")
    .runWith({
      timeoutSeconds: 300,
      memory: "1GB",
    })
    .https.onCall(async (data, context) => {
      const {config, email, password, profile} = data;
      let targetApp;

      try {
        const appName = `provision_${config.projectId}_${Date.now()}`;

        targetApp = initializeApp({
          apiKey: config.apiKey,
          authDomain: config.authDomain,
          projectId: config.projectId,
          storageBucket: config.storageBucket,
          messagingSenderId: config.messagingSenderId,
          appId: config.appId,
        }, appName);

        const targetAuth = getAuth(targetApp);
        const targetDb = getFirestore(targetApp);

        let uid;

        // 1. Try to CREATE the user
        try {
          const userCredential =
          await createUserWithEmailAndPassword(targetAuth, email, password);
          uid = userCredential.user.uid;
          console.log("✅ User created successfully.");
        } catch (createError) {
          // 2. If user exists, try to LOGIN (Retry Scenario)
          if (createError.code === "auth/email-already-in-use") {
            console.log("⚠️ User exists. Attempting to recover via login...");
            try {
              const loginCredential =
              await signInWithEmailAndPassword(targetAuth, email, password);
              uid = loginCredential.user.uid;
              console.log("✅ Recovered UID via login.");
            } catch (loginError) {
              // Password mismatch or other issue
              throw new functions.https.HttpsError("already-exists",
                  `The user ${email} already exists in the target project
                  with a DIFFERENT password. Please delete this user in the
                  Client's Firebase Console manually to retry.`);
            }
          } else {
            // Some other error (e.g. weak password)
            throw createError;
          }
        }

        // 3. Create/Update Admin Profile (Merge to be safe)
        await setDoc(doc(targetDb, "admins", uid), {
          email: email,
          role: "clinicAdmin",
          permissions: ["manage_staff", "manage_clinic",
            "view_financials", "onboard_client"],
          firstName: profile.firstName || "Admin",
          lastName: profile.lastName || "",
          mobile: profile.mobile,
          companyName: profile.companyName,
          isFirstLogin: true,
          isActive: true,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(), // Track updates
        }, {merge: true}); // Merge prevents overwriting unrelated fields
        return {success: true, uid: uid};
      } catch (error) {
        console.error("Provisioning Error:", error);
        throw new functions.https.HttpsError("internal", error.message);
      } finally {
        if (targetApp) await deleteApp(targetApp);
      }
    });
// ... existing imports ...

exports.verifyTenantConnection = functions
    .region("asia-south1")
    .https.onCall(async (data, context) => {
      const config = data.config;
      let targetApp;

      try {
        // 1. Unique App Name for this check
        const appName = `verify_${Date.now()}`;

        // 2. Initialize using the provided keys (Web SDK mode)
        targetApp = initializeApp({
          apiKey: config.apiKey,
          projectId: config.projectId,
          authDomain: config.authDomain,
          appId: config.appId, // Web App ID is sufficient here
        }, appName);

        const targetAuth = getAuth(targetApp);

        // 3. Perform a Dummy Operation to test connectivity
        // We try to sign in with a fake user.
        // If keys are VALID, Firebase returns 'auth/user-not-found'.
        // If keys are INVALID, it returns 'auth/invalid-api-key' or similar.
        try {
          await createUserWithEmailAndPassword(targetAuth,
              "test_connection_check@test.com", "test_pass_123");
        } catch (authError) {
          // If we get 'email-already-in-use', the connection worked!
          // If we get 'user-not-found' (from sign in), connection worked!
          // We mainly want to catch configuration errors.
          if (authError.code === "auth/invalid-api-key" ||
              authError.code === "auth/project-not-found" ||
              authError.code === "auth/app-not-authorized") {
            throw new Error("Invalid Configuration: " + authError.code);
          }
        }
        return {success: true, message: "Connection Verified"};
      } catch (error) {
        console.error("Verification Failed:", error);
        throw new functions.https.HttpsError("invalid-argument",
            "Connection Failed: " + error.message);
      } finally {
        if (targetApp) {
          await deleteApp(targetApp);
        }
      }
    });


