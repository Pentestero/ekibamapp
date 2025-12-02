import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppPalette { blueAmber, purplePink, greenTeal, redOrange }

class ThemeController extends ChangeNotifier {
  AppPalette _palette = AppPalette.blueAmber;
  ThemeMode _mode = ThemeMode.light;

  AppPalette get palette => _palette;
  ThemeMode get mode => _mode;

  void setPalette(AppPalette palette) {
    _palette = palette;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  ThemeData get lightTheme => _buildTheme(_palette, Brightness.light);
  ThemeData get darkTheme => _buildTheme(_palette, Brightness.dark);
}

ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
  final seed = switch (palette) {
    AppPalette.blueAmber => const Color(0xFF3A86FF),
    AppPalette.purplePink => const Color(0xFF6D28D9),
    AppPalette.greenTeal => const Color(0xFF2EC4B6),
    AppPalette.redOrange => const Color(0xFFE63946),
  };

  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

  final secondary = switch (palette) {
    AppPalette.blueAmber => const Color(0xFFFFB703),
    AppPalette.purplePink => const Color(0xFFF72585),
    AppPalette.greenTeal => const Color(0xFF14B8A6),
    AppPalette.redOrange => const Color(0xFFFF7F11),
  };
  final tertiary = switch (palette) {
    AppPalette.blueAmber => const Color(0xFF2EC4B6),
    AppPalette.purplePink => const Color(0xFF64DFDF),
    AppPalette.greenTeal => const Color(0xFF80ED99),
    AppPalette.redOrange => const Color(0xFF06D6A0),
  };

  final cs = scheme.copyWith(secondary: secondary, tertiary: tertiary);

  final textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: brightness == Brightness.dark ? cs.onSurface : null,
    displayColor: brightness == Brightness.dark ? cs.onSurface : null,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: textTheme,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 2,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surface,
      indicatorColor: cs.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cs.surface,
      selectedIconTheme: IconThemeData(color: cs.primary),
      selectedLabelTextStyle: TextStyle(color: cs.primary),
      unselectedIconTheme: IconThemeData(color: cs.secondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.secondary,
        foregroundColor: cs.onSecondary,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData get lightTheme {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3A86FF),
    brightness: Brightness.light,
  );

  final vibrant = scheme.copyWith(
    secondary: const Color(0xFFFFB703),
    tertiary: const Color(0xFF2EC4B6),
    surface: const Color(0xFFFDFDFD),
    primaryContainer: const Color(0xFFE3F2FD),
    secondaryContainer: const Color(0xFFFFF3E0),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: vibrant,
    textTheme: GoogleFonts.interTextTheme(),
    scaffoldBackgroundColor: vibrant.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: vibrant.primary,
      foregroundColor: vibrant.onPrimary,
      elevation: 2,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: vibrant.surface,
      indicatorColor: vibrant.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: vibrant.surface,
      selectedIconTheme: IconThemeData(color: vibrant.primary),
      selectedLabelTextStyle: TextStyle(color: vibrant.primary),
      unselectedIconTheme: IconThemeData(color: vibrant.secondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: vibrant.secondary,
        foregroundColor: vibrant.onSecondary,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: vibrant.surface,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: vibrant.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF007BFF),
    brightness: Brightness.dark,
  ),
  textTheme: GoogleFonts.interTextTheme().apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    foregroundColor: Colors.white,
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
    },
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
