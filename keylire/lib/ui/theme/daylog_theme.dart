import 'package:flutter/material.dart';

/// KEYLIRE — ink on bone.
///
/// A printed almanac, not a dashboard. Cool bone paper, graphite ink, and
/// the day arc rendered in desaturated printer's inks rather than screen
/// neons. One typeface for words (Instrument Sans), one for numbers
/// (IBM Plex Mono, tabular). No shadows, no card chrome, no eyebrows.
/// Hue appears in the ribbon, key names, the ring, and the focused underline.
class DlColors {
  // Light
  static const paper = Color(0xFFF1F1EE);
  static const surface = Color(0xFFF7F7F5);
  static const surfaceElevated = Color(0xFFE9E9E5);
  static const ink = Color(0xFF1C1C1E);
  static const inkSoft = Color(0xFF5C5C60);
  static const inkFaint = Color(0xFF9A9A9E);
  static const line = Color(0xFFDCDCD7);

  // Dark
  static const paperDark = Color(0xFF111214);
  static const surfaceDark = Color(0xFF17181B);
  static const surfaceElevatedDark = Color(0xFF212226);
  static const inkDark = Color(0xFFE9E9E4);
  static const inkSoftDark = Color(0xFF9C9C98);
  static const inkFaintDark = Color(0xFF63636A);
  static const lineDark = Color(0xFF2A2B30);

  // The arc, as inks
  static const night = Color(0xFF4B5B85); // slate
  static const dawn = Color(0xFFB98A2E); // ochre
  static const daylight = Color(0xFF2E7A85); // teal
  static const dusk = Color(0xFF7A4F78); // plum

  static const danger = Color(0xFFB4433A);

  /// Intentionally empty. Kept so old call sites compile.
  static List<BoxShadow> cardShadow(Brightness b) => const [];
}

/// Hue of a moment; fraction = minute-of-day / 1440, local time.
Color arcColor(double fraction) {
  const stops = <double>[0.0, 6 / 24, 12 / 24, 18 / 24, 1.0];
  const hues = <Color>[
    DlColors.night, DlColors.dawn, DlColors.daylight, DlColors.dusk, DlColors.night
  ];
  final f = fraction.clamp(0.0, 1.0);
  for (var i = 0; i < stops.length - 1; i++) {
    if (f <= stops[i + 1]) {
      final t = (f - stops[i]) / (stops[i + 1] - stops[i]);
      return Color.lerp(hues[i], hues[i + 1], t)!;
    }
  }
  return DlColors.night;
}

Color arcColorFor(DateTime local) =>
    arcColor((local.hour * 60 + local.minute) / 1440.0);

Color arcColorOfMinute(int minute) => arcColor((minute % 1440) / 1440.0);

/// Responsive 4pt scale. compact (<360dp) / regular / roomy (>430dp).
class Dl {
  Dl._(this.unit);
  final double unit;

  factory Dl.of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return Dl._(3.5);
    if (w > 430) return Dl._(4.5);
    return Dl._(4.0);
  }

  double get x1 => unit;
  double get x2 => unit * 2;
  double get x3 => unit * 3;
  double get x4 => unit * 4;
  double get x5 => unit * 5;
  double get x6 => unit * 6;
  double get x8 => unit * 8;
  double get x10 => unit * 10;

  static const double radius = 12;
  static const double radiusSmall = 8;
  static const double radiusPill = 999;
  static const double tapMin = 48;
}

class DlType {
  static TextTheme textTheme(Brightness b) {
    final ink = b == Brightness.dark ? DlColors.inkDark : DlColors.ink;
    final soft = b == Brightness.dark ? DlColors.inkSoftDark : DlColors.inkSoft;
    TextStyle sans(double size, FontWeight w, {Color? color, double? height, double spacing = 0}) =>
        TextStyle(
            fontFamily: 'InstrumentSans',
            fontSize: size,
            fontWeight: w,
            color: color ?? ink,
            height: height,
            letterSpacing: spacing);

    return TextTheme(
      displayLarge: sans(40, FontWeight.w600, height: 1.05, spacing: -1.0),
      displaySmall: sans(28, FontWeight.w600, height: 1.1, spacing: -0.6),
      headlineMedium: sans(22, FontWeight.w600, spacing: -0.3),
      titleLarge: sans(18, FontWeight.w600, spacing: -0.2),
      titleSmall: sans(13, FontWeight.w600, color: soft),
      bodyLarge: sans(16, FontWeight.w400, height: 1.4),
      bodyMedium: sans(14.5, FontWeight.w400, height: 1.45),
      bodySmall: sans(12.5, FontWeight.w400, color: soft, height: 1.35),
      labelLarge: sans(14, FontWeight.w600),
      labelSmall: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: soft,
      ),
    );
  }

  static TextStyle mono(BuildContext context,
          {double size = 12.5, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: size,
        color: color ??
            (Theme.of(context).brightness == Brightness.dark
                ? DlColors.inkSoftDark
                : DlColors.inkSoft),
        fontWeight: weight ?? FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

ThemeData daylogTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final paper = dark ? DlColors.paperDark : DlColors.paper;
  final surface = dark ? DlColors.surfaceDark : DlColors.surface;
  final elevated = dark ? DlColors.surfaceElevatedDark : DlColors.surfaceElevated;
  final ink = dark ? DlColors.inkDark : DlColors.ink;
  final soft = dark ? DlColors.inkSoftDark : DlColors.inkSoft;
  final line = dark ? DlColors.lineDark : DlColors.line;
  final text = DlType.textTheme(brightness);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: ink,
    onPrimary: paper,
    secondary: DlColors.daylight,
    onSecondary: Colors.white,
    error: DlColors.danger,
    onError: Colors.white,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: soft,
    outline: line,
    surfaceContainerHighest: elevated,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'InstrumentSans',
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
      indicatorColor: elevated,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'InstrumentSans', fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          size: 22, color: s.contains(WidgetState.selected) ? ink : soft)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: elevated,
      selectedColor: ink,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dl.radiusPill)),
      labelStyle: TextStyle(fontFamily: 'InstrumentSans', fontSize: 13.5, fontWeight: FontWeight.w600, color: ink),
      secondaryLabelStyle: TextStyle(fontFamily: 'InstrumentSans', fontSize: 13.5, fontWeight: FontWeight.w600, color: paper),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: UnderlineInputBorder(borderSide: BorderSide(color: line)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: line)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ink, width: 1.5)),
      hintStyle: TextStyle(fontFamily: 'InstrumentSans', color: soft, fontSize: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: paper,
        minimumSize: const Size(Dl.tapMin, Dl.tapMin),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dl.radiusSmall)),
        textStyle: const TextStyle(fontFamily: 'InstrumentSans', fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        textStyle: const TextStyle(fontFamily: 'InstrumentSans', fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? DlColors.surfaceElevatedDark : DlColors.ink,
      contentTextStyle: TextStyle(fontFamily: 'InstrumentSans', color: dark ? DlColors.inkDark : DlColors.paper, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dl.radiusSmall)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dl.radius)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dl.radius)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
  );
}

bool reducedMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;
