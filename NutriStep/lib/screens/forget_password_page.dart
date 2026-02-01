import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
      // for AppGradients if needed
// … other imports …

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isButtonPressed = false;

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Password reset link sent to $email",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found with that email.";
          break;
        case 'invalid-email':
          message = "That email address is not valid.";
          break;
        default:
          message = "Error: ${e.message ?? 'Unknown error'}";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => AppGradients.nutriStep.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            "Reset Password",
            style: theme.textTheme.titleLarge,
          ),
        ),
        iconTheme: theme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppGradients.nutriStep.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                "Recover Your Account",
                style: theme.textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your email address to receive a password reset link.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: "Email",
                          hintText: "Enter your email",
                          prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                          // Input borders, fillColor, label/hint styles come from your InputDecorationTheme
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Email is required";
                          final t = val.trim();
                          if (!t.contains('@') || !t.contains('.')) return "Enter a valid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? CircularProgressIndicator(color: theme.colorScheme.primary)
                          : GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_)   => setState(() => _isButtonPressed = false),
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        onTap: _sendResetLink,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.identity()
                            ..scale(_isButtonPressed ? 0.95 : 1.0),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary, // your accentTeal
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
                              "Send Reset Email",
                              style: theme.textTheme.titleMedium!
                                  .copyWith(color: theme.colorScheme.onSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
