import 'package:cake_shop/splash_screen.dart';
import 'package:flutter/material.dart';

import 'admin/screens/admin_dashboard_screen.dart';
import 'screens/forgot_password_page.dart';
import 'screens/login_page.dart';
import 'screens/shop_shell.dart';
import 'theme/app_theme.dart';

class CakeShopApp extends StatefulWidget {
  const CakeShopApp({super.key});

  static _CakeShopAppState _of(BuildContext context) =>
      context.findAncestorStateOfType<_CakeShopAppState>()!;

  static bool isDarkMode(BuildContext context) => _of(context).isDarkMode;

  static void setDarkMode(BuildContext context, bool isDark) {
    _of(context).toggleTheme(isDark);
  }

  @override
  State<CakeShopApp> createState() => _CakeShopAppState();
}

class _CakeShopAppState extends State<CakeShopApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cake Shop',
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
      routes: {
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/login': (context) => const LoginPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/shop': (context) => const ShopShell(),
      },
    );
  }
}
