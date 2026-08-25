import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────
///  "The Ledger" design system — see UI-mockup.md for the full spec.
///  Warm ivory paper · deep ink navy · foil gold · serif + archive mono.
/// ─────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Paper world
  static const paper = Color(0xFFF2EDE2);
  static const paperCard = Color(0xFFFBF8F0);
  static const paperDeep = Color(0xFFE9E2D2);

  // Ink world
  static const ink = Color(0xFF1B2334);
  static const inkDeep = Color(0xFF141A28);
  static const inkSoft = Color(0xFF2A3450);

  // Foil gold
  static const gold = Color(0xFFC9A24B);
  static const goldDeep = Color(0xFFA9832F);
  static const goldSoft = Color(0xFFE7D9B8);

  // Text
  static const textPrimary = Color(0xFF20242E);
  static const textSecondary = Color(0xFF6E6A5E);
  static const textFaint = Color(0xFF9A9483);
  static const textOnDark = Color(0xFFF2EDE2);

  // Lines
  static const line = Color(0xFFE2DAC6);
  static const lineStrong = Color(0xFFD2C8AE);

  // Ink stamps (semantic)
  static const stampGreen = Color(0xFF3E7C5B);
  static const stampGold = Color(0xFFB98A2F);
  static const stampRed = Color(0xFFB54B42);

  // Compatibility aliases (legacy call sites)
  static const primary = ink;
  static const primaryLight = inkSoft;
  static const secondary = goldDeep;
  static const accent = gold;
  static const accentSoft = goldSoft;
  static const surface = paper;
  static const surfaceCard = paperCard;
  static const surfaceDark = ink;
  static const border = line;
  static const borderStrong = lineStrong;
  static const success = stampGreen;
  static const warning = stampGold;
  static const error = stampRed;
  static const info = Color(0xFF4A6B8A);
  static const infoSoft = Color(0xFFE5EBEF);
  static const unavailable = textFaint;
  static const warningSoft = Color(0xFFF6ECD4);
  static const errorSoft = Color(0xFFF3E2DE);
  static const cream = paperDeep;

  // Seat states
  static const seatAvailable = stampGreen;
  static const seatOccupied = Color(0xFFC4574E);
  static const seatReserved = Color(0xFFC9962E);

  // Cover palette (fallback art — ink-family + jewel tones on paper)
  static const coverPalette = [
    Color(0xFF1B2334),
    Color(0xFF3E5C50),
    Color(0xFF7A3B2E),
    Color(0xFF2F4159),
    Color(0xFF5C4A72),
    Color(0xFF8A6A2F),
    Color(0xFF243B4A),
    Color(0xFF4A3350),
  ];
}

class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const full = 999.0;
}

class AppShadows {
  AppShadows._();

  /// Whisper shadow for paper cards.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF1B2334).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Deeper shadow for raised paper cards.
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: const Color(0xFF1B2334).withValues(alpha: 0.10),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  /// Deep drop shadow for ink-world surfaces (hero, member card, nav).
  static List<BoxShadow> get ink => [
        BoxShadow(
          color: const Color(0xFF141A28).withValues(alpha: 0.35),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  /// Gold glow for foil elements.
  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.30),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];
}

class AppGradients {
  AppGradients._();

  /// Ink-world surface gradient (hero ledger, member card, best match).
  static const ledger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF232C44), AppColors.inkDeep],
  );

  /// Foil gold (chip, emblem, gold icons on ink).
  static const foil = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3C77E), AppColors.gold, AppColors.goldDeep],
  );

  static Gradient tint(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.05)],
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

/// The three typographic voices of the ledger (UI-mockup.md §3).
class AppText {
  AppText._();

  /// Display serif — headlines, greetings, book titles.
  static TextStyle serif(
    double size, {
    FontWeight w = FontWeight.w700,
    double ls = -0.5,
    Color? color,
    bool italic = false,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textPrimary,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: height,
      );

  /// Archive mono — eyebrows, stamps, meta. Always pass uppercase strings.
  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w600,
    double ls = 2.4,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? AppColors.textFaint,
      );

  /// Workhorse sans — body, subtitles, buttons, nav labels.
  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w500,
    double ls = 0,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        height: height,
        color: color ?? AppColors.textPrimary,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.goldDeep,
      onSecondary: AppColors.paper,
      surface: AppColors.paper,
      onSurface: AppColors.textPrimary,
      error: AppColors.stampRed,
      onError: AppColors.paper,
    );

    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.serif(23, w: FontWeight.w700),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paperCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppText.sans(14.5, color: AppColors.textFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.goldDeep, width: 1.6),
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppText.sans(15, w: FontWeight.w700, ls: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.lineStrong, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppText.sans(15, w: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldDeep,
          textStyle: AppText.sans(14, w: FontWeight.w700),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: AppText.sans(14.5, w: FontWeight.w600),
        subtitleTextStyle:
            AppText.sans(12.5, color: AppColors.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.paper : AppColors.textFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.stampGreen
              : AppColors.paperDeep,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.line,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentTextStyle: AppText.sans(13.5, w: FontWeight.w600, color: AppColors.paper),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paperCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.goldDeep),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LedgerPageTransitionsBuilder(),
          TargetPlatform.iOS: _LedgerPageTransitionsBuilder(),
          TargetPlatform.windows: _LedgerPageTransitionsBuilder(),
          TargetPlatform.macOS: _LedgerPageTransitionsBuilder(),
          TargetPlatform.linux: _LedgerPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Fade + gentle rise, in the spirit of React Bits' BlurFade (UI-mockup.md §7.1).
class _LedgerPageTransitionsBuilder extends PageTransitionsBuilder {
  const _LedgerPageTransitionsBuilder();

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
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
