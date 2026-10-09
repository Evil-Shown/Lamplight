import 'package:flutter/material.dart';
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

  /// Nordic light: sapphire, porcelain canvas, amber accent.
  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF0D50E8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCE8FF),
    onPrimaryContainer: Color(0xFF062A6E),
    secondary: Color(0xFF4F46E5),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE8E7FF),
    onSecondaryContainer: Color(0xFF1E1B4B),
    tertiary: Color(0xFFF59E0B),
    onTertiary: Color(0xFF1C1917),
    tertiaryContainer: Color(0xFFFFEDD5),
    onTertiaryContainer: Color(0xFF431407),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFF9CA3AF),
    outlineVariant: Color(0xFFE5E7EB),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFF93B8FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
    surfaceDim: Color(0xFFE2E8F0),
    surfaceBright: Color(0xFFF8FAFC),
  );

  /// Nordic dark: slate canvas, light sapphire primary.
  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF93B8FF),
    onPrimary: Color(0xFF062A6E),
    primaryContainer: Color(0xFF0D50E8),
    onPrimaryContainer: Color(0xFFDCE8FF),
    secondary: Color(0xFFA5B4FC),
    onSecondary: Color(0xFF1E1B4B),
    secondaryContainer: Color(0xFF3730A3),
    onSecondaryContainer: Color(0xFFE8E7FF),
    tertiary: Color(0xFFFBBF24),
    onTertiary: Color(0xFF431407),
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFFEDD5),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF334155),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFF0D50E8),
    surfaceContainerLowest: Color(0xFF020617),
    surfaceContainerLow: Color(0xFF1E293B),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHigh: Color(0xFF334155),
    surfaceContainerHighest: Color(0xFF475569),
    surfaceDim: Color(0xFF0F172A),
    surfaceBright: Color(0xFF334155),
  );

  /// Electric indigo — selected seats, nav pill, focus rings.
  static const Color indigo = Color(0xFF4F46E5);

  /// Warm amber — “yours / top pick / hold ready” only.
  static const Color amberHighlight = Color(0xFFF59E0B);

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
      isDark ? const Color(0xFFF2BC4C) : const Color(0xFF8A5A00);
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
  static Color get neutralSoft => scheme.surfaceContainerHigh;  // Seat map — aliases per spec §3.1 (yours = primary, selected = rust).
  static Color get seatAvailable => success;
  static Color get seatLimited => warning;
  static Color get seatOccupied => error;
  static Color get seatSelected => indigo;
  static Color get seatYours => primary;

  /// ARGB values, so they line up with `Book.coverColor`. Deterministic:
  /// index = `book.id.hashCode.abs() % 10`.
  static const List<int> coverPalette = [
    0xFF1E40AF,
    0xFF0E7490,
    0xFFB45309,
    0xFF9D174D,
    0xFF5B21B6,
    0xFF155E75,
    0xFF166534,
    0xFF7C2D12,
    0xFF831843,
    0xFF1E3A8A,
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
        colors: [Color(0xFF0D50E8), Color(0xFF4F46E5)],
      );

  /// Depth hero: sapphire → indigo at 135°.
  static Gradient get hero => AppColors.isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D50E8), Color(0xFF312E81)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D50E8), Color(0xFF4F46E5)],
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

/// Material 3 type ramp on Plus Jakarta Sans.
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
      GoogleFonts.plusJakartaSans(
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
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: AppText.title(17, w: FontWeight.w600),
        iconTheme: const IconThemeData(size: 22),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppText.body(14.5, color: scheme.onSurfaceVariant),
        labelStyle: AppText.body(13.5, color: scheme.onSurfaceVariant),
        floatingLabelStyle:
            AppText.body(13, w: FontWeight.w600, color: scheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
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
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
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
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        labelStyle: AppText.label(13, color: scheme.onSurfaceVariant),
        secondaryLabelStyle:
            AppText.label(13, color: scheme.onSecondaryContainer),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        contentTextStyle:
            AppText.body(13.5, color: scheme.onInverseSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
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
