import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { adminAuth, db } from "./admin";
import { releaseReservationCopy } from "./reservations";
import { freeSeatForBooking } from "./seats";
import { logError, logInfo, requireAuth, toJson } from "./util";
import { releaseResource } from "./waitlist";

const SUBCOLLECTIONS = ["reservations", "bookings", "waitlist", "notifications"] as const;

/** exportAccountData -> { exportedAt, profile, reservations, bookings, waitlist, loans, notifications, strikes } */
export const exportAccountData = onCall(async (request) => {
  const uid = requireAuth(request);
  try {
    const userRef = db.collection("users").doc(uid);
    const [profile, loans, strikes, ...subs] = await Promise.all([
      userRef.get(),
      db.collection("loans").where("userId", "==", uid).get(),
      userRef.collection("strikes").get(),
      ...SUBCOLLECTIONS.map((c) => userRef.collection(c).get()),
    ]);
    const list = (docs: FirebaseFirestore.QueryDocumentSnapshot[]): unknown[] =>
      docs.map((d) => ({ id: d.id, ...(toJson(d.data()) as object) }));
    const out: Record<string, unknown> = {
      exportedAt: new Date().toISOString(),
      uid,
      profile: toJson(profile.data() ?? null),
      loans: list(loans.docs),
      strikes: list(strikes.docs),
    };
    SUBCOLLECTIONS.forEach((c, i) => {
      out[c] = list(subs[i]!.docs);
    });
    return out;
  } catch (err) {
    logError("exportAccountData", err, { uid });
    throw new HttpsError("internal", "Export failed.");
  }
});

/**
 * deleteAccountData: releases held seats/copies, deletes the user's profile and
 * every subcollection, their returned loans, then the Auth user. Refuses while
 * the user still has books on loan. The client must sign out afterwards.
 */
export const deleteAccountData = onCall(async (request) => {
  const uid = requireAuth(request);
  try {
    const userRef = db.collection("users").doc(uid);
    const loans = await db.collection("loans").where("userId", "==", uid).get();
    if (loans.docs.some((l) => l.get("status") !== "returned")) {
      throw new HttpsError("failed-precondition", "Return all borrowed books before deleting your account.");
    }

    // Give back anything the account is holding so nobody is blocked by a ghost.
    const bookings = await userRef.collection("bookings").get();
    for (const b of bookings.docs) {
      if (["ready", "active", "expiringSoon"].includes(String(b.get("status")))) {
        await freeSeatForBooking(uid, b.id, String(b.get("seatId")));
      }
    }
    const reservations = await userRef.collection("reservations").get();
    for (const r of reservations.docs) {
      if (["ready", "active", "expiringSoon"].includes(String(r.get("status")))) {
        await r.ref.update({ status: "cancelled", cancelledAt: FieldValue.serverTimestamp() });
        await releaseReservationCopy(r.ref);
      }
    }
    const offers = await userRef.collection("waitlist").where("status", "==", "offered").get();
    for (const o of offers.docs) {
      await o.ref.update({ status: "declined" });
      await releaseResource(o.get("type"), String(o.get("resourceId")));
    }

    await Promise.all(loans.docs.map((l) => l.ref.delete()));
    await db.recursiveDelete(userRef);
    try {
      await adminAuth.deleteUser(uid);
    } catch (err) {
      if ((err as { code?: string }).code !== "auth/user-not-found") throw err;
    }
    logInfo("deleteAccountData.done", { uid });
    return { deleted: true };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logError("deleteAccountData", err, { uid });
    throw new HttpsError("internal", "Account deletion failed.");
  }
});
