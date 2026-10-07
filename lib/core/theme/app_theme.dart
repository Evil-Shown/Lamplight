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

  // Surfaces - Warm Academic Editorial (Stone/Cream paper undertone in light, Deep Midnight Ink in dark)
  static Color get background =>
      isDark ? const Color(0xFF0F141C) : const Color(0xFFF9F8F5);
  static Color get surface =>
      isDark ? const Color(0xFF161D27) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF1E2734) : const Color(0xFFF2EFE9);
  static Color get surfaceSunken =>
      isDark ? const Color(0xFF131822) : const Color(0xFFEBE6DC);

  // Brand - Deep Scholarly Indigo / Oxford Navy
  static Color get primary =>
      isDark ? const Color(0xFF6B92E5) : const Color(0xFF1D3557);
  static Color get primaryDark =>
      isDark ? const Color(0xFFB0CBFF) : const Color(0xFF10223B);
  static Color get primarySoft =>
      isDark ? const Color(0xFF192538) : const Color(0xFFEBF1FA);
  static Color get primaryBright =>
      isDark ? const Color(0xFF7CA3F8) : const Color(0xFF284B78);
  static Color get primaryLift =>
      isDark ? const Color(0xFF9DBDFF) : const Color(0xFF457B9D);

  // Accents - Warm Terracotta, Antique Gold, Soft Sage
  static Color get accent =>
      isDark ? const Color(0xFFE07A5F) : const Color(0xFFC85A32);
  static Color get accentSoft =>
      isDark ? const Color(0xFF35201A) : const Color(0xFFFBF0EB);
  static Color get cyan =>
      isDark ? const Color(0xFF5BA4A4) : const Color(0xFF3D7D7D);
  static Color get cyanSoft =>
      isDark ? const Color(0xFF152A2A) : const Color(0xFFE6F2F2);
  static Color get gold =>
      isDark ? const Color(0xFFDE9B35) : const Color(0xFFB87D18);
  static Color get goldSoft =>
      isDark ? const Color(0xFF33250E) : const Color(0xFFFDF5E6);

  // Text - Charcoal & Editorial Ink
  static Color get textPrimary =>
      isDark ? const Color(0xFFF0F3F8) : const Color(0xFF181E24);
  static Color get textSecondary =>
      isDark ? const Color(0xFF9EABB9) : const Color(0xFF5A6675);
  static Color get textFaint =>
      isDark ? const Color(0xFF677587) : const Color(0xFF8F9BA8);
  static Color get textInverse => const Color(0xFFFFFFFF);

  // Lines - Soft warm hairline borders
  static Color get border =>
      isDark ? const Color(0xFF263242) : const Color(0xFFE8E3DA);
  static Color get borderStrong =>
      isDark ? const Color(0xFF3B4A5D) : const Color(0xFFD4CDC0);

  // Status - Refined Natural Sage, Amber, Brick Red
  static Color get success =>
      isDark ? const Color(0xFF4EAE7B) : const Color(0xFF2D7A51);
  static Color get successSoft =>
      isDark ? const Color(0xFF142D20) : const Color(0xFFEBF6F0);
  static Color get warning =>
      isDark ? const Color(0xFFE59834) : const Color(0xFFC07314);
  static Color get warningSoft =>
      isDark ? const Color(0xFF33220C) : const Color(0xFFFEF6E8);
  static Color get error =>
      isDark ? const Color(0xFFE85D5D) : const Color(0xFFC53030);
  static Color get errorSoft =>
      isDark ? const Color(0xFF361818) : const Color(0xFFFDEEEC);
  static Color get info => primary;
  static Color get infoSoft => primarySoft;
  static Color get neutral =>
      isDark ? const Color(0xFF8695A6) : const Color(0xFF677584);
  static Color get neutralSoft =>
      isDark ? const Color(0xFF1F2936) : const Color(0xFFF0EDE6);

  // Seat map
  static Color get seatAvailable => success;
  static Color get seatLimited => warning;
  static Color get seatOccupied => error;
  static Color get seatSelected => accent;

  /// ARGB values, so they line up with `Book.coverColor`.
  static const List<int> coverPalette = [
    0xFF1D3557,
    0xFF2A5B5B,
    0xFF8D3B2A,
    0xFFB06F17,
    0xFF4A3E72,
    0xFF1F4E5B,
    0xFF7C3626,
    0xFF3B5E34,
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
          color: const Color(0xFF1B1A17).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get raised => [
        BoxShadow(
          color: const Color(0xFF1B1A17).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: const Color(0xFF1B1A17).withValues(alpha: 0.04),
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
          color: const Color(0xFF1B1A17).withValues(alpha: 0.04),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ];

  /// Soft ambient bloom, for primary actions and selected states.
  static List<BoxShadow> glow(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.15),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get primary => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF23426A), Color(0xFF1D3557), Color(0xFF132238)],
  );

  static const hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xF0182230), Color(0xFA0F1620)],
  );

  /// The signature scholarly sweep: deep navy through warm terracotta and gold
  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D3557), Color(0xFF284B78), Color(0xFFC85A32)],
  );

  static const auroraSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEBF1FA), Color(0xFFFBF0EB)],
  );

  static const mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4EAE7B), Color(0xFF2D7A51)],
  );

  /// Deep panel used behind stats and staff surfaces.
  static const panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2A3A), Color(0xFF111722)],
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

/// Editorial Academic typography: Serif display & titles (Newsreader) paired with
/// ultra-crisp humanist sans (Inter) for functional text and UI controls.
class AppText {
  AppText._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    double ls = -0.4,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.newsreader(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        height: height ?? 1.15,
      );

  static TextStyle title(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = -0.2,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.newsreader(
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

  /// The small uppercase section headers used above lists.
  static TextStyle overline(
    double size, {
    FontWeight w = FontWeight.w700,
    double ls = 1.2,
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
