/**
 * Dev helper (EMULATOR ONLY): grant the demo admin a `role` custom claim so that
 * BOTH the Firestore security rules (request.auth.token.role) AND the admin-portal
 * RoleGuard pass.
 *
 * Why this is needed: the portal's "Dev sign-in" button creates
 * admin@bluegrassgameday.dev with a RANDOM uid (so it won't match a seeded
 * users/{uid} doc), and custom claims can't be set from the browser. Run this once
 * after the emulator is up and after you've clicked Dev sign-in at least once:
 *
 *   npm run dev-claim                       # admin@bluegrassgameday.dev -> admin
 *   npm run dev-claim -- you@example.com editor
 *
 * Then REFRESH the admin app (or sign out + Dev sign-in) to pick up the new claim.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const projectId = process.env.GCLOUD_PROJECT ?? "bluegrass-gameday-dev";
if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error("Refusing to run: FIREBASE_AUTH_EMULATOR_HOST is not set (this helper is emulator-only).");
  process.exit(1);
}

const email = process.argv[2] ?? "admin@bluegrassgameday.dev";
const role = process.argv[3] ?? "admin";

(async () => {
  initializeApp({ projectId });
  const auth = getAuth();
  let user = await auth.getUserByEmail(email).catch(() => null);
  if (!user) {
    user = await auth.createUser({ email, password: "devpassword123" });
    console.log(`Created ${email} in the Auth emulator.`);
  }
  await auth.setCustomUserClaims(user.uid, { role });
  console.log(`✓ Granted role="${role}" to ${email} (uid ${user.uid}).`);
  console.log("Now REFRESH the admin app (or sign out + Dev sign-in) to pick up the claim.");
  process.exit(0);
})().catch((e) => {
  console.error("Failed:", e);
  process.exit(1);
});
