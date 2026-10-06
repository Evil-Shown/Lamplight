# Source: HCI_Assignment-2_WE_153_2.2.docx

Sri Lanka Institute of Information Technology

IT3060 – Human Computer Interaction

Milestone 02 – Assignment 2

High-Fidelity Prototyping & User Testing

Project Title: Library Book Reservation and Reading Room Seat Booking System

Group Number: WE_153_2.2

--- TABLE ---
Reg. No | Name | Workload distribution
IT23628854 | Yatawata  Y.A.D.W.D. B.S | Reading-room seat booking flow (seat map, filters, seat details, seat success, waiting list) and integration of the full Figma prototype
IT23612228 | Kalutotage  S Y | Book search, results, book details and book reservation flow
IT23607446 | Pathiranage  S.S. | My Reservations, cancellation and notification screens
IT23617100 | Wathudura  L K | Login, register, home, QR check-in and staff flow

1. Project overview and prototyping tool

This report documents how our Library Book Reservation and Reading Room Seat Booking System moved from the Milestone 01 research into a tested, high-fidelity interactive prototype. The design progressed through four stages – sketches, wireframes, a low-fidelity clickable prototype and a high-fidelity prototype – and each stage is evidenced in Sections 3 to 6.

The system has two audiences. Students and faculty use it to find and reserve books, find and book reading-room seats, join waiting lists, receive reminders and check in by QR code. Library staff use a smaller set of screens to verify reservations and manage no-shows. In Milestone 01, 57.3% of our 119 respondents said they had failed to find a book they wanted, and 60.7% said they sometimes, often or always cannot find a seat, so the design goal throughout is to reduce the effort of finding and securing a resource.

1.1 Why we chose Figma

The brief asks us to justify our prototyping tool. We compared three options against the needs of a four-person team working in parallel:

--- TABLE ---
Criterion | Figma | Adobe XD | Paper prototype
Real-time teamwork | All four members edit one file at the same time | Co-editing exists but the product is in maintenance mode | Cannot be shared remotely
Interactivity | Overlays, smart  animate , variables, Present mode | Basic transitions | Manual, facilitator-driven
Reusable components | Components and variants keep 4 members consistent | Component states, fewer options | None
Testing and recording | Runs in a browser, so remote test sessions can be screen-recorded | Needs the desktop app | Hard to record
Cost | Free education plan | No new  licences | Free

Figma was selected because a shared component library let four people design different screens without the visual language drifting, and because participants can run the prototype in a browser link during recorded sessions.

--- TABLE ---
How to open the prototype Figma link:   Figma Link   Open the link, go to the   page

2. Recap of Milestone 01 requirements and traceability

In the Assignment  01 collected 119 questionnaire responses from four stakeholder groups: undergraduate students (53), postgraduate students including one graduate (33), faculty members (19) and library staff (12), with IT support represented as a tertiary stakeholder. The findings that shaped the interface decisions are summarized below.

--- TABLE ---
Milestone 01 finding | Design consequence
57.3% (67/119) could not find a wanted book; “Current availability” was the top item to show first (Q6) | Availability status appears on every result card and at the top of Book Details
31.6% often/always cannot find a seat; a further 29.1% sometimes | Seat Map shows live occupancy and a system-recommended seat
Auto-recommend (33), floor/section filter (30) and list (28) for finding seats (Q9) | Recommendation card plus floor and area filters, instead of a plain list
Faster book reservation was the top reason for regular use, 42% (Q18) | Book reservation  is reachable  in a few taps from Home
Confirmation before cancelling (33) and cancel anytime (31) beat auto-release (29) (Q14) | Two-step cancel dialog with a stated consequence
Notification channel split between app (34), SMS (32) and email (32) (Q13) | In-app notification  center ; channel treated as a user setting
“Add me to a waiting list” was the top overflow option, 56 selections (Q17) | Waiting list for both books and seats, with queue position
Quick QR seat check-in was the top QR feature, 55 selections (Q16) | Dedicated QR Check-in screen for students and a scanner for staff

2.1 Requirements traceability table

Every screen in the high-fidelity prototype traces to at least one requirement. The FR and NFR numbers below are exactly those defined in our Milestone 01 report, so the two submissions agree with each other. Screen IDs match the frame names in the Figma Prototype page.

