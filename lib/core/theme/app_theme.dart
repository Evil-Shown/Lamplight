import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nordic Modern Campus — Material 3 design system.
///
/// Sapphire primary (#0D50E8), indigo selection (#4F46E5), porcelain
/// canvas (#F8FAFC), amber (#F59E0B) for “yours” only. Hand-tuned schemes
/// (no `fromSeed`) so surfaces stay crisp.
/// Every legacy token — `AppColors`, `AppText`, `AppShadows`,
/// `AppGradients` — resolves onto the scheme so all thirty screens
/// restyle together.
///
/// Colours resolve through getters so the app can flip to the dark
/// scheme at runtime; call sites keep the same `AppColors.x` syntax —
/// the trade-off is that colours can't appear inside `const`
/// expressions.
class AppColors {
  AppColors._();

  /// Nordic light: sapphire, porcelain canvas, indigo accent.
  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF6B3516),
    onPrimary: Color(0xFFFFF3E0),
    primaryContainer: Color(0xFFF3D3A6),
    onPrimaryContainer: Color(0xFF3A1B06),
    secondary: Color(0xFF9C4A2B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF4D5C4),
    onSecondaryContainer: Color(0xFF3E1608),
    tertiary: Color(0xFF7A5A1A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF2DDA0),
    onTertiaryContainer: Color(0xFF35270A),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFE8B380),
    onSurface: Color(0xFF2A180C),
    onSurfaceVariant: Color(0xFF4A2F1C),
    outline: Color(0xFF6B4A32),
    outlineVariant: Color(0xFFB88652),
    inverseSurface: Color(0xFF2A180C),
    onInverseSurface: Color(0xFFFBEBD3),
    inversePrimary: Color(0xFFF0B070),
    surfaceContainerLowest: Color(0xFFFFF9EE),
    surfaceContainerLow: Color(0xFFFFF1DC),
    surfaceContainer: Color(0xFFF2D9B4),
    surfaceContainerHigh: Color(0xFFE8C799),
    surfaceContainerHighest: Color(0xFFDDB57F),
    surfaceDim: Color(0xFFD9A369),
    surfaceBright: Color(0xFFEBB886),
  );

  /// Nordic dark: slate canvas, light sapphire primary.
  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFFF0B070),
    onPrimary: Color(0xFF2A1503),
    primaryContainer: Color(0xFF7A4A1E),
    onPrimaryContainer: Color(0xFFFFDDB8),
    secondary: Color(0xFFE0A58A),
    onSecondary: Color(0xFF3E1608),
    secondaryContainer: Color(0xFF5A3322),
    onSecondaryContainer: Color(0xFFF8DECF),
    tertiary: Color(0xFFE6C98A),
    onTertiary: Color(0xFF35270A),
    tertiaryContainer: Color(0xFF5E4A12),
    onTertiaryContainer: Color(0xFFF6E8B8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1C110C),
    onSurface: Color(0xFFF6E6D2),
    onSurfaceVariant: Color(0xFFD6BCA3),
    outline: Color(0xFFA58A72),
    outlineVariant: Color(0xFF43302A),
    inverseSurface: Color(0xFFF6E6D2),
    onInverseSurface: Color(0xFF2A180C),
    inversePrimary: Color(0xFF6B3516),
    surfaceContainerLowest: Color(0xFF120A07),
    surfaceContainerLow: Color(0xFF271912),
    surfaceContainer: Color(0xFF2F1F16),
    surfaceContainerHigh: Color(0xFF3B281C),
    surfaceContainerHighest: Color(0xFF4B3426),
    surfaceDim: Color(0xFF1C110C),
    surfaceBright: Color(0xFF3B281C),
  );

  /// Electric indigo — selected seats, nav pill, focus rings.
  static const Color indigo = Color(0xFFB5532C);

  /// Cyan accent for your seat / special highlights (no yellow).
  static const Color amberHighlight = Color(0xFFE6B422);

  /// The scheme matching the active brightness. Kept in sync by the app
  /// root through [isDark] before the frame is built.
  static ColorScheme get scheme =>
      isDark ? _darkScheme : _lightScheme;

  /// Whether the dark palette is active. Synced by the app root from
  /// [AppState.themeMode] before the frame is built.
  static bool isDark = false;

  // Surfaces — M3 tonal tiers instead of white cards on an off-white page.
  static Color get background => scheme.surface;
  static Color get surface => scheme.surfaceContainerLow;
  static Color get surfaceMuted => scheme.surfaceContainer;
  static Color get surfaceSunken => scheme.surfaceContainerHighest;

  // Brand — the primary roles. Lift is a brighter vivid blue (light mode)
  // or a deeper one (dark), never a grey blend.
  static Color get primary => scheme.primary;
  static Color get primaryDark => scheme.onPrimaryContainer;
  static Color get primarySoft => scheme.primaryContainer;
  static Color get primaryBright => scheme.primary;
  static Color get primaryLift => isDark
      ? Color.lerp(scheme.primary, Colors.black, 0.25)!
      : Color.lerp(scheme.primary, Colors.white, 0.22)!;

  // Accents — tertiary is the seeded warm complement, secondary the
  // quiet counterpart.
  static Color get accent => scheme.tertiary;
  static Color get accentSoft => scheme.tertiaryContainer;
  static Color get cyan => scheme.secondary;
  static Color get cyanSoft => scheme.secondaryContainer;
  static Color get gold =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get goldSoft =>
      Color.alphaBlend(gold.withValues(alpha: 0.12), scheme.surface);

  // Text — M3 foreground roles.
  static Color get textPrimary => scheme.onSurface;
  static Color get textSecondary => scheme.onSurfaceVariant;
  static Color get textFaint => scheme.outline;
  static Color get textInverse => scheme.onPrimary;

  // Lines — M3 outline roles.
  static Color get border => scheme.outlineVariant;
  static Color get borderStrong => scheme.outline;

  // Status — semantic tonal pairs pinned to the design-spec `AppSemantic`
  // extension so pills, icons and text stay harmonised across surfaces in
  // both brightnesses.
  static Color get success =>
      isDark ? const Color(0xFF8FD6A3) : const Color(0xFF1E6B3A);

  /// Explicit success container — never an alpha blend.
  static Color get successContainer =>
      isDark ? const Color(0xFF12432A) : const Color(0xFFD8F0DE);
  static Color get onSuccessContainer =>
      isDark ? const Color(0xFFBDF0CB) : const Color(0xFF0B3318);

  /// Alias so legacy call sites resolve onto the pinned container.
  static Color get successSoft => successContainer;
  static Color get warning =>
      isDark ? const Color(0xFFF2C25B) : const Color(0xFF8A5A00);

  /// Explicit warning container — never an alpha blend.
  static Color get warningContainer =>
      isDark ? const Color(0xFF4A3500) : const Color(0xFFFFE9B8);
  static Color get onWarningContainer =>
      isDark ? const Color(0xFFFFE08A) : const Color(0xFF3D2800);

  /// Alias so legacy call sites resolve onto the pinned container.
  static Color get warningSoft => warningContainer;
  static Color get error => scheme.error;

  /// Explicit error container from the scheme (soft error fills).
  static Color get errorContainer => scheme.errorContainer;
  static Color get onErrorContainer => scheme.onErrorContainer;
  static Color get errorSoft =>
      Color.alphaBlend(error.withValues(alpha: 0.10), scheme.surface);
  static Color get info => primary;
  static Color get infoSoft =>
      Color.alphaBlend(primary.withValues(alpha: 0.10), scheme.surface);
  static Color get neutral => scheme.onSurfaceVariant;
  static Color get neutralSoft => scheme.surfaceContainerHigh;

  // Seat map — aliases per spec §3.1 (yours = primary, selected = rust).
  static Color get seatAvailable => success;
  static Color get seatLimited => warning;
  static Color get seatOccupied => error;
  static Color get seatSelected => indigo;
  static Color get seatYours => primary;

  /// ARGB values, so they line up with `Book.coverColor`. Deterministic:
  /// index = `book.id.hashCode.abs() % 10`.
  static const List<int> coverPalette = [
    0xFF7A2E2B,
    0xFF2F4A3A,
    0xFFB5733A,
    0xFF4B3426,
    0xFF22344C,
    0xFF8E4B2A,
    0xFF5A5F3A,
    0xFF6B3A52,
    0xFF3D5A5E,
    0xFF9A6B2F,
  ];
}

