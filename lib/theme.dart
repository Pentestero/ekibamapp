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

  // Define explicit status colors for messages
  final Color successColor = brightness == Brightness.light ? Colors.green.shade600 : Colors.green.shade400;
  final Color warningColor = brightness == Brightness.light ? Colors.orange.shade700 : Colors.orange.shade400;
  final Color infoColor = brightness == Brightness.light ? Colors.blue.shade600 : Colors.blue.shade400;


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
        backgroundColor: cs.primary, // Primary button uses primary color
        foregroundColor: cs.onPrimary,
        minimumSize: const Size(48, 48), // Good touch target for mobile
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 3, // Add some elevation
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return cs.onPrimary.withOpacity(0.08); // Subtle hover effect
            }
            if (states.contains(MaterialState.focused)) {
              return cs.onPrimary.withOpacity(0.12); // Subtle focus effect
            }
            if (states.contains(MaterialState.pressed)) {
              return cs.onPrimary.withOpacity(0.12); // Subtle pressed effect
            }
            return null; // Defer to the widget's default.
          },
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary, // Outlined uses primary color for text/border
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: cs.primary), // Border color
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return cs.primary.withOpacity(0.08);
            }
            if (states.contains(MaterialState.focused)) {
              return cs.primary.withOpacity(0.12);
            }
            if (states.contains(MaterialState.pressed)) {
              return cs.primary.withOpacity(0.12);
            }
            return null;
          },
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary, // Text button uses primary color
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return cs.primary.withOpacity(0.08);
            }
            if (states.contains(MaterialState.focused)) {
              return cs.primary.withOpacity(0.12);
            }
            if (states.contains(MaterialState.pressed)) {
              return cs.primary.withOpacity(0.12);
            }
            return null;
          },
        ),
      ),
    ),
    // Destructive Button Style (example - could be used for danger actions)
    // You can define a custom button widget that uses this, or apply directly
    // to existing buttons that need this specific styling.
    buttonTheme: ButtonThemeData(
      colorScheme: cs.copyWith(error: cs.error),
      textTheme: ButtonTextTheme.primary,
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