--- TABLE ---
ID | Requirement (Milestone 01) | Screens affected | Owner
FR01 | Search for library books | Book Search | Kalutotage
FR02 | Search by title, ISBN, author, subject | Book Search, Results | Kalutotage
FR03 | Display current book availability | Results, Book Details | Kalutotage
FR04 | Display book information before reserving | Book Details | Kalutotage
FR05 | Reserve an available book | Reserve for Pickup | Kalutotage
FR06 | Show the user’s active book reservations | My Reservations | Pathiranage
FR07 | Confirmation after a book reservation | Reservation Success | Kalutotage
FR08 | Display available reading-room seats | Seat Map | Yatawata
FR09 | Show seat information (power, quiet, window) | Seat Details | Yatawata
FR10 | Identify seats by preference | Filter Sheet, Recommendation | Yatawata
FR11 | Reserve an available seat | Seat Details, Reserve | Yatawata
FR12 | Confirmation after a seat reservation | Seat Success | Yatawata
FR13 | Join a waiting list | Waiting List | Yatawata
FR14 | Notify waiting-list users when a seat frees up | Waitlist Joined, Notifications | Yatawata ,  Wathudura
FR15 | Cancellation or expiry of reservations | Cancel Dialog, My Reservations | Pathiranage
FR16 | Send reservation reminders | Notifications | Pathiranage
FR17 | Provide reservation confirmations | Both success screens | Pathiranage
FR18 | Notify users of status changes | Notifications | Wathudura
FR19 | QR-based seat check-in | QR Check-in, Staff Scanner | Pathiranage
NFR01 | Clear, easy-to-understand interface | All screens (design system) | All
NFR03 | Accurate reservation and availability data | Status chips, live counts | All
NFR04 | Admin functions  limited  to  authorised  users | Login, Staff Dashboard | Wathudura
NFR06 | Usable with different accessibility needs | Contrast, labels, tap targets | All

Note: NFR02 (response time), NFR05 (data protection) and NFR07 (availability) are back-end qualities. A Figma prototype cannot demonstrate them, so they are not evaluated in this milestone.

3. Sketches and design alternatives

Before opening Figma, each member sketched several variants for every interface they own. The variants were compared using a simple pros-and-cons table and a group vote to shortlist (edit this line to name the exact ideation technique your group used, for example Crazy 8s). Sketches are kept unedited on Page 1 of the Figma file as the original ideation record.

3.1 Seat booking (Yatawata)

--- TABLE ---
Variant | Strength | Weakness | Decision
A. Plain list of seats | Very simple to build | No sense of where seats are | Rejected
B. Interactive floor map | Shows layout and occupancy | Crowded without help | Kept as base
C. Map with floor and area filters | Location plus preference in one view | Needs a clear legend | Selected
D. Auto-recommended seat card | Removes searching (Q9) | Must explain why a seat was chosen | Merged into C

The final design merges C and D. Users see the map with filters and, above it, a recommendation card (for example Seat 2C: quiet area, power outlet, near window). This follows Q9 directly, where users ranked automatic recommendation and floor filters ahead of a plain list.

--- TABLE ---
Figure 1.  Selected seat-booking sketch (Figma Page 1).

3.2 Book search and reservation (Kalutotage)

--- TABLE ---
Variant | Strength | Weakness | Decision
A. Search bar only | Minimal | No support for author, ISBN or subject | Rejected
B. Search bar with filter chips | Covers all four search types (Q7) | Needs a clear active state | Selected
C. Browse by category tiles | Good for exploring | Slow when the title is known | Secondary

3.3 Reservations, notifications, QR and staff (Wathudura, Pathiranage)

The same process was used for the reservation list, notification centre, QR check-in and staff screens. The chosen layouts were a tabbed list (Books | Seats) for My Reservations, a grouped notification feed with unread markers, a full-screen QR pass with a visible expiry, and a dashboard-first staff home. Each member’s sketch variants and reasons are shown in Figures 2 and 3.

--- TABLE ---
Figure 2.  Sketch variants for reservations and notifications (Figma Page 1).
Figure 3.  Sketch variants for QR check-in and staff screens (Figma Page 1).

