# Library+ · UI Mockup & Design System
**Codename: "The Ledger" — a vintage-library-luxury design language**

> Version 1.0 · 2026-08-25 · This document is the single source of truth for the app's visual
> identity. Every screen, component, motion, and asset decision traces back to here.

---

## 1. Design Concept — why "The Ledger"

Most library apps look like admin panels: white cards, blue buttons, list tiles. We reject that.
Our concept turns the app into a **beautiful object you already love: the library itself** —
a card catalog drawer, a leather ledger, a stamped due-date card, a brass lamp, a member
card with a gold chip.

**The one-line pitch:** *a modern student app dressed as a priceless private-library ledger —
ink on cream paper, gold foil accents, serif headlines, stamped status marks, ticket-stub cards.*

### 1.1 Moodboard keywords
`vintage ledger` · `letterpress` · `gold foil on navy` · `cream paper` · `library due-date card` ·
`ticket stub` · `monogram embossing` · `card catalog` · `private club member card` · `archive drawer`

### 1.2 Inspiration sources (and how each one is used)

| Source | What we take from it |
|---|---|
| **Pinterest** (moodboard research) | Vintage library / dark-academia interiors, gold-on-navy book plates, letterpress posters, ticket & stamp ephemera. Drives palette, texture and typography choices. |
| **Flaticon** (flaticon.com/free-icons/mobile-app) | Custom icon set direction: consistent 1.5–2px stroke line icons with slightly rounded joins — "etched pen" feel. Categories to pull: book, armchair, qr, hourglass, bell, shield, bolt, star, compass. *(Material Symbols rounded is used until the custom set is exported; the icon grid, sizes and stroke weights below are already Flaticon-compatible.)* |
| **React Bits** (reactbits.dev) | Motion vocabulary, ported to Flutter: **Blur-Fade** reveals for headlines, **Spotlight Card** (pointer-following highlight) for the hero ledger, **Shimmer** sweeps on gold text, **Count-Up** stat numbers, **Magnet**-style press feedback (scale 0.97 + spring back), **Aurora/gradient drift** for dark surfaces. |
| **LottieFiles** (lottiefiles.com/free-animations/3d-website) | Future drop-in animations: 3D book opening (splash), floating lamp glow (empty states), paper-plane "reservation sent" (confirmations). Integration point prepared in §7; the v1 splash reproduces the book-opening moment in pure Flutter so there is zero asset dependency. |

---

## 2. Color System

Warm ivory paper, deep ink navy, and foil gold. Semantic greens/ambers/reds are desaturated
to feel like ink stamps rather than UI status colors.

### 2.1 Core palette

| Token | Hex | Role |
|---|---|---|
| `paper` | `#F2EDE2` | App background — warm ivory |
| `paperCard` | `#FBF8F0` | Card surfaces — lighter cream |
| `paperDeep` | `#E9E2D2` | Sunken areas, inner fields, entrance strip |
| `ink` | `#1B2334` | Primary ink — headlines, hero ledger card, bottom bar |
| `inkDeep` | `#141A28` | Deepest navy — gradients, member card end-stop |
| `inkSoft` | `#2A3450` | Navy for secondary dark surfaces / hover |
| `gold` | `#C9A24B` | Foil gold — accents, active nav, stat numerals |
| `goldDeep` | `#A9832F` | Gold pressed on light paper (chips, icons) |
| `goldSoft` | `#E7D9B8` | Gold tint fill (icon tiles, stamp backgrounds) |
| `textPrimary` | `#20242E` | Body ink on paper |
| `textSecondary` | `#6E6A5E` | Warm grey secondary text |
| `textFaint` | `#9A9483` | Tertiary, mono eyebrows at 70% |
| `line` | `#E2DAC6` | Hairline borders on paper |
| `lineOnInk` | `#FFFFFF 12%` | Hairline borders on navy |

### 2.2 Semantic "ink stamp" colors

| Token | Hex | Used for |
|---|---|---|
| `stampGreen` | `#3E7C5B` | AVAILABLE, ACTIVE, success banners |
| `stampGreenSoft` | `#3E7C5B @ 10%` | stamp fill |
| `stampGold` | `#B98A2F` | RESERVED, HOLD, waiting states |
| `stampRed` | `#B54B42` | BUSY, claim-deadline banners, destructive |
| `stampRedSoft` | `#B54B42 @ 8%` | claim banner fill |
| `seatFree` | `#3E7C5B` | seat map free tiles |
| `seatHold` | `#C9962E` | seat map held tiles |
| `seatBusy` | `#C4574E` | seat map busy tiles |

### 2.3 Gradients

- `ledgerGradient` — `#232C44 → #141A28` (top-left → bottom-right): hero ledger card, member card, best-match card.
- `foilGradient` — `#E3C77E → #C9A24B → #A9832F`: gold chip, gold icons on ink, splash emblem.
- `paperWash` — `#F6F1E7 → #EFE9DB`: optional subtle vertical wash for long screens.

