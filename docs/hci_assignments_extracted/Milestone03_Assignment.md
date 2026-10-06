# Source: IT3060 Milestone 03 assignment brief (text provided 2026-10-07)

Sri Lanka Institute of Information Technology

BSc (Hons) in Information Technology

**Module:** IT3060 — Human Computer Interaction  
**Year / Semester:** Year 3 Semester 2, 2026  
**Milestone:** 03  
**Assignment title:** Mobile App Implementation & Final Evaluation  

| Field | Value |
|--------|--------|
| Learning outcomes | LO4, LO5, LO6 |
| Assignment mode | Take-home assignment |
| Maximum marks | 100 |
| Contribution to final grade | 20% |
| Date published | 28.09.2026 |
| Deadline for submissions | **09.10.2026** |
| Mode of submission | Online |
| Group | Continue the same group of 4 (WE_153_2.2) |

---

## 1. Aim

Implement a **working mobile application** based on the high-fidelity prototype developed in Milestone 02, using a **justifiable technology stack**, and **validate it through user testing**.

The app must be a working, **installable/runnable** mobile application — **not** a clickable prototype.

---

## 1.1 Objectives

a. Review the high-fidelity prototype and its traceability to the user requirements established in Milestone 01.

b. Select a mobile technology stack (e.g. frontend framework, backend/API, database, authentication) and **justify each choice** against the project's requirements and constraints.

c. Implement the mobile app, covering **each member's assigned workload of interfaces** from Milestone 01 / 02.

d. Ensure the implemented interfaces **match the high-fidelity prototype** in structure and intent, **documenting and justifying any necessary deviations**.

e. Design and execute **functional test cases** covering the core features and **CRUD operations** of the app.

f. Design and conduct **usability testing** on the **working app** with a representative sample of real or proxy users.

g. Analyse the testing results, document defects/usability issues found, and record **fixes or planned improvements**.

h. Compile a **single consolidated report** covering Milestones 01, 02, and 03.

---

## 1.2 Things to concern

- The app must be a working, installable/runnable mobile application — not a clickable prototype.
- Each member must implement the interfaces from **their own workload**, with **at least 2 working CRUD operations per interface** (consistent with Milestone 01's project requirement).
- Any deviation between the implemented app and the high-fidelity prototype must be **explicitly documented and justified** in the report.
- Functional test cases must cover **all core features**; a **traceability matrix** linking test cases to user requirements is required.
- A **minimum of 5 participants** (real or proxy users) must take part in usability testing of the **working app**.
- Source code must be submitted via a **version-controlled repository** (e.g. GitHub) with a **clear README** containing setup and run instructions.
- **Plagiarism is not tolerated**; zero marks if the examiner discovers that the work presented, including source code, is not the group's own.
- **AI tools may be used**, but the report **must not paste AI text unchanged**. The examiner will check the **AI percentage**; it **must be less than 50%**. Rewrite in the group's own words, cite sources, and keep implementation evidence (screenshots, tests, recordings) original.

---

## 1.3 Special requirements

Continue working in the **same group of 4 members**. The technology stack is **open to the group's choice** but **must be justified** in the report. The coordinator may request a change if the choice is not feasible within the project timeframe.

---

## 1.4 Deliverables

1. A **single consolidated group report** covering all three milestones (template in Section 1.5 / 6.10 of the brief).
2. **Complete, working source code** (repository link) with instructions on how to **build/run** the app, plus an **installable build (e.g. APK)** where applicable.
3. A **live demonstration / viva** where **each member must individually** demonstrate and explain:
   - the interfaces they implemented
   - the tech-stack decisions
   - the testing results

---

## 1.5 Report template

- **Maximum 35 pages** including the cover page (consolidated across all milestones).
- **PDF file name:** `IT3060HCI2026_Milestone03_Group<group number>`  
  For this group: `IT3060HCI2026_Milestone03_GroupWE_153_2.2` (confirm exact group-number format with the brief if the coordinator uses a numeric code).
- **Cover page content:**
  - IT3060 Human Computer Interaction
  - Milestones 01–03 (Final Report)
  - Project title
  - Group number
  - Group name
  - Group member details: student ID, name, **workload distribution**

**Body of the report (required sections):**

1. Executive summary of the overall project
2. Milestone 01 summary — problem, stakeholders, user research, and elucidated requirements
3. Milestone 02 summary — sketches, wireframes, low- and high-fidelity prototypes
4. Tech stack selection and justification
5. System / app architecture overview
6. Implementation details and screenshots of the working app
7. Traceability matrix (requirements → prototype → implementation → test cases)
8. Functional test cases and results
9. Usability testing plan, execution, and results
10. Issues identified and fixes / recommendations
11. Overall time schedule (Gantt chart)
12. Conclusion and lessons learned

- **References** — not counted in the page limit.
- **Appendix** — not counted in the page limit. Include full test-case logs, additional screenshots, session recordings/links, source-code excerpts, etc.

**NOTE:** Max page number excludes the appendix. Diagrams, descriptions, and raw-data extracts may go there.

---

## 2. Marking scheme (20% of module / 20 marks as published)

The brief table lists component marks that total **20** (contribution to final grade). Treat these as the examiner's weightings:

| Component | Description | Marks |
|-----------|-------------|-------|
| Tech stack selection & justification | Appropriateness of chosen frontend / backend / database technologies for a mobile app, with clear justification against project needs | **3** |
| Implementation & fidelity | Functional completeness of the implemented app, correctness of CRUD operations, and fidelity to the Milestone 02 high-fidelity prototype and Milestone 01 requirements | **8** |
| Testing (functional & usability) | Coverage and quality of functional test cases, execution of usability testing with real/proxy users, and evidence of issues found and addressed | **5** |
| Consolidated report & demonstration / viva | Quality and coherence of the final report covering all milestones, and ability to demonstrate the working app and defend implementation decisions during the viva | **4** |
| **Total** | | **20** |

(The header also states “Maximum Marks 100”. Use the **20-mark weighting** for how the assignment contributes to the final grade; keep a 100-point internal breakdown only if the lecturer's full rubric uses that scale.)

---

## 3. Group workload (from Milestone 02 — must match viva ownership)

| Reg. No | Name | Interfaces / CRUD ownership |
|---------|------|-----------------------------|
| IT23628854 | Yatawata Y.A.D.W.D.B.S | Seat map, filters, seat details, seat success, waiting list; Figma integration |
| IT23612228 | Kalutotage S Y | Book search, results, book details, book reservation flow |
| IT23607446 | Pathiranage S.S. | My Reservations, cancellation, notification screens *(confirm vs M02 header/wireframe swap before the cover page)* |
| IT23617100 | Wathudura L K | Login, register, home, QR check-in, staff flow |

Each owner needs **at least two working CRUD operations** on their interfaces (create / read / update / delete or equivalent: reserve, list, cancel, update status, join/leave waitlist, verify, etc.).

---

## 4. What this means for the current Flutter app

The existing app is a **high-fidelity UI prototype with in-memory mock state**. Milestone 03 requires it to become a **working, installable** app with:

- Justified stack (Flutter + Firebase Auth/Firestore/Functions is already planned in `docs/`).
- Real CRUD against a backend, not only local `AppState`.
- Prototype fidelity + documented deviations.
- Functional tests mapped to FR01–FR19.
- Usability tests on the **running app** with **≥ 5 participants** (do not invent results).
- GitHub README with setup/run steps and an **APK**.
- One **≤ 35-page** consolidated PDF, written in the **group's own words** (AI similarity **< 50%**).

See `docs/REPORT_AND_VIVA.md` for report drafting rules and the originality constraint.
