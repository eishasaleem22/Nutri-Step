import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_projects/screens/home_screen.dart';
import '../dashboard_screen.dart';

class SignupStep3 extends StatefulWidget {
  final String name, email, password, gender;
  final int age;
  final double height, weight;

  const SignupStep3({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
  });

  @override
  State<SignupStep3> createState() => _SignupStep3State();
}

class _SignupStep3State extends State<SignupStep3> {
  final _formKey = GlobalKey<FormState>();
  String? _goal = 'Lose Weight';
  String? _activity = 'Moderate';
  bool _isButtonPressed = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          UserCredential cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
          user = cred.user;
        }
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': widget.name,
            'email': widget.email,
            'gender': widget.gender,
            'age': widget.age,
            'height_cm': widget.height,
            'weight_kg': widget.weight,
            'goal': _goal,
            'activity': _activity,
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signup error: ${e.message ?? 'Unknown error'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
              ),
            ),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorScheme.primary, colorScheme.secondary],
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "Set Your Goals",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildProgressBar(step: 3, totalSteps: 3),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  "Step 3: Goals & Activity",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Define your fitness journey.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
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
                        _buildDropdownField(
                          label: "Fitness Goal",
                          value: _goal,
                          items: ['Lose Weight', 'Gain Muscle', 'Stay Fit'],
                          onChanged: (val) => setState(() => _goal = val),
                          icon: Icons.star,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: "Activity Level",
                          value: _activity,
                          items: ['Sedentary', 'Moderate', 'Active'],
                          onChanged: (val) => setState(() => _activity = val),
                          icon: Icons.directions_run,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) => setState(() => _isButtonPressed = false),
                onTapCancel: () => setState(() => _isButtonPressed = false),
                onTap: _submit,
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
                      "Complete Sign-Up",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DropdownButtonFormField<String>(
      value: value,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
      ),
      dropdownColor: colorScheme.surface,
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProgressBar({required int step, required int totalSteps}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorScheme.primary, colorScheme.secondary],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(totalSteps, (index) {
        final isActive = index < step;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: isActive ? gradient : null,
              color: isActive ? null : colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}