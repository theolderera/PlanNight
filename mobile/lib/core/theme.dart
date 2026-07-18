import 'package:flutter/material.dart';

/// -----------------------------------------------------------------------------
/// PlanNight design system — "Daylight" (light) / "Nocturne" (dark).
///
/// A warm-paper canvas, white surfaces, a cobalt accent, deep-navy hero cards,
/// a gold streak, and two typefaces: Plus Jakarta Sans for the UI and Space
/// Grotesk for numbers/times. Colours that don't fit Material's ColorScheme
/// live on [AppColors], read at call sites via `context.colors`.
/// -----------------------------------------------------------------------------

/// Font family constants — bundled variable fonts (see pubspec `fonts:`).
class AppFonts {
  const AppFonts._();
  static const sans = 'PlusJakartaSans';
  static const mono = 'SpaceGrotesk'; // numeric / time / stat accent
}

/// Brand tokens that Material's [ColorScheme] has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.surfaceAlt,
    required this.navy,
    required this.onNavy,
    required this.onNavyMuted,
    required this.navyRingTrack,
    required this.navyRingFill,
    required this.ink,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.divider,
    required this.trackBg,
    required this.accent,
    required this.accentTint,
    required this.success,
    required this.streakStart,
    required this.streakEnd,
    required this.amber,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.shadow,
  });

  final Color paper; // scaffold background (warm paper)
  final Color surface; // card / sheet
  final Color surfaceAlt; // faint fill: inactive segment, tinted tile
  final Color navy; // deep hero cards (progress, plan summary, avatar, logo)
  final Color onNavy; // primary text on navy
  final Color onNavyMuted; // secondary text on navy
  final Color navyRingTrack; // progress-ring track on navy
  final Color navyRingFill; // progress-ring fill on navy
  final Color ink; // primary text
  final Color textSecondary; // secondary text
  final Color textMuted; // tertiary text
  final Color textFaint; // faint / disabled text
  final Color border; // hairline borders (checkbox, chip)
  final Color divider; // list dividers
  final Color trackBg; // segmented-control track, bar-chart track
  final Color accent; // cobalt primary
  final Color accentTint; // cobalt wash (selected chip, ghost button)
  final Color success; // completed / good day
  final Color streakStart; // streak card gradient (top)
  final Color streakEnd; // streak card gradient (bottom)
  final Color amber; // partial day
  final Color danger; // destructive (logout)
  final Color dangerBg;
  final Color dangerBorder;
  final Color shadow; // card drop shadow base

  /// Preset category dot colours — align with the design's swatches. The user
  /// still picks per-category hex; this is the fallback/new-category palette.
  static const categoryPalette = <Color>[
    Color(0xFF5B6CFF), Color(0xFF22C55E), Color(0xFFF472B6), Color(0xFFFBBF24),
    Color(0xFF60A5FA), Color(0xFFA78BFA), Color(0xFF14B8A6), Color(0xFFF97316),
    Color(0xFFEF4444), Color(0xFF84CC16),
  ];

  static const light = AppColors(
    paper: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF4F2EC),
    navy: Color(0xFF1E2A56),
    onNavy: Color(0xFFFFFFFF),
    onNavyMuted: Color(0x9EFFFFFF),
    navyRingTrack: Color(0x26FFFFFF),
    navyRingFill: Color(0xFF7AA2FF),
    ink: Color(0xFF1A1D24),
    textSecondary: Color(0xFF8A8577),
    textMuted: Color(0xFFA39D90),
    textFaint: Color(0xFFC9C3B6),
    border: Color(0xFFD8D3C7),
    divider: Color(0xFFF0EDE5),
    trackBg: Color(0xFFEAE6DE),
    accent: Color(0xFF5B6CFF),
    accentTint: Color(0xFFEEF0FF),
    success: Color(0xFF22C55E),
    streakStart: Color(0xFFFF9A3D),
    streakEnd: Color(0xFFF97316),
    amber: Color(0xFFFBBF24),
    danger: Color(0xFFE0524F),
    dangerBg: Color(0xFFFFF5F5),
    dangerBorder: Color(0xFFFDE0E0),
    shadow: Color(0x141A1D24),
  );

  static const dark = AppColors(
    paper: Color(0xFF0F1119),
    surface: Color(0xFF191E2B),
    surfaceAlt: Color(0xFF242A3A),
    navy: Color(0xFF1A2338),
    onNavy: Color(0xFFF2F5FB),
    onNavyMuted: Color(0x99F2F5FB),
    navyRingTrack: Color(0x1FFFFFFF),
    navyRingFill: Color(0xFF7AA2FF),
    ink: Color(0xFFF2F5FB),
    textSecondary: Color(0xFF7A869E),
    textMuted: Color(0xFF6B7890),
    textFaint: Color(0xFF556080),
    border: Color(0xFF2B3346),
    divider: Color(0xFF232A3A),
    trackBg: Color(0xFF242A3A),
    accent: Color(0xFF6D7CFF),
    accentTint: Color(0xFF3D4574),
    success: Color(0xFF22C55E),
    streakStart: Color(0xFFFF9A3D),
    streakEnd: Color(0xFFF97316),
    amber: Color(0xFFFBBF24),
    danger: Color(0xFFF0716E),
    dangerBg: Color(0x1FF0716E),
    dangerBorder: Color(0x4DF0716E),
    shadow: Color(0x33000000),
  );

  @override
  AppColors copyWith({
    Color? paper, Color? surface, Color? surfaceAlt, Color? navy, Color? onNavy,
    Color? onNavyMuted, Color? navyRingTrack, Color? navyRingFill, Color? ink,
    Color? textSecondary, Color? textMuted, Color? textFaint, Color? border,
    Color? divider, Color? trackBg, Color? accent, Color? accentTint,
    Color? success, Color? streakStart, Color? streakEnd, Color? amber,
    Color? danger, Color? dangerBg, Color? dangerBorder, Color? shadow,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      navy: navy ?? this.navy,
      onNavy: onNavy ?? this.onNavy,
      onNavyMuted: onNavyMuted ?? this.onNavyMuted,
      navyRingTrack: navyRingTrack ?? this.navyRingTrack,
      navyRingFill: navyRingFill ?? this.navyRingFill,
      ink: ink ?? this.ink,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      trackBg: trackBg ?? this.trackBg,
      accent: accent ?? this.accent,
      accentTint: accentTint ?? this.accentTint,
      success: success ?? this.success,
      streakStart: streakStart ?? this.streakStart,
      streakEnd: streakEnd ?? this.streakEnd,
      amber: amber ?? this.amber,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      paper: c(paper, other.paper),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      navy: c(navy, other.navy),
      onNavy: c(onNavy, other.onNavy),
      onNavyMuted: c(onNavyMuted, other.onNavyMuted),
      navyRingTrack: c(navyRingTrack, other.navyRingTrack),
      navyRingFill: c(navyRingFill, other.navyRingFill),
      ink: c(ink, other.ink),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      textFaint: c(textFaint, other.textFaint),
      border: c(border, other.border),
      divider: c(divider, other.divider),
      trackBg: c(trackBg, other.trackBg),
      accent: c(accent, other.accent),
      accentTint: c(accentTint, other.accentTint),
      success: c(success, other.success),
      streakStart: c(streakStart, other.streakStart),
      streakEnd: c(streakEnd, other.streakEnd),
      amber: c(amber, other.amber),
      danger: c(danger, other.danger),
      dangerBg: c(dangerBg, other.dangerBg),
      dangerBorder: c(dangerBorder, other.dangerBorder),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// `context.colors.accent` — brand tokens. `context.mono(...)` — a Space Grotesk
/// number/time style.
extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// A Space Grotesk text style for numbers, times and stats.
  TextStyle mono({double size = 14, FontWeight weight = FontWeight.w700, Color? color}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: size,
        fontWeight: weight,
        height: 1.1,
        color: color ?? colors.ink,
      );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      primaryContainer: c.accentTint,
      onPrimaryContainer: c.accent,
      secondary: c.navy,
      onSecondary: c.onNavy,
      secondaryContainer: c.navy,
      onSecondaryContainer: c.onNavy,
      tertiary: c.streakEnd,
      onTertiary: Colors.white,
      error: c.danger,
      onError: Colors.white,
      errorContainer: c.dangerBg,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.textSecondary,
      outline: c.textMuted,
      outlineVariant: c.border,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: c.ink,
      onInverseSurface: c.surface,
      inversePrimary: c.navyRingFill,
      surfaceTint: Colors.transparent,
    );

    final baseText = _textTheme(c.ink, c.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      fontFamily: AppFonts.sans,
      textTheme: baseText,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: c.ink,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        shadowColor: c.shadow,
      ),

      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: c.textMuted, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border.withValues(alpha: brightness == Brightness.dark ? 1 : 0)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans, fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: c.accent.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans, fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: const TextStyle(
          fontFamily: AppFonts.sans, fontSize: 14.5, fontWeight: FontWeight.w700),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? c.accent : c.textMuted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected) ? c.accent : c.textMuted,
            )),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : c.surface),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.accent : c.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineWidth: const WidgetStatePropertyAll(0),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: c.accent,
        inactiveTrackColor: c.trackBg,
        thumbColor: Colors.white,
        overlayColor: c.accent.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        trackShape: const RoundedRectSliderTrackShape(),
        valueIndicatorColor: c.navy,
        valueIndicatorTextStyle: const TextStyle(
            fontFamily: AppFonts.mono, color: Colors.white, fontWeight: FontWeight.w700),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.accentTint,
        side: BorderSide.none,
        labelStyle: TextStyle(
            fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? c.surface : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? c.ink : c.textSecondary),
          textStyle: const WidgetStatePropertyAll(TextStyle(
              fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w700)),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          visualDensity: VisualDensity.compact,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
            fontFamily: AppFonts.sans, fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        dragHandleColor: c.border,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.navy,
        contentTextStyle: TextStyle(
            fontFamily: AppFonts.sans, color: c.onNavy, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: c.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(fontFamily: AppFonts.sans, color: c.ink, fontSize: 14),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        titleTextStyle: TextStyle(
            fontFamily: AppFonts.sans, fontSize: 14.5, fontWeight: FontWeight.w600, color: c.ink),
        subtitleTextStyle: TextStyle(
            fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w500, color: c.textMuted),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        hourMinuteTextStyle: const TextStyle(fontFamily: AppFonts.mono, fontSize: 42, fontWeight: FontWeight.w700),
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color secondary) {
    TextStyle s(double size, FontWeight w, {double h = 1.3, double ls = 0, Color? col}) =>
        TextStyle(fontFamily: AppFonts.sans, fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: col ?? ink);
    return TextTheme(
      displayLarge: s(32, FontWeight.w800, h: 1.05, ls: -0.5),
      displayMedium: s(28, FontWeight.w800, h: 1.05, ls: -0.4),
      displaySmall: s(25, FontWeight.w800, h: 1.05, ls: -0.3),
      headlineMedium: s(22, FontWeight.w800, h: 1.1, ls: -0.2),
      headlineSmall: s(19, FontWeight.w700, h: 1.15),
      titleLarge: s(17, FontWeight.w700),
      titleMedium: s(15, FontWeight.w700),
      titleSmall: s(14, FontWeight.w700),
      bodyLarge: s(15, FontWeight.w500, h: 1.5),
      bodyMedium: s(13.5, FontWeight.w500, h: 1.5),
      bodySmall: s(12, FontWeight.w500, h: 1.4, col: secondary),
      labelLarge: s(13, FontWeight.w700),
      labelMedium: s(11.5, FontWeight.w600, col: secondary),
      labelSmall: s(10.5, FontWeight.w600, col: secondary),
    );
  }

  /// Map the stored theme preference ('light'|'dark'|'system') to a ThemeMode.
  static ThemeMode modeFromString(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
