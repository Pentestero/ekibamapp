import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const ColorScheme _monoLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF000000),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF1A1A1A),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF555555),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE0E0E0),
  onSecondaryContainer: Color(0xFF1A1A1A),
  tertiary: Color(0xFF888888),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFEDEDED),
  onTertiaryContainer: Color(0xFF1A1A1A),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  background: Color(0xFFFFFFFF),
  onBackground: Color(0xFF000000),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF000000),
  surfaceVariant: Color(0xFFE0E0E0),
  onSurfaceVariant: Color(0xFF444444),
  outline: Color(0xFF888888),
  outlineVariant: Color(0xFFCCCCCC),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1A1A1A),
  onInverseSurface: Color(0xFFF5F5F5),
  inversePrimary: Color(0xFFCCCCCC),
  surfaceTint: Color(0xFF000000),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF7F7F7),
  surfaceContainer: Color(0xFFF0F0F0),
  surfaceContainerHigh: Color(0xFFE8E8E8),
  surfaceContainerHighest: Color(0xFFE0E0E0),
  surfaceDim: Color(0xFFD6D6D6),
  surfaceBright: Color(0xFFFFFFFF),
  primaryFixed: Color(0xFFE0E0E0),
  onPrimaryFixed: Color(0xFF000000),
  primaryFixedDim: Color(0xFFBDBDBD),
  onPrimaryFixedVariant: Color(0xFF1A1A1A),
  secondaryFixed: Color(0xFFE0E0E0),
  onSecondaryFixed: Color(0xFF1A1A1A),
  secondaryFixedDim: Color(0xFFBDBDBD),
  onSecondaryFixedVariant: Color(0xFF333333),
  tertiaryFixed: Color(0xFFEDEDED),
  onTertiaryFixed: Color(0xFF1A1A1A),
  tertiaryFixedDim: Color(0xFFCCCCCC),
  onTertiaryFixedVariant: Color(0xFF333333),
);

const ColorScheme _monoDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF000000),
  primaryContainer: Color(0xFFE0E0E0),
  onPrimaryContainer: Color(0xFF000000),
  secondary: Color(0xFFCCCCCC),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFF333333),
  onSecondaryContainer: Color(0xFFF0F0F0),
  tertiary: Color(0xFF999999),
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF2A2A2A),
  onTertiaryContainer: Color(0xFFE0E0E0),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  background: Color(0xFF0A0A0A),
  onBackground: Color(0xFFF5F5F5),
  surface: Color(0xFF0A0A0A),
  onSurface: Color(0xFFF5F5F5),
  surfaceVariant: Color(0xFF333333),
  onSurfaceVariant: Color(0xFFC0C0C0),
  outline: Color(0xFF8A8A8A),
  outlineVariant: Color(0xFF3A3A3A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFF0F0F0),
  onInverseSurface: Color(0xFF1A1A1A),
  inversePrimary: Color(0xFF000000),
  surfaceTint: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFF050505),
  surfaceContainerLow: Color(0xFF141414),
  surfaceContainer: Color(0xFF1A1A1A),
  surfaceContainerHigh: Color(0xFF242424),
  surfaceContainerHighest: Color(0xFF303030),
  surfaceDim: Color(0xFF0A0A0A),
  surfaceBright: Color(0xFF3A3A3A),
  primaryFixed: Color(0xFFE0E0E0),
  onPrimaryFixed: Color(0xFF000000),
  primaryFixedDim: Color(0xFFBDBDBD),
  onPrimaryFixedVariant: Color(0xFF1A1A1A),
  secondaryFixed: Color(0xFFE0E0E0),
  onSecondaryFixed: Color(0xFF1A1A1A),
  secondaryFixedDim: Color(0xFFBDBDBD),
  onSecondaryFixedVariant: Color(0xFF333333),
  tertiaryFixed: Color(0xFFEDEDED),
  onTertiaryFixed: Color(0xFF1A1A1A),
  tertiaryFixedDim: Color(0xFFCCCCCC),
  onTertiaryFixedVariant: Color(0xFF333333),
);

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);
}

ThemeData _buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;

  final cs = isLight ? _monoLight : _monoDark;

  final surfaceColor =
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0A);
  final cardColor = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF161616);

  final textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: isLight ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
    displayColor: isLight ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs.copyWith(surface: surfaceColor),
    textTheme: textTheme,
    scaffoldBackgroundColor: cs.surface,

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
