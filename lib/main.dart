import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userStr = prefs.getString('user_session');
  Map<String, dynamic>? user;
  if (userStr != null) {
    try {
      user = jsonDecode(userStr);
    } catch (e) {
      print('Error parsing saved user: $e');
    }
  }
  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticketz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EA)),
        useMaterial3: true,
      ),
      home: initialUser != null 
          ? DashboardScreen(user: initialUser!) 
          : const LoginScreen(),
    );
  }
}
