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

  final isLight = brightness == Brightness.light;
  final surfaceColor = isLight ? Colors.white : const Color(0xFF1A1A2E);
  final cardColor = isLight ? Colors.white : const Color(0xFF16213E);

  final textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: isLight ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
    displayColor: isLight ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs.copyWith(surface: surfaceColor),
    textTheme: textTheme,
    scaffoldBackgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F0F23),

    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: isLight ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 2,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: cs.primary.withAlpha(25),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary, letterSpacing: 0.2);
        }
        return TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: isLight ? Colors.grey.shade500 : Colors.grey.shade400, letterSpacing: 0.1);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(size: 22, color: cs.primary);
        }
        return IconThemeData(size: 22, color: isLight ? Colors.grey.shade400 : Colors.grey.shade500);
      }),
      elevation: 12,
      shadowColor: isLight ? Colors.black.withAlpha(15) : Colors.black.withAlpha(50),
      surfaceTintColor: Colors.transparent,
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: cs.primary.withAlpha(30),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      selectedIconTheme: IconThemeData(color: cs.primary, size: 24),
      unselectedIconTheme: IconThemeData(color: isLight ? Colors.grey.shade500 : Colors.grey.shade500, size: 24),
      selectedLabelTextStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelTextStyle: TextStyle(color: isLight ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 12),
      labelType: NavigationRailLabelType.all,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        shadowColor: cs.primary.withAlpha(60),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return cs.onPrimary.withAlpha(30);
          return null;
        }),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.primary.withAlpha(80), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return cs.primary.withAlpha(20);
          return null;
        }),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        minimumSize: const Size(48, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return cs.primary.withAlpha(20);
          return null;
        }),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.error, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.error, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      labelStyle: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: isLight ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14, fontStyle: FontStyle.italic),
      prefixIconColor: isLight ? Colors.grey.shade500 : Colors.grey.shade500,
      suffixIconColor: isLight ? Colors.grey.shade500 : Colors.grey.shade500,
      floatingLabelStyle: TextStyle(color: cs.primary, fontSize: 14, fontWeight: FontWeight.w600),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155), width: 0.5),
      ),
      shadowColor: isLight ? Colors.black.withAlpha(18) : Colors.black.withAlpha(50),
      clipBehavior: Clip.antiAlias,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isLight ? const Color(0xFF111827) : Colors.white),
      contentTextStyle: TextStyle(fontSize: 15, color: isLight ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB), height: 1.5),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      dragHandleColor: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      contentTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isLight ? Colors.white : Colors.white),
      width: isLight ? null : 400,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
      selectedColor: cs.primary.withAlpha(30),
      labelStyle: TextStyle(fontSize: 13, color: isLight ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    dividerTheme: DividerThemeData(
      color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
      thickness: 0.5,
      space: 1,
    ),

    expansionTileTheme: ExpansionTileThemeData(
      iconColor: cs.primary,
      collapsedIconColor: isLight ? Colors.grey.shade500 : Colors.grey.shade500,
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return null;
      }),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary.withAlpha(60);
        return null;
      }),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: cs.primary,
      linearTrackColor: cs.primary.withAlpha(20),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(cardColor),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    badgeTheme: BadgeThemeData(
      backgroundColor: cs.error,
      textColor: Colors.white,
      smallSize: 8,
      largeSize: 20,
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      headerBackgroundColor: cs.primary,
      headerForegroundColor: cs.onPrimary,
      todayBackgroundColor: WidgetStateProperty.all(cs.primary.withAlpha(30)),
      todayForegroundColor: WidgetStateProperty.all(cs.primary),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return null;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return null;
      }),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),

    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
