import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Campus-blue palette. A cool off-white page, white cards, one confident
/// blue, and semantic status colours that stay quiet enough to read as
/// information rather than decoration.
///
/// Every colour resolves through getters so the whole app can flip to a
/// matching dark palette at runtime. Call sites keep the same
/// `AppColors.x` syntax — the only trade-off is that colours can no longer
/// appear inside `const` expressions.
class AppColors {
  AppColors._();

  /// Whether the dark palette is active. Synced by the app root from
  /// [AppState.themeMode] before the frame is built.
  static bool isDark = false;

  // Surfaces
  static Color get background =>
      isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F6FC);
  static Color get surface =>
      isDark ? const Color(0xFF141D31) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF1B2540) : const Color(0xFFF0F3F8);
  static Color get surfaceSunken =>
      isDark ? const Color(0xFF0F1726) : const Color(0xFFEBEFF8);

  // Brand
  static Color get primary =>
      isDark ? const Color(0xFF4C82E8) : const Color(0xFF1A56DB);
  static Color get primaryDark =>
      isDark ? const Color(0xFFA9C6FF) : const Color(0xFF10328C);
  static Color get primarySoft =>
      isDark ? const Color(0xFF1A2A4E) : const Color(0xFFE8EFFD);
  static Color get primaryBright =>
      isDark ? const Color(0xFF6E9EFF) : const Color(0xFF3B7BF6);
  static Color get primaryLift =>
      isDark ? const Color(0xFF8FB4FF) : const Color(0xFF6E9EFF);

  /// Secondary accent used for gradients and highlights.
  static Color get accent =>
      isDark ? const Color(0xFF8B7BF7) : const Color(0xFF6D5BF5);
  static Color get accentSoft =>
      isDark ? const Color(0xFF26224C) : const Color(0xFFEFECFE);
  static Color get cyan =>
      isDark ? const Color(0xFF2CC5DC) : const Color(0xFF12B5CE);
  static Color get cyanSoft =>
      isDark ? const Color(0xFF12333B) : const Color(0xFFE2F7FB);
  static Color get gold =>
      isDark ? const Color(0xFFE5B95E) : const Color(0xFFD9A441);
  static Color get goldSoft =>
      isDark ? const Color(0xFF332A16) : const Color(0xFFFBF2DF);

  // Text
  static Color get textPrimary =>
      isDark ? const Color(0xFFEDF2FB) : const Color(0xFF0C1526);
  static Color get textSecondary =>
      isDark ? const Color(0xFF9BAAC4) : const Color(0xFF56657F);
  static Color get textFaint =>
      isDark ? const Color(0xFF5E6C88) : const Color(0xFF94A3B8);
  static Color get textInverse => const Color(0xFFFFFFFF);

  // Lines
  static Color get border =>
      isDark ? const Color(0xFF24304A) : const Color(0xFFE6EAF4);
  static Color get borderStrong =>
      isDark ? const Color(0xFF354465) : const Color(0xFFCBD5E1);

  // Status
  static Color get success =>
      isDark ? const Color(0xFF34C97B) : const Color(0xFF16A34A);
  static Color get successSoft =>
      isDark ? const Color(0xFF122B1D) : const Color(0xFFE8F8EE);
  static Color get warning =>
      isDark ? const Color(0xFFF0A03C) : const Color(0xFFE8890C);
  static Color get warningSoft =>
      isDark ? const Color(0xFF322310) : const Color(0xFFFEF3E2);
  static Color get error =>
      isDark ? const Color(0xFFF27171) : const Color(0xFFDC2626);
  static Color get errorSoft =>
      isDark ? const Color(0xFF341B1D) : const Color(0xFFFDECEC);
  static Color get info => primary;
  static Color get infoSoft => primarySoft;
  static Color get neutral =>
      isDark ? const Color(0xFF8291AB) : const Color(0xFF64748B);
  static Color get neutralSoft =>
      isDark ? const Color(0xFF1C2538) : const Color(0xFFEFF2F6);

  // Seat map
  static Color get seatAvailable => success;
  static Color get seatLimited => warning;
  static Color get seatOccupied => error;
  static Color get seatSelected => primary;

  /// ARGB values, so they line up with `Book.coverColor`.
  static const List<int> coverPalette = [
    0xFF1E40AF,
    0xFF0E7490,
    0xFF9D174D,
    0xFFB45309,
    0xFF5B21B6,
    0xFF155E75,
    0xFF9A3412,
    0xFF3F6212,
  ];
}

class AppRadii {
  AppRadii._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const full = 999.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF0F1A2E).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get raised => [
        BoxShadow(
          color: const Color(0xFF0C1526).withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF0C1526).withValues(alpha: 0.05),
          blurRadius: 36,
          offset: const Offset(0, 14),
        ),
      ];

  /// Two-part coloured shadow: a soft neutral drop plus a tinted bloom in
  /// the card's own hue. This is what makes surfaces read as layered.
  static List<BoxShadow> layered(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.16),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF0C1526).withValues(alpha: 0.05),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ];

  /// Soft ambient bloom, for primary actions and selected states.
  static List<BoxShadow> glow(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.18),
          blurRadius: 36,
          offset: const Offset(0, 14),
        ),
      ];

  static List<BoxShadow> get primary => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C6BE0), Color(0xFF1A56DB), Color(0xFF123C9E)],
  );

  static const hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xD9101826), Color(0xF5090F1B)],
  );

  /// The signature brand sweep, used on hero cards and primary actions.
  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B7BF6), Color(0xFF1A56DB), Color(0xFF6D5BF5)],
  );

  static const auroraSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8EFFD), Color(0xFFF4F1FE)],
  );

  static const mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
  );

  /// Deep panel used behind stats and the staff surfaces.
  static const panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16234A), Color(0xFF0C1526)],
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

/// One type voice. The prototype uses a single sans-serif family throughout —
/// weight and size carry the hierarchy, not a second typeface.
class AppText {
  AppText._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    double ls = -0.4,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height,
      );

  static TextStyle title(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = -0.2,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height,
      );

  static TextStyle body(
    double size, {
    FontWeight w = FontWeight.w400,
    double ls = 0,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height,
      );

  static TextStyle label(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = 0.2,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textSecondary,
      );

  /// The small uppercase grey section headers used above every list.
  static TextStyle overline(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = 1.1,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textFaint,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.textInverse,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.textInverse,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textInverse,
      outline: AppColors.border,
    );

    final textTheme = GoogleFonts.interTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
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
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppText.body(14.5, color: AppColors.textFaint),
        labelStyle: AppText.body(13.5, color: AppColors.textSecondary),
        floatingLabelStyle:
            AppText.body(13, w: FontWeight.w600, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        prefixIconColor: AppColors.textFaint,
        suffixIconColor: AppColors.textFaint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          textStyle: AppText.title(15, w: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          textStyle: AppText.title(15, w: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppText.title(14, w: FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: AppText.title(15, w: FontWeight.w600),
        subtitleTextStyle: AppText.body(13, color: AppColors.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.textInverse
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(AppColors.textInverse),
        side: BorderSide(color: AppColors.borderStrong, width: 1.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        contentTextStyle: AppText.body(13.5, color: AppColors.textInverse),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: AppColors.primary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textFaint,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.label(
            11.5,
            w: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textFaint,
          ),
        ),
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
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