---

## 3. Typography — three voices, like a printed ledger

| Voice | Font | Usage |
|---|---|---|
| **Display serif** | *Playfair Display* (700/800, italic for flourishes) | Screen titles ("The catalog", "Find a seat"), greeting, book titles on covers, "— end of your queue —" (italic). Sizes 26–34, tracking −0.5. |
| **Archive mono** | *JetBrains Mono* (600/700) | Eyebrows and stamps, ALWAYS uppercase, tracking +2…+4, sizes 10–12: "5 TITLES READY", "LEDGER — TUESDAY, AUG 25", "POS. 2", "VALID THRU 2027", "ROW A — WINDOW SIDE". |
| **Workhorse sans** | *Inter* (400–800) | Everything else: body, subtitles, buttons, nav labels. |

**Rules**
- Every screen opens with: mono eyebrow (gold or faint) → serif display headline.
- Numbers that matter (stats, countdowns, seat labels) are either serif bold or mono bold — never light.
- No sentence-case eyebrows. Ever. Mono voice is always CAPS + letterspaced.

---

## 4. Geometry, Elevation & Texture

- **Radii:** cards 20 · inner tiles 14 · pills/stamps 999 · hero & member card 24 · seat tiles 14.
- **Borders over shadows.** Paper world: 1px `line` borders, shadows only whisper (`0 10 30 ink@6%`).
  Ink world (hero/member/best-match/nav): deep soft shadow `0 16 40 ink@35%`.
- **Ticket-stub card** (signature component): left perforation — vertical dashed gold line inset 14px,
  with two punched half-circle notches (top/bottom of the perforation line) cut into the card edge.
- **Dashed dividers** (gold @ 40%) separate logical zones inside cards (seat rows, waitlist meta).
- **Paper texture (later):** 2–3% opacity fractal-noise image tiled over `paper`; code-drawn dot grid at 3% is the v1 stand-in on dark surfaces.
- **Touch targets:** ≥ 48dp (NFR06), 52dp for primary actions.

---

## 5. Component Inventory (v1 implemented)

1. **LedgerHeroCard** (Home) — navy gradient, mono eyebrow `LEDGER — <WEEKDAY, MON DD>`,
   serif greeting "Good afternoon, Alex.", one-line subtitle, and a row of 3 **stat boxes**
   (translucent `white 6%` fill, `white 12%` border, gold serif numerals, mono labels).
   A gold QR tile sits top-right; a `✦ LIBRARY+` foil-outlined pill top-left.
2. **StampChip** — dashed 1.4px border in stamp color, `stampColor @ 8–10%` fill, mono 10.5px
   uppercase tracking +2, optional 6px dot. Variants: ACTIVE (green + pulsing dot), RESERVED (gold),
   WAITING (gold), POS. n (ink on paper), AVAILABLE / ON LOAN / BUSY.
3. **TicketCard** — cream card, left perforation + notches, content rows; used for glance items
   and waitlist entries. Trailing meta in mono (e.g. "4 MIN", "~40M").
4. **MemberCard** (Account) — navy gradient, foil gold chip (44×34 rounded rect w/ inner rule lines),
   `✦ LIBRARY+ MEMBER` mono eyebrow, serif name, mono `STU · 2024 · 1847`, email, right-aligned
   mono `VALID THRU 2027`.
5. **QuickActionTile** — cream tile, gold-soft rounded icon well (Flaticon-style line icon in
   `goldDeep`/semantic tint), sans 12px label, count badge as gold dot with numeral.
6. **SectionHeader** — serif 20px title + optional mono count on the right ("5 TITLES").
7. **BookCover** — two tiers: (a) **network tier**: real cover art from OpenLibrary covers API by
   ISBN (see §7.3) with serif-initials fallback while loading / offline; (b) **fallback tier**:
   flat `inkDeep`-family color block, gold spine rule inset 8px, Playfair initials centered,
   bottom gold tick. Radius 10–14, shadow `0 8 20 ink@25%`.
8. **SeatTile** — 48×48, radius 14, 1.6px status border, status fill @ 12%, mono 12px label,
   6px gold "power dot" bottom-right when outlet exists. Free tiles get a faint inner glow.
   Busy tiles are muted (fill 6%, text 45%).
9. **BestMatchCard** — navy gradient strip: gold star tile, serif "Best match: B1",
   sans 13px "Power outlet · window-adjacent · quiet zone". Tappable.
10. **LedgerNavBar** — full-width `inkDeep` bar, 72dp, icons+labels: inactive `paper @ 38%`,
    active gold with 20×3 gold top indicator. Mono-ish tight labels 11px.