/// The spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64.
///
/// Screen horizontal margin is 16, card padding 18 (20 for heroes), list
/// gaps 12, section gaps 24, and scrollables keep a 96px bottom inset so
/// content never hides under the navigation bar.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double xxxxl = 48;

  /// Fixed layout values from the design spec.
  static const double screenMargin = 16;
  static const double cardPadding = 18;
  static const double heroCardPadding = 20;
  static const double listGap = 12;
  static const double sectionGap = 24;

  /// Bottom inset for floating glass dock + safe area.
  static const double scrollBottomInset = 108;
}

/// The motion vocabulary: five durations and three curves. Motion is a
/// whisper — 90–480ms, never springy beyond [AppMotion.instant] press
/// feedback.
class AppMotion {
  AppMotion._();

  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 320);
  static const hero = Duration(milliseconds: 480);
  static const tabFade = Duration(milliseconds: 200);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasis = Curves.easeInOutCubic;
  static const Curve press = Curves.easeOutBack;

  // Springs: physical, slightly bouncy. Use the [SpringDescription]s with
  // `SpringSimulation`, or the [Curve]s anywhere a duration-based
  // animation is needed.

  /// Press-down / release on buttons and cards: quick, barely overshoots.
  static const SpringDescription pressSpring =
      SpringDescription(mass: 1, stiffness: 520, damping: 26);

  /// Entrances and morphs (dock pill, sheets): a touch more bounce.
  static const SpringDescription entranceSpring =
      SpringDescription(mass: 1, stiffness: 300, damping: 21);

  /// Spring as a curve for press-release; pair with [pressSettle].
  static const Curve springPress = SpringCurve(pressSpring);

  /// Spring as a curve for entrances and morphs; pair with [entranceSettle].
  static const Curve springEntrance = SpringCurve(entranceSpring);

  static const pressSettle = Duration(milliseconds: 260);
  static const entranceSettle = Duration(milliseconds: 480);
}

