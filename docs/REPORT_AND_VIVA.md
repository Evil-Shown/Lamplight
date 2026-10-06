# Milestone 03 report, viva, and originality rules

This file exists so later work (code, tests, and the final PDF) stays aligned with the **IT3060 Milestone 03** brief. The full brief is in [`hci_assignments_extracted/Milestone03_Assignment.md`](hci_assignments_extracted/Milestone03_Assignment.md).

**Deadline:** 09.10.2026  
**Weight:** 20% of the module (published component marks: 3 + 8 + 5 + 4).

---

## 1. AI and plagiarism (examiner rule)

The brief states:

> You can use AI tools, but you can’t put things the same as you take from the AI. In the report, we are going to check the percentage of the AI. It needs to be **less than 50%**.

Also: plagiarism, including source code that is not the group's own, is **zero marks**.

### How to stay under 50% AI similarity

- Use AI for **planning, checklists, architecture notes, and code assistance** in the repo — **not** as the voice of the PDF.
- **Rewrite** every report paragraph in the group's own words. Do not paste ChatGPT / Cursor output into the PDF.
- Prefer **evidence**: your screenshots, APK, GitHub commits, test tables, quotes from *your* usability sessions, and citations of Dix, Nielsen, WCAG, Firebase docs, Flutter docs.
- Keep Milestone 01/02 summaries **short and recast**, not a dump of the previous Word files or of `docs/*.md`.
- Architecture and stack justification must sound like **this group's constraints** (four people, two-week window, library booking, Google Auth, QR camera) — not a generic “Firebase is scalable” essay.
- Run the draft through the **institution's AI/plagiarism checker** before submit. If the score is high, cut generated prose and replace with original analysis.
- Do **not** invent usability numbers. Empty M02 Section 8 must be filled from **real** M03 sessions on the working app.

### What *is* allowed in the repository

Internal design docs (`docs/HIGH_LEVEL_ARCHITECTURE.md` etc.) may be AI-assisted working notes. They are **not** the submission PDF. The PDF must be a human-written consolidation.

---

## 2. Deliverable checklist

| Deliverable | Status to track |
|-------------|-----------------|
| Working, installable Android APK (and/or iOS if shown in viva) | Required |
| GitHub repo with README: clone, Flutter version, `pub get`, Firebase setup, `flutter run`, how to install APK | Required |
| Each member can demo **their** screens live | Required |
| ≥ 2 working CRUD ops **per member interface set** | Required |
| Functional test cases + results + **FR → prototype → code → test** matrix | Required |
| Usability test of the **app** (not Figma): **≥ 5** real/proxy users, recordings/consent | Required |
| Deviations from Figma documented with reasons | Required |
| One PDF ≤ 35 pages + unlimited appendix/references | Required |
| AI similarity **< 50%** | Required |

---

## 3. Suggested 35-page budget (adjust, do not copy verbatim)

| Section | Pages (approx.) | Source to rewrite from |
|---------|-----------------|------------------------|
| Cover | 1 | Group details + workload table |
| Executive summary | 1 | Original: problem → app → tests → outcome |
| M01 summary | 3–4 | `Assignment1_HCI.md` — compress; keep 119 respondents, FR/NFR list |
| M02 summary | 3–4 | `HCI_Assignment-2_WE_153_2.2.md` — sketches → wireframes → Figma; no fake test results |
| Tech stack justification | 2 | Map Flutter/Firebase to NFR02–07, camera QR, Google Auth, timeframe |
| Architecture | 2 | One context diagram + one Flutter layer diagram (redraw, do not screenshot AI mermaid only) |
| Implementation + screenshots | 6–8 | Real device/emulator shots; CRUD table per member |
| Traceability matrix | 2–3 | FR01–FR19 rows |
| Functional tests | 2–3 | Summary in body; full logs in appendix |
| Usability tests | 3–4 | Plan, 5 participants, metrics, issues — **real data only** |
| Issues and fixes | 1–2 | Severity log + what you shipped vs later |
| Gantt | 1 | 24 Jul–09 Oct style across three milestones |
| Conclusion | 1 | Lessons learned in first person plural |
| References | extra | Not in 35 |
| Appendix | extra | Tests, extra shots, Drive links, code excerpts |

