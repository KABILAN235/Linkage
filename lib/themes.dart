import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.black,
    onSecondary: Colors.white,
    error: Colors.black,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.black),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.black)),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.black)),
  ),
  listTileTheme: ListTileThemeData(
    tileColor: Colors.white,
    iconColor: Colors.black,
    textColor: Colors.black,
  ),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.black,
    onSecondary: Colors.white,
    error: Colors.black,
    onError: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.white),
      foregroundColor: WidgetStatePropertyAll(Colors.black),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.white)),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.white)),
  ),
  listTileTheme: ListTileThemeData(
    tileColor: Colors.black,
    iconColor: Colors.white,
    textColor: Colors.white,
  ),
);
