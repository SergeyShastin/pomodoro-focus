import 'package:flutter/material.dart';

export 'app_theme_mode.dart';

class AppTheme {
  static const Color defaultSeedColor =
      Color(0xFFD32F2F); // Classic Pomodoro Red

  static ThemeData light(ColorScheme? dynamicColorScheme, Color seedColor,
      {double fontScale = 1.2}) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );

    return _buildTheme(colorScheme, fontScale: fontScale);
  }

  static ThemeData dark(ColorScheme? dynamicColorScheme, Color seedColor,
      {double fontScale = 1.2}) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );

    return _buildTheme(colorScheme, fontScale: fontScale);
  }

  static ThemeData oled(ColorScheme? dynamicColorScheme, Color seedColor,
      {double fontScale = 1.2}) {
    final baseDarkScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );

    // Pure black (#000000) for OLED burn-in prevention and maximum power saving
    final oledScheme = baseDarkScheme.copyWith(
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceBright: const Color(0xFF1E1E1E),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF121212),
      surfaceContainerHigh: const Color(0xFF1C1C1C),
      surfaceContainerHighest: const Color(0xFF262626),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFCCCCCC),
    );

    return _buildTheme(oledScheme, fontScale: fontScale).copyWith(
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: const Color(0xFF121212),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorColor: oledScheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.black,
        indicatorColor: oledScheme.secondaryContainer,
      ),
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme,
      {required double fontScale}) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    return ThemeData(
      useMaterial3: true,
      textTheme: base.typography.englishLike.apply(
        fontSizeFactor: fontScale,
        fontFamily: base.textTheme.bodyMedium?.fontFamily,
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        labelType: NavigationRailLabelType.all,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
