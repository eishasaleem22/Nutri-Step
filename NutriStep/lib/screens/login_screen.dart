import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/screens/home_screen.dart';
import 'package:flutter_projects/screens/signup/signup_step1.dart';
import 'forget_password_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _isButtonPressed = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Login failed",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Text(
                    "Welcome Back",
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Log in to continue your NutriStep journey",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: "Email",
                            hintText: "Enter your email",
                            prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                            labelStyle: theme.inputDecorationTheme.labelStyle,
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            enabledBorder: theme.inputDecorationTheme.enabledBorder,
                            focusedBorder: theme.inputDecorationTheme.focusedBorder,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Email is required";
                            }
                            final trimmed = val.trim();
                            if (!trimmed.contains("@") || !trimmed.contains(".")) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Enter your password",
                            prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                            labelStyle: theme.inputDecorationTheme.labelStyle,
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            enabledBorder: theme.inputDecorationTheme.enabledBorder,
                            focusedBorder: theme.inputDecorationTheme.focusedBorder,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Password is required";
                            }
                            if (val.trim().length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        isLoading
                            ? CircularProgressIndicator(color: colorScheme.primary)
                            : GestureDetector(
                          onTapDown: (_) => setState(() => _isButtonPressed = true),
                          onTapUp: (_) => setState(() => _isButtonPressed = false),
                          onTapCancel: () => setState(() => _isButtonPressed = false),
                          onTap: login,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "Log In",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignupStep1()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}