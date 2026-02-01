import 'package:flutter/material.dart';
import 'package:flutter_projects/screens/signup/signup_step1.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
    // ensures appTheme is applied in MaterialApp

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoginPressed = false;
  bool _isSignupPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Title
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.nutriStep.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  "Welcome to NutriStep",
                  style: theme.textTheme.headlineLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                "Start your journey to a healthier you",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Log In button
              GestureDetector(
                onTapDown: (_) => setState(() => _isLoginPressed = true),
                onTapUp: (_) => setState(() => _isLoginPressed = false),
                onTapCancel: () => setState(() => _isLoginPressed = false),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform:
                  Matrix4.identity()..scale(_isLoginPressed ? 0.95 : 1.0),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.nutriStep,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Log In",
                      style: theme.textTheme.titleMedium!
                          .copyWith(color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Up button
              GestureDetector(
                onTapDown: (_) => setState(() => _isSignupPressed = true),
                onTapUp: (_) => setState(() => _isSignupPressed = false),
                onTapCancel: () => setState(() => _isSignupPressed = false),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupStep1(),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform:
                  Matrix4.identity()..scale(_isSignupPressed ? 0.95 : 1.0),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Sign Up",
                      style: theme.textTheme.titleMedium!
                          .copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