4. Wireframes derived from selected sketches

Selected sketches were turned into greyscale wireframes on Page 2. Wireframes deliberately contain no colour, imagery or branding, so that layout, labels and task order can be judged on their own. Placeholder text is realistic enough to check wording (for example “Reserve for pickup”).

--- TABLE ---
Owner | Wireframes produced | Requirements covered
Yatawata | Seat Map, Filter Sheet, Seat Details, Seat Success, Waiting List, Waitlist Joined | FR08–FR14
Kalutotage | Book Search, Results, Book Details, Reserve, Reservation Success | FR01–FR05, FR07
Wathudura | My Reservations, Reservation Details, Cancel Dialog, Notifications | FR06, FR15, FR16, FR18
Pathiranage | Login, Register, Home, QR Check-in, Staff Dashboard, Scanner, Result | FR19, NFR04

4.1 Questions the wireframes had to answer

Can a first-time user tell what the next action is on every screen?

Are “available”, “reserved” and “occupied” visibly different for both books and seats?

Can filters be found without instruction?

Is cancelling visible but hard to trigger by accident?

Can staff tell valid, invalid and pending reservations apart?

--- TABLE ---
Figure 4.  Wireframe overview (Figma Page 2).

5. Low-fidelity prototype and validation

The greyscale wireframes were linked into a clickable flow in Figma, giving six navigable journeys. Before any styling was added, the group reviewed each journey with a cognitive walkthrough, asking at every step: will the user know what to do, see the control, and understand the feedback? Record who took part in the review here: [ enter reviewers and date ].

--- TABLE ---
Journey | Starts at | Path | Ends at
Book reservation | Book Search | Search → Results → Details → Reserve | Reservation Success
Seat reservation | Seat Map | Filter → Details → Reserve | Seat Success
Seat waiting list | Seat Map | No seat → Preferences → Join | Waitlist Joined
Manage reservation | My Reservations | Details → Cancel → Confirm | Updated list
QR check-in | QR Check-in | Show pass → Verify | Success / Invalid
Staff verification | Staff Dashboard | Scanner → Result | Verified / Mismatch

5.1 What the walkthrough changed

--- TABLE ---
Finding | Change made | Requirement
Cancel and Reserve looked equally important | Cancel moved to a secondary style and placed behind a confirmation step | FR15, NFR01
Route to seat booking was unclear from Home | Added a labelled “Reserve a Seat” action and bottom-nav entry | FR08, FR11
Waiting-list result gave no position | Added queue position on the confirmation screen | FR13, FR14
Book and seat statuses looked alike | Separate status wording and chips for each | FR03, NFR03
Figure 5.  Low-fidelity prototype with the starting frame marked (Figma Page 3).

6. High-fidelity prototype and interaction flow

The validated structure was rebuilt with realistic content and a shared visual language. The prototype is a set of connected mobile frames inside the Prototype section of the Figma file.

6.1 Design system

--- TABLE ---
Element | Decision and reason
Colour | Navy for identity, blue for primary actions. Green means available or confirmed, amber means attention, red means destructive or invalid.  Colour  is never the only signal; every status also has a text label (NFR06).
Typography | Inter. Bold headings, medium labels, regular body. Body text no smaller than 14  px .
Layout | 390 × 844  px  mobile frames, 16  px  margins, 8  px  spacing grid.
Components | Cards, chips, tabs, bottom navigation, bottom sheets and dialogs, built once and reused by all four members.
Touch targets | Buttons and list rows at least 44  px  high.

6.2 Screens by member

--- TABLE ---
Member | High-fidelity screens | Main requirements
Yatawata | Seat Map, Filter Sheet, Seat Details, Seat Success, Waiting List, Waitlist Joined | FR08–FR14
Kalutotage | Book Search, Results, Book Details, Reserve, Reservation Success | FR01–FR05, FR07
Wathudura | My Reservations, Cancel Dialog, Notifications | FR06, FR15, FR16, FR18
Pathiranage | Login, Register, Home, QR Check-in, Staff Dashboard, Scanner, Result | FR19, NFR04
Figure 6.  Yatawata’s  high-fidelity seat-booking screens.
Figure 7.  Kalutotage’s  high-fidelity book screens.
Figure 8.  Pathiranage’s  reservation and notification screens.
Figure 9.     Wathudura’s   home, QR and staff screens.

