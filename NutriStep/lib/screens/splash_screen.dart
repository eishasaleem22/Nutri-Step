import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_projects/screens/home_screen.dart';
import 'package:flutter_projects/screens/welcome_screen.dart';

import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Force Firebase to re-fetch the user’s state from the server
        await user.reload();
        user = FirebaseAuth.instance.currentUser; // re-grab the possibly updated user
      } catch (e) {
        // In case of any error (for example: the user was deleted),
        // treat it as if user == null
        user = null;
      }
    }

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Dark background to fill the entire screen
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain, // Ensures logo fits appropriately
          height: 180, // Smaller size to match the fitness app's style
          width: 180, // Smaller size to match the fitness app's style
        ),
      ),
    );
  }
}