11. **Buttons** — primary: ink navy pill (radius 16, 52dp, sans 15 w700, gold icon when present).
    Secondary: transparent, 1.4px `line`/`ink @ 25%` border. Destructive-link: stamp red text.
12. **Banner** (notify / claim) — stamp-tinted fill, dashed stamp border, stamp icon, 13px w600 text.

---

## 6. Screen Blueprints

### 6.1 Splash — "The Opening" (animated)
Ivory stage. Sequence (total ~2.4s, then cross-fade 400ms into Home):
1. 0–600ms — a gold foil ring draws itself clockwise around center (arc sweep, easeOutCubic).
2. 300–900ms — an etched book emblem scales 0.7→1.0 with fade inside the ring.
3. 700–1300ms — "Library+" in Playfair 800 fades up 12px; a foil shimmer sweeps across the wordmark once.
4. 1000–1600ms — mono eyebrow "EST. 2024 · CAMPUS READING ROOM" letters fade in staggered.
5. 1800–2400ms — everything holds; a soft ink vignette breathes once; then fade to shell.
Status bar: ink icons on ivory. Skip-on-tap. Reduced-motion: static emblem + 400ms fade.

### 6.2 Home — "The Ledger"
- **LedgerHeroCard** (see §5.1) full-bleed-ish (20px margins), radius 24.
- **Quick actions** — 4 tiles: Search / Book Seat / My Holds (gold count dot) / Scan QR.
- **"Today at a glance"** — serif header; TicketCards:
  Seat A1 [ACTIVE stamp + pulsing dot | mono "4 MIN"] → grace banner inside (dashed amber):
  "Check in within 4 min or the seat returns to the floor."
  DoET cover thumb [RESERVED stamp] "Pickup by Aug 27".
  Quiet Zone [WAITING stamp] "Position #2 in line" | mono "~40M".
- **Discover** — "Browse the catalog" (cover thumb, mono sub "5 TITLES READY") and
  "Find a quiet seat" (mono sub "17 SEATS OPEN RIGHT NOW"), both with ink arrow-in-circle.

### 6.3 Books — "The Catalog"
- Eyebrow `5 TITLES READY` → serif "The catalog" → search field (cream, 1px line, gold caret).
- Filter stamps: ALL / AVAILABLE NOW / FICTION (selected = ink fill, paper text).
- **Trending this week** — horizontal carousel of large fallback covers (110×150), serif titles
  beneath, mono status word (RESERVED gold / WAITLIST amber / AVAILABLE green).
- **List rows** — cover thumb 48×64, serif title 16, sans author · copies, ink **Reserve** pill.
- Detail screen: large cover, serif title, stamp status, ruled InfoRows (mono labels), ink CTA bar.

### 6.4 Seats — "Find a seat"
- Eyebrow `FLOOR 1 · READING ROOM` → serif "Find a seat"; map/list toggle tiles top-right.
- Floor + section stamp filters; legend row with counts ("9 available of 12 shown").
- Map card: dashed `↓ ENTRANCE` strip; per-row mono labels `ROW A — WINDOW SIDE`,
  `ROW B — CARREL DESKS`; gold dashed dividers between rows; seat grid (§5.8);
  mono footnote "● MARKS POWER OUTLET".
- **BestMatchCard**; **Other sections** — two cream tiles: mono eyebrow + serif numeral + sans unit.

### 6.5 Waitlist — "Your queue"
- Eyebrow `YOUR QUEUE` → serif "Waitlist" + info tile.
- Mint notify banner (dashed green stamp border).
- TicketCards: icon/cover tile, serif title, sans sub, **POS. n** ink stamp;
  dashed divider; mono meta row (clock + "Estimated wait ~40 minutes");
  claim banner (dashed red stamp): "Claim within 17:59…"; Leave waitlist secondary button.
- Footer: Playfair italic, faint — "— end of your queue —".

### 6.6 Account — "The member card"
- Eyebrow `MEMBER SINCE 2024` → serif "Account".
- **MemberCard** (§5.4).
- Groups PRIVACY / ACCESSIBILITY / QUICK LINKS as mono eyebrows; cream group cards with
  gold-soft icon tiles; ink switches; chevrons `ink @ 30%`.

### 6.7 QR — "The stamping desk"
Ink navy full screen. Viewfinder: `#0E1422` rounded 28, gold corner brackets, animated gold
sweep line (2.2s loop). Mono instruction text `paper @ 70%`. Paper-white CTA button with ink text.

### 6.8 Detail / Confirmation
Success: gold foil ring burst → serif "You're all set." → cream summary card with ruled
SummaryRows (mono labels, serif-ish values) → ink CTA + text-button.

---

## 7. Motion System