6.3 Interaction flow

Present mode starts at Login. From Home the user reaches every journey; the bottom navigation stays available so nobody gets stranded.

Student: Login → Home → Search Books or Reserve a Seat → details → confirm → My Reservations or Notifications → QR Check-in.

Seat: Seat Map → Filter Sheet → recommended Seat 2C → Details → Reserve → Success. With no seat free: Waiting List → Waitlist Joined (queue position).

Book: Home → Search → Results → Book Details → Reserve for Pickup → Success. An unavailable book offers the waiting list instead.

Staff: Staff Login → Dashboard → Scanner → Verified or Mismatch result.

--- TABLE ---
Figure 10.  Prototype flow map showing the connected paths.

7. User testing plan

We will run moderated, task-based usability tests on the high-fidelity prototype. This method shows where real users hesitate or misread the interface and produces the measurable evidence the brief requires: at least five real or proxy users, recorded sessions, and at least one task per major requirement.

7.1 Participants

Five to six people from the Milestone 01 audience (undergraduates, a postgraduate or faculty proxy, and one person in the library-staff role), anonymised as P1–P5, each giving consent before recording.

7.2 Tasks and success criteria

--- TABLE ---
# | Task given to the participant | Success criterion | Requirements
T1 | Find a quiet seat with a power outlet using the filters. | Finds Seat 2C in 90 s without help | FR08–FR10
T2 | Reserve that seat for 24 Aug, 10:00–12:00. | Reaches and explains the confirmation in 60 s | FR11, FR12, FR17
T3 | A full room: join the seat waiting list. | Finds queue position and explains it | FR13, FR14
T4 | Search “Introduction to Human Computer Interaction” and reserve it. | Reaches Success and finds shelf info | FR01–FR05, FR07
T5 | Find your active reservations and cancel one. | Reads the consequence before confirming | FR06, FR15
T6 | Open your notifications and say what needs action. | Identifies the reminder | FR16, FR18
T7 | Open your QR pass and say when you  would  use it. | Displays pass and  states  purpose | FR19
T8 | Staff role: verify a reservation using the scanner. | Reaches  a result and explains it | FR19, NFR04

7.3 Metrics

--- TABLE ---
Metric | How it is measured | Target
Task completion | Successful, partial or failed, per task | ≥ 80% successful
Time on task | Stopwatch from the recording | Within the stated limit
Errors | Wrong taps or wrong screens per task | ≤ 1 per task
Assistance | Times the moderator had to help | 0 per task
Ease rating (SEQ) | 1 (very difficult) to 7 (very easy) after each task | Mean ≥ 5.5

Procedure. Consent and a neutral briefing; the participant shares their screen and the session is recorded. Tasks are read aloud one at a time and the moderator helps only after a long pause, with an SEQ rating after each task and a short closing interview. Recordings are uploaded to Google Drive with “Anyone with the link can view”.

8. Testing results and usability issues

--- TABLE ---
Complete this section from your real sessions The yellow cells below are placeholders. Fill them only with evidence from your recordings. The brief requires at least 5 recorded participants and a severity-rated issue log. Do not enter invented results.

8.1 Participant results

--- TABLE ---
Participant | Role / proxy | Tasks succeeded | Total time | Mean SEQ | Main observation
P1 | Undergrad | x / 8 | mm:ss | x.x | ...
P2 | Undergrad | x / 8 | mm:ss | x.x | ...
P3 | Postgrad | x / 8 | mm:ss | x.x | ...
P4 | Faculty proxy | x / 8 | mm:ss | x.x | ...
P5 | Staff proxy | x / 8 | mm:ss | x.x | ...

8.2 Summary metrics

--- TABLE ---
Metric | Result | Target met?
Overall completion rate | __ % | Yes / No
Median time per task | __ s | Yes / No
Mean errors per task | __ | Yes / No
Mean SEQ | __ / 7 | Yes / No

8.3 Usability issue log

Severity scale: High prevents task completion; Medium causes confusion or delay; Low is a minor inconvenience or visual issue. Issues are logged even if they are not fixed.

