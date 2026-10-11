import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export function logError(fn: string, err: unknown, ctx: Record<string, unknown> = {}): void {
  const e = err instanceof Error ? err : new Error(String(err));
  logger.error(`${fn} failed`, { fn, message: e.message, stack: e.stack, ...ctx });
}

export function logInfo(fn: string, ctx: Record<string, unknown> = {}): void {
  logger.info(fn, { fn, ...ctx });
}

export function requireAuth(req: CallableRequest<unknown>): string {
  if (!req.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  return req.auth.uid;
}

export function requireStaff(req: CallableRequest<unknown>): string {
  const uid = requireAuth(req);
  const role = req.auth?.token["role"];
  if (role !== "staff" && role !== "admin") {
    throw new HttpsError("permission-denied", "Staff only.");
  }
  return uid;
}

export function requireAdmin(req: CallableRequest<unknown>): string {
  const uid = requireAuth(req);
  if (req.auth?.token["role"] !== "admin") {
    throw new HttpsError("permission-denied", "Admin only.");
  }
  return uid;
}

export type Role = "admin" | "staff" | "student";

function listHas(list: unknown, email: string): boolean {
  return Array.isArray(list) && list.some((e) => typeof e === "string" && e.trim().toLowerCase() === email);
}

/** Role precedence: admin > staff > student. An empty email is always a student. */
export function pickRole(email: string, staffEmails: unknown, adminEmails: unknown): Role {
  const e = email.trim().toLowerCase();
  if (!e) return "student";
  if (listHas(adminEmails, e)) return "admin";
  if (listHas(staffEmails, e)) return "staff";
  return "student";
}

export function asObject(data: unknown): Record<string, unknown> {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    throw new HttpsError("invalid-argument", "Request body must be an object.");
  }
  return data as Record<string, unknown>;
}

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

export function idField(o: Record<string, unknown>, name: string): string {
  const v = o[name];
  if (typeof v !== "string" || !ID_RE.test(v)) {
    throw new HttpsError("invalid-argument", `${name} must be a valid id.`);
  }
  return v;
}

export function boolField(o: Record<string, unknown>, name: string): boolean {
  const v = o[name];
  if (typeof v !== "boolean") throw new HttpsError("invalid-argument", `${name} must be a boolean.`);
  return v;
}

/** Converts Timestamps (and nested ones) to ISO strings for JSON responses. */
export function toJson(value: unknown): unknown {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.map(toJson);
  if (typeof value === "object") {
    const v = value as { toDate?: () => Date };
    if (typeof v.toDate === "function") return v.toDate().toISOString();
    const out: Record<string, unknown> = {};
    for (const [k, x] of Object.entries(value as Record<string, unknown>)) out[k] = toJson(x);
    return out;
  }
  return value;
}

export function availabilityFor(copies: number, previous: unknown): string {
  if (copies > 0) return "available";
  return previous === "waitlisted" ? "waitlisted" : "onLoan";
}