### 7.1 Tokens
- Durations: micro 120ms · standard 220ms · entrance 350ms · dramatic 600ms · splash steps per §6.1.
- Curves: `easeOutCubic` (enter) · `easeInCubic` (exit) · `easeInOut` (loops) ·
  `easeOutBack` (playful pop, badges/stamps only).
- Page transitions: fade + 24px up-slide + slight scale 0.98→1 (React-Bits BlurFade spirit).

### 7.2 Screen choreography
- **Staggered list entrance:** children enter 40ms apart, 350ms fade+16px rise (max 8 items, then instant).
- **Count-Up** on hero stat numerals (600ms, once per visit).
- **Pulse dot** on ACTIVE stamps: 2s opacity 1→0.35 loop.
- **Shimmer** across gold elements (foil sheen) on splash + member card chip, 1.6s, once per mount.
- **Press feedback:** scale 0.97, 120ms, spring return (all tappable cards/tiles).
- **QR sweep:** gold gradient line, 2.2s ease-in-out loop between brackets; stops on success,
  check emblem pops with easeOutBack.

### 7.3 Live data motion
- Grace/claim countdowns tick every second (mono digits, fixed-width so no jitter).
- Seat tiles: 150ms color/border transition on status change (future realtime).

---

## 8. Asset Strategy (the four sources, concretely)

### 8.1 Icons — Flaticon
- Target set: ~24 line icons, 24px grid, 1.5px stroke, rounded caps — one family, one designer
  (search "lineal" packs; e.g. flaticon.com/free-icons/mobile-app as starting point).
- Delivery: SVG → export PNG @1x/2x/3x or a custom IconFont; drop into `assets/icons/`.
- v1 ships with Material Symbols (rounded) tuned to the same stroke feel; swap is drop-in
  because every icon call goes through `IconBadge`/tiles.

### 8.2 Motion — LottieFiles
- Curated shortlist to license/download as `.json` into `assets/lottie/`:
  3D book opening (splash upgrade), quill/ink signature (confirmation), floating lamp (empty states),
  paper plane (notification sent). Integration: `lottie` package, `Lottie.asset(..., repeat: false)`.
- Rule: Lottie is garnish, never load-bearing; every Lottie moment has the pure-Flutter fallback
  already implemented (§6.1, §6.8).

### 8.3 Images — internet
- **Book covers (v1, live):** OpenLibrary covers API —
  `https://covers.openlibrary.org/b/isbn/<ISBN>-L.jpg` (free, no key).
  Loaded via `Image.network` with serif-initials placeholder + fallback (§5.7). Mock ISBNs are real.
- **Background textures (v1.1):** subtle paper grain / leather texture tiles (Unsplash/Pexels,
  2–4% opacity) into `assets/textures/`; applied behind `paper` and inside ink cards.
- **Hero art (v1.1):** one dark-academia library illustration for the splash backdrop @ 6% opacity.
- Licensing note: prefer Unsplash/Pexels (free); record attribution in `ASSETS-CREDITS.md`.

### 8.4 Pinterest
- Maintain a board per screen ("ledger home", "catalog shelf", "seat map wayfinding");
  each accepted pin maps to a token/section in this file. Mood drift beyond §1.1 requires
  updating this doc first.

---

## 9. Accessibility & Quality Gates
- Contrast: ink on paper 13:1; gold on ink ≥ 4.6:1; stamp colors ≥ 4.5:1 on their tint fills.
- `Semantics` labels on seat tiles ("Seat B1, free, power outlet"), stamps, and nav.
- 48dp targets; countdown digits fixed-width; reduced-motion path for splash/loops.
- No layout jank: fixed-size covers/tiles, `cacheWidth` on network images, placeholder always
  same footprint as final art.

## 10. Implementation Map (Flutter)
| Design artifact | Code home |
|---|---|
| Tokens (§2–4) | `core/theme/app_theme.dart` — `AppColors`, `AppGradients`, `AppShadows`, `AppTypography` |
| StampChip, TicketCard, MemberCard, LedgerHero, BookCover, BestMatch | `core/widgets/ledger_widgets.dart` + `shared_widgets.dart` |
| Splash (§6.1) | `core/widgets/splash_screen.dart`, wired in `app.dart` |
| Screen blueprints (§6) | `features/**` screens |
| Motion (§7) | per-screen `AnimationController`s; implicit `Animated*` for micro-motion |
| Covers (§8.3) | `BookCover.network(isbn:)` in `ledger_widgets.dart` |

## 11. Roadmap
- **v1 (this pass):** tokens, splash, ledger hero, stamps/tickets, catalog carousel + network
  covers, seat map rows + best match, waitlist queue, member card, ink nav bar.
- **v1.1:** paper/leather textures, Flaticon custom set swap, hero backdrop art, count-up + stagger polish.
- **v1.2:** Lottie garnish set, spotlight-card hero (React Bits), realtime seat pulses, dark "midnight reading" theme (ink-first inversion of this system).
