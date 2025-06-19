import 'package:flutter/material.dart';

const _colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF414B79), // Main sidebar background
  onPrimary: Color(0xFFFFFFFF), // Text/icons on primary color (white)
  primaryContainer: Color(0xFFE8E8E8), // Input field background
  onPrimaryContainer: Color(0xFF131E4E), // Darker blue for contrast

  secondary: Color(0xFFFFFFFF), // Active tab highlight
  onSecondary: Color(0xFF414A73), // Text/icons on secondary color (white)
  secondaryContainer: Color(
    0xFF4368FA,
  ), // Lighter blue, used for additional highlights
  onSecondaryContainer: Color(0xFF131E4E), // Dark contrast for readability

  error: Colors.red, // Error messages or alerts
  onError: Color(0xFFFFFFFF), // Text/icons on error color (white)
  errorContainer: Color(0xFFE8E8E8), // Soft background for errors
  onErrorContainer: Color(0xFF131E4E), // Dark contrast on error container

  surface: Color(0xFFE8E8E8), // Main form container background
  onSurface: Color(0xFF414A73), // Main text color (dark blue)
  onSurfaceVariant: Color(
    0xFF787878,
  ), // Muted gray for labels, dividers, secondary text
  surfaceDim: Color(0xFFFFFFFF), // Light gray background for subtle contrast
  outline: Colors.grey,
);

const _textTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 57,
    height: 1.13,
    letterSpacing: 0,
    fontWeight: FontWeight.normal,
  ),
  displayMedium: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 45,
    height: 1.16,
    letterSpacing: 0,
    fontWeight: FontWeight.normal,
  ),
  displaySmall: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 36,
    height: 1.22,
    letterSpacing: 0,
    fontWeight: FontWeight.normal,
  ),
  headlineLarge: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 32,
    height: 1.25,
    letterSpacing: 0,
    fontWeight: FontWeight.normal,
  ),
  headlineMedium: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 28,
    height: 1.29,
    letterSpacing: 0,
    fontWeight: FontWeight.normal,
  ),
  headlineSmall: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 24,
    height: 1.33,
    letterSpacing: 0,
    fontWeight: FontWeight.normal,
  ),
  titleLarge: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 20,
    height: 1.27,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  ),
  titleMedium: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.15,
    fontWeight: FontWeight.w600,
  ),
  titleSmall: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w600,
  ),
  labelLarge: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w600,
  ),
  labelMedium: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w600,
  ),
  labelSmall: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 11,
    height: 1.45,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w600,
  ),
  bodyLarge: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.15,
    fontWeight: FontWeight.normal,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.25,
    fontWeight: FontWeight.normal,
  ),
  bodySmall: TextStyle(
    fontFamily: 'AbhayaLibre',
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.4,
    fontWeight: FontWeight.normal,
  ),
);

final _appBarTheme = AppBarTheme(
  backgroundColor: _colorScheme.primary,
  titleSpacing: -8,
  titleTextStyle: _textTheme.titleMedium!.copyWith(
    color: _colorScheme.onPrimary,
  ),
  actionsIconTheme: IconThemeData(color: _colorScheme.onPrimary),
  iconTheme: IconThemeData(color: _colorScheme.onPrimary),
);

final _inputDecorationTheme = InputDecorationTheme(
  hintStyle: _textTheme.titleMedium!.copyWith(
    color: _colorScheme.onSurfaceVariant,
  ),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: _colorScheme.outline, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: _colorScheme.primary, width: 1.5),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
);

final _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    foregroundColor: _colorScheme.onPrimary,
    backgroundColor: _colorScheme.primary,
    textStyle: _textTheme.titleSmall!.copyWith(
      color: _colorScheme.onPrimary,
      fontWeight: FontWeight.w600,
    ),
    disabledBackgroundColor: const Color.fromARGB(120, 158, 158, 158),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
  ),
);

final _cardTheme = CardThemeData(
  color: _colorScheme.secondary,
  elevation: 2,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

final _navigationBarTheme = NavigationBarThemeData(
  backgroundColor: _colorScheme.primaryContainer,
  indicatorColor: _colorScheme.primaryFixed,
);

final _dialogTheme = DialogThemeData(
  backgroundColor: _colorScheme.surface,
  elevation: 3,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  titleTextStyle: _textTheme.titleMedium!.copyWith(
    color: _colorScheme.onSurface,
  ),
  contentTextStyle: _textTheme.bodyMedium!.copyWith(
    color: _colorScheme.onSurface,
  ),
);

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: _colorScheme,
  textTheme: _textTheme,
  appBarTheme: _appBarTheme,
  scaffoldBackgroundColor: _colorScheme.surface,
  inputDecorationTheme: _inputDecorationTheme,
  splashFactory: InkRipple.splashFactory,
  elevatedButtonTheme: _elevatedButtonTheme,
  cardTheme: _cardTheme,
  navigationBarTheme: _navigationBarTheme,
  dialogTheme: _dialogTheme,
);