---

## 4. Tech stack justification (points to argue in *your* words)

Do not paste the architecture docs. In the report, justify against **this** project:

| Choice | Why it fits IT3060 M03 |
|--------|------------------------|
| Flutter | One codebase, Material 3, already matches M02 screens, APK for viva |
| Dart / feature folders | Each member owns a feature directory |
| Firebase Auth + Google | NFR04; campus accounts; no fake password UI in the marked build |
| Cloud Firestore | CRUD for books, seats, reservations, waitlists, notifications |
| Cloud Functions | Conflict-safe reserve/cancel/check-in (NFR03) if time allows; else document a simpler transactional client+rules approach **and why** |
| FCM | FR16–FR18 reminders (or in-app only if FCM slips — **document deviation**) |
| `qr_flutter` + `mobile_scanner` | FR19 student pass + staff camera |
| GitHub | Required version control |

If the group ships **mock Firestore-less CRUD** (local persistence only), say so clearly, justify timeframe, and still show create/read/update/delete on real device.

---

## 5. CRUD mapping (minimum two ops per member)

Equivalent operations count as CRUD (reserve = create, list = read, cancel = delete, status/prefs = update).

| Member | Interface set | Example CRUD (must actually work) |
|--------|---------------|-----------------------------------|
| Kalutotage | Books | Create reservation; Read search/details; Update waitlist/status; Cancel hold |
| Yatawata (Damitha) | Seats / waitlist | Create seat booking; Read map/filters; Update filters/preferences; Leave waitlist / cancel seat — see [`workloads/DAMITHA_SEAT_BOOKING.md`](workloads/DAMITHA_SEAT_BOOKING.md) |
| Pathiranage | Reservations / notifications | Read lists; Update cancel/read-state; Delete/cancel reservation; Create notification on events |
| Wathudura | Auth / home / QR / staff | Create session (sign-in); Read profile/queue; Update check-in status; Staff verify / dismiss queue |

Confirm names on the **cover page** against the M02 ownership swap noted in `DECISIONS.md`.

---

## 6. Viva — what each person should be able to say

Without reading a script:

1. Which screens they built and where they live in `lib/features/…`.
2. One CRUD path they can perform live.
3. One place the app **differs** from Figma and why.
4. One functional test ID that traces to an FR they own.
5. One usability finding (once tests exist) and whether it was fixed.

Staff/QR camera, Google sign-in, and APK install should be rehearsed on a **physical phone** before the viva.

---

## 7. Fidelity and deviations (required table in the report)

Keep a living table while coding:

| Screen / flow | Figma | App | Deviation | Justification |
|---------------|-------|-----|-----------|----------------|
| Login | Email/password + staff entry | Google sign-in (planned) | Auth method | Security / M03 stack / NFR04 |
| Staff Home vs Staff tab | Two similar frames | Distinct Home vs Staff | Duplicate dashboard in current code | Usability / IA |
| Seat list toggle | Research wanted list + map | Map-first | Time; list still required for a11y if possible | Q9 vs scope |
| … | … | … | … | … |

Every unfixed gap (due dates, floor filter, seat cancel bug, stub scanner) either gets **fixed** or appears in this table.

---

## 8. Testing the working app (M03, not Figma)

Reuse Assignment 2 tasks **T1–T8** on the **installed APK**. Metrics stay: ≥ 80% success, SEQ ≥ 5.5, ≥ 5 participants, consent, recordings in appendix (Drive links).

Functional tests must include CRUD and core FRs. Put the **matrix** in the report body and raw logs in the appendix. See `TESTING_QA.md`.

---

## 9. File name and GitHub README (submission)

- PDF: `IT3060HCI2026_Milestone03_GroupWE_153_2.2.pdf` (confirm group token).
- README at repo root must include: Flutter SDK, Java/Android, `flutter pub get`, how to configure Firebase (or demo credentials), `flutter run`, `flutter build apk`, and known limitations.

Do not commit secrets (`.env`, service-account JSON, signing keystores).