/// A [Curve] driven by a damped spring, running 0 → 1 over the animation's
/// duration (it may overshoot 1 on the way).
class SpringCurve extends Curve {
  const SpringCurve(this.description, {this.settle = 0.5});

  final SpringDescription description;

  /// Seconds of simulation that `t == 1` maps to.
  final double settle;

  @override
  double transformInternal(double t) =>
      SpringSimulation(description, 0, 1, 0).x(t * settle);
}

/// Liquid-glass tokens: translucent fills, hairline borders, blur sigmas
/// and a top-left highlight. Getters follow [AppColors.isDark]; the
/// `*For(dark)` forms are for theme construction.
class AppGlass {
  AppGlass._();

  /// Blur for chrome (app bar, dock, sheets) and for hero panels.
  static const double blurChrome = 24;

  /// Blur for single glass cards outside scrolling lists.
  static const double blurCard = 16;

  static Color cardFillFor(bool dark) => dark
      ? const Color(0xFF2B1D14).withValues(alpha: 0.74)
      : const Color(0xFFFFF4E2).withValues(alpha: 0.82);

  static Color chromeFillFor(bool dark) => dark
      ? const Color(0xFF1B110B).withValues(alpha: 0.88)
      : const Color(0xFFFFEDD2).withValues(alpha: 0.94);

  static Color borderFor(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.18)
      : const Color(0xFF4A2410).withValues(alpha: 0.22);

  /// Bright rim light on the top/left edge.
  static Color rimFor(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.22)
      : Colors.white.withValues(alpha: 0.95);

