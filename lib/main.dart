import 'package:flutter/material.dart';
import 'app/app_shell.dart';
import 'app/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.dark; // default

  void _setThemeMode(ThemeMode mode) {
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reels Clone',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: AppShell(themeMode: _mode, onThemeModeChanged: _setThemeMode),
      debugShowCheckedModeBanner: false,
    );
  }
}
