# Nordic Modern Campus — UI reference

Flutter implementation of the Lamplight redesign (tokens in `lib/core/theme/app_theme.dart`).

| Token | Light | Usage |
|-------|-------|--------|
| Canvas | `#F8FAFC` | `ColorScheme.surface` |
| Primary | `#0D50E8` | Buttons, links |
| Indigo | `#4F46E5` | Nav pill, selected seats |
| Amber | `#F59E0B` | Yours / top pick only |
| Card radius | 24dp | `AppRadii.card` |

**Chrome:** `GlassDock` in `lib/core/widgets/glass_dock.dart` — floating bottom nav with blur.

**Navigation:** `AppRoute.push` / `pushReplacement` in `lib/core/navigation/app_route.dart`.

**Home layout:** Greeting → session `DepthHero` → 2×2 `BentoTile` → segmented occupancy meter.

Stitch mocks are optional; this doc tracks the shipped Flutter source of truth.