  static Color shadowFor(bool dark) => dark
      ? Colors.black.withValues(alpha: 0.38)
      : const Color(0xFF4A2410).withValues(alpha: 0.16);

  /// Translucent card fill (frosted cards, chips, inputs).
  static Color get cardFill => cardFillFor(AppColors.isDark);

  /// Stronger fill for chrome that sits over moving content.
  static Color get chromeFill => chromeFillFor(AppColors.isDark);

  /// Hairline outline.
  static Color get border => borderFor(AppColors.isDark);

  /// Top-left rim highlight colour.
  static Color get rim => rimFor(AppColors.isDark);

  static Color get shadow => shadowFor(AppColors.isDark);

  /// Diagonal sheen painted over a glass surface: bright at the top-left
  /// corner, gone by the middle.
  static Gradient get highlight => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 0.45],
        colors: [
          Colors.white.withValues(alpha: AppColors.isDark ? 0.12 : 0.55),
          Colors.white.withValues(alpha: 0),
        ],
      );

  /// Soft shadow under glass: a tinted ambient drop plus a tight contact.
  static List<BoxShadow> get shadows => [
        BoxShadow(
          color: shadow,
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.25 : 0.04),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];
}

/// The sky behind the app: dusk amber deepening to brown in light mode, a
/// midnight sky with stars in dark mode, with
/// soft copper glows. A desert scene is painted over it (see glass.dart).
class AppAurora {
  AppAurora._();

  static const List<Color> light = [
    Color(0x66FFE3B8), // cream glow 40%
    Color(0x40C2703A), // copper 25%
    Color(0x33FFC58A), // peach 20%
    Color(0x2E8A4A2B), // rust 18%
  ];

  static const List<Color> dark = [
    Color(0x335B6BD6),
    Color(0x2E4A3B8C),
    Color(0x29B8703A),
    Color(0x1F2B3A6B),
  ];

  static List<Color> get colors => AppColors.isDark ? dark : light;

  /// Canvas colour the blobs float over.
  static Color get base => AppColors.isDark
      ? const Color(0xFF1A1832)
      : const Color(0xFFE3A872);

  /// Top-to-bottom sky gradient stops.
  static List<Color> get sky => AppColors.isDark
      ? const [Color(0xFF0C1124), Color(0xFF1A1832), Color(0xFF2C1C28)]
      : const [Color(0xFFF0C99C), Color(0xFFE3A872), Color(0xFFC98350)];
}

/// The M3 corner scale: extra-small 8, small 12, medium 16, large 20,
/// extra-large 28, full (stadium).
class AppRadii {
  AppRadii._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const card = 24.0;
  static const xl = 28.0;
  static const full = 999.0;
}

/// Elevation shadows tuned to the M3 key-light model: a tight key shadow
/// plus a wide ambient one. Tinted variants keep the option of a coloured
/// bloom for featured surfaces.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get raised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  /// Two-part coloured shadow: a soft neutral drop plus a tinted bloom in
  /// the card's own hue. This is what makes surfaces read as layered.
  static List<BoxShadow> layered(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.14),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ];

  /// Porcelain card shadow (blur 24, spread -4, y 8).
  static List<BoxShadow> get ambient => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Brand gradients — only two, per the design spec (§3.7): `hero` for
/// the single hero panel a screen may have, `brand` for the mark and
/// avatars. Everything else in the app is flat.
class AppGradients {
  AppGradients._();