--- TABLE ---
# | Issue | Evidence | Severity | Recommendation | Status
1 | ... | P?,   T?,  time | H/M/L | ... | Open/Fixed
2 | ... | P?,   T?,  time | H/M/L | ... | Open/Fixed
3 | ... | P?,   T?,  time | H/M/L | ... | Open/Fixed
4 | ... | P?,   T?,  time | H/M/L | ... | Open/Fixed
5 | ... | P?,   T?,  time | H/M/L | ... | Open/Fixed

Recording links: [ paste public Google Drive folder link ]

9. Recommendations for further refinement

The items below are design risks we already expect to check against the test data. After the sessions, keep only those the evidence supports, add new ones from the issue log, and cite a participant and task for each.

--- TABLE ---
# | Recommendation | Why we expect it matters | Evidence (add)
1 | Make the filter control and the reason for the recommended seat more prominent | Users prefer recommendations and filters (Q9), so missing them defeats the purpose | P?,  T1
2 | Show clearly different states for available, selected, occupied and reserved seats | Prevents booking errors on a dense map | P?,  T1–T2
3 | Keep cancellation behind an explicit confirmation that states the result | Q14 showed users want confirmation before cancelling | P?,  T5
4 | Show QR guidance before the scanner opens | Staff and students must understand the check-in step | P?,  T7–T8
5 | Give visible feedback after reserving, joining a list and cancelling | Confirmation supports FR07, FR12, FR17 | P?,  T2–T5
6 | Add a notification-channel setting | Q13 showed no single preferred channel | P?,  T6

9.1 Limitations

The prototype is not connected to real library data, so availability and queue numbers are fixed sample values. Response time (NFR02), data protection (NFR05) and uptime (NFR07) cannot be tested in Figma and are left for implementation. Proxy participants may not behave exactly like library staff, so staff-flow findings should be treated with more caution.

10. Time schedule (Gantt chart)

The schedule runs from the release of the brief (24 July 2026) to the deadline (9 August 2026). Adjust the week labels to your real dates before submitting.

--- TABLE ---
Task | W1 | W2 | W3 | W4 | W5 | W6 | Responsible
Review  M01 requirements and traceability |  |  |  |  |  |  | All
Sketches and design variants |  |  |  |  |  |  | All
Wireframes |  |  |  |  |  |  | All
Low-fidelity prototype and walkthrough |  |  |  |  |  |  | All
High-fidelity design and prototype wiring |  |  |  |  |  |  | All
Test plan and consent materials |  |  |  |  |  |  | All
Five recorded testing sessions |  |  |  |  |  |  | All
Analysis, issue log, recommendations |  |  |  |  |  |  | All
Report writing and viva preparation |  |  |  |  |  |  | All

10.1 Individual contributions

--- TABLE ---
Member | Reg. No | Contribution
Yatawata | IT23628854 | Seat-booking sketches, wireframes and high-fidelity screens; assembled and wired the full Prototype section;
Kalutotage | IT23612228 | Book search and reservation sketches, wireframes and high-fidelity screens
Pathiranage | IT23617100 | My Reservations, cancellation and notification screens
Wathudura | IT23607446 | Login, home, QR check-in and staff screens

References

Dix, A., Finlay, J., Abowd, G. D. and Beale, R. (2004) Human-Computer Interaction. 3rd edn. Harlow: Pearson Education.

Nielsen, J. (1994) 10 Usability Heuristics for User Interface Design. Nielsen Norman Group. Available at: https://www.nngroup.com/articles/ten-usability-heuristics/

Sauro, J. and Dumas, J. S. (2009) ‘Comparison of three one-question, post-task usability questionnaires’, Proceedings of CHI 2009. ACM.

Figma, Inc. Figma design and prototyping platform. Available at: https://www.figma.com/

World Wide Web Consortium (2018) Web Content Accessibility Guidelines (WCAG) 2.1. Available at: https://www.w3.org/TR/WCAG21/

Sri Lanka Institute of Information Technology (2026) IT3060 Human Computer Interaction: Milestone 01 report (Group WE_153_2.2) and Milestone 02 assignment brief.

HCI - Library Book Reservation and Seat Booking - System prototype video
