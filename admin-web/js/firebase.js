// Firebase init + emulator wiring. One exact SDK version everywhere.
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import * as authMod from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import * as fsMod from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";
import * as fnMod from "https://www.gstatic.com/firebasejs/10.14.1/firebase-functions.js";
import { firebaseConfig } from "./firebase-config.js";

export const app = initializeApp(firebaseConfig);
export const auth = authMod.getAuth(app);
export const db = fsMod.getFirestore(app);
// Functions are deployed to the default region (us-central1) - see functions/src/config.ts.
export const functions = fnMod.getFunctions(app);

const isLocal = ["localhost", "127.0.0.1"].includes(location.hostname);
export const usingEmulator = isLocal && new URLSearchParams(location.search).get("emulator") === "1";
if (usingEmulator) {
  authMod.connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  fsMod.connectFirestoreEmulator(db, "127.0.0.1", 8080);
  fnMod.connectFunctionsEmulator(functions, "127.0.0.1", 5001);
}

export const A = authMod;
export const F = fsMod;
export const call = (name, data) => fnMod.httpsCallable(functions, name)(data ?? {}).then((r) => r.data);