  /// Mark/avatar gradient: primary → vivid lift, 135°.
  static Gradient get brand => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0A050), Color(0xFFB8702C)],
      );

  /// Depth hero: glowing amber in dark mode (dark text on it), deep brown
  /// in light mode (cream text on it), at 135 degrees.
  static Gradient get hero => AppColors.isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0B070), Color(0xFFC27A2C)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A4020), Color(0xFF4A2410)],
        );

  /// Legacy name kept so existing call sites restyle onto `hero`; the
  /// aurora/mint/panel family was retired into it (§3.7).
  static Gradient get aurora => hero;

  /// Retired: mint heroes are now flat success-container panels.
  static Gradient get mint => const LinearGradient(
        colors: [Color(0xFFD8F0DE), Color(0xFFD8F0DE)],
      );

  /// Retired: dark panels are now a flat surface step.
  static const Gradient panel = LinearGradient(
    colors: [Color(0xFF1C2026), Color(0xFF1C2026)],
  );

  static Gradient tint(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
      );

  static LinearGradient cover(int baseColor) {
    final base = Color(baseColor);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(const Color(0x2EFFFFFF), base),
        base,
        Color.alphaBlend(const Color(0x26000000), base),
      ],
    );
  }
}

/// Material 3 type ramp: Fraunces (serif) for display headings, Plus
/// Jakarta Sans for everything else.
/// Display/title roles use tight negative tracking, body and label sit
/// neutral, per modern iOS/Android best practices.
class AppText {
  AppText._();

  /// Named display steps from the type scale: 58 for single hero
  /// numbers, 40 for confirmation headlines, 34 for seat-label heroes.
  static const double displayXl = 58;
  static const double displayLg = 40;
  static const double displayMd = 34;

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    double ls = -0.5,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height ?? 1.15,
      );

  static TextStyle title(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = -0.4,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height ?? 1.25,
      );

  static TextStyle body(
    double size, {
    FontWeight w = FontWeight.w400,
    double ls = 0,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height ?? 1.45,
      );

  static TextStyle label(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = 0.1,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textSecondary,
      );

  /// The small uppercase section headers used above lists.
  static TextStyle overline(
    double size, {
    FontWeight w = FontWeight.w700,
    double ls = 1.2,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textFaint,
      );
}

/// No overscroll glow / stretch — calmer scroll on Android.
class NordicScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? AppColors._darkScheme
        : AppColors._lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppGlass.chromeFillFor(dark),
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.title(17, w: FontWeight.w600),
        iconTheme: const IconThemeData(size: 22),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppGlass.cardFillFor(dark),
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppGlass.cardFillFor(dark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppText.body(14.5, color: scheme.onSurfaceVariant),
        labelStyle: AppText.body(13.5, color: scheme.onSurfaceVariant),
        floatingLabelStyle:
            AppText.body(13, w: FontWeight.w600, color: scheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: AppGlass.borderFor(dark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: AppGlass.borderFor(dark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: AppText.title(15, w: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: AppText.title(15, w: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          side: BorderSide(color: scheme.outline, width: 1.2),
          shape: const StadiumBorder(),
          textStyle: AppText.title(15, w: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppText.title(14, w: FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: AppText.title(15, w: FontWeight.w600),
        subtitleTextStyle: AppText.body(13, color: scheme.onSurfaceVariant),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (dark ? scheme.onSurfaceVariant : Colors.white),
        ),
        thumbIcon: const WidgetStatePropertyAll<Icon?>(null),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : (dark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFF0F172A).withValues(alpha: 0.16)),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outlineVariant,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppGlass.cardFillFor(dark),
        selectedColor: scheme.secondaryContainer,
        labelStyle: AppText.label(13, color: scheme.onSurfaceVariant),
        secondaryLabelStyle:
            AppText.label(13, color: scheme.onSecondaryContainer),
        side: BorderSide(color: AppGlass.borderFor(dark)),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface.withValues(alpha: 0.92),
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(
            color: Colors.white.withValues(alpha: dark ? 0.0 : 0.12),
          ),
        ),
        contentTextStyle:
            AppText.body(13.5, color: scheme.onInverseSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow.withValues(alpha: 0.94),
        modalBackgroundColor:
            scheme.surfaceContainerLow.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: AppGlass.borderFor(dark)),
        ),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.label(
            11.5,
            w: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: _SoftPageTransitionsBuilder(),
          TargetPlatform.windows: _SoftPageTransitionsBuilder(),
          TargetPlatform.macOS: _SoftPageTransitionsBuilder(),
          TargetPlatform.linux: _SoftPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
