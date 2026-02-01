import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_prefernces.dart';
import '../utils/calorie_calculator.dart' hide GoalType, ActivityLevel;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController genderController;
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  String? selectedGoal;
  String? selectedActivity;
  bool isLoading = false;
  bool _isButtonPressed = false;
  bool _isLogoutPressed = false;
  final _formKey = GlobalKey<FormState>();
  final List<String> goals = ['Lose Weight', 'Gain Muscle', 'Stay Fit'];
  final List<String> activities = ['Sedentary', 'Moderate', 'Active'];
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session expired. Please log in again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      });
    } else {
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      userData = doc.data() as Map<String, dynamic>?;

      nameController = TextEditingController(text: userData?['name'] ?? '');
      emailController = TextEditingController(text: userData?['email'] ?? '');
      genderController = TextEditingController(text: userData?['gender'] ?? '');
      ageController = TextEditingController(text: userData?['age']?.toString() ?? '');
      heightController = TextEditingController(text: userData?['height_cm']?.toString() ?? '');
      weightController = TextEditingController(text: userData?['weight_kg']?.toString() ?? '');
      selectedGoal = userData?['goal'] ?? goals[2];
      selectedActivity = userData?['activity'] ?? activities[1];

      setState(() {});
    }
  }

  Future<void> saveProfileChanges() async {
    if (user == null || !_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'gender': genderController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'height_cm': double.tryParse(heightController.text.trim()) ?? 0,
        'weight_kg': double.tryParse(weightController.text.trim()) ?? 0,
        'goal': selectedGoal,
        'activity': selectedActivity,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
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

  void _confirmLogout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Confirm Logout",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text(
              "Logout",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
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

    if (user == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Text(
            "Redirecting to login...",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onBackground,
            ),
          ),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "My Profile",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        iconTheme: theme.appBarTheme.iconTheme,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // inside your ProfileScreen build…
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF00C6A7), // pick a nice fallback color
                    backgroundImage: user!.photoURL != null
                        ? NetworkImage(user!.photoURL!)         // real image
                        : null,
                    child: user!.photoURL == null
                        ? Text(
                      // grab first letter from the nameController or userData
                      (nameController.text.isNotEmpty
                          ? nameController.text[0]
                          : 'U'   // default to 'U' if somehow empty
                      ).toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),

                  
                ],
              ),
            ),
            const SizedBox(height: 8),

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Basic Information",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: nameController,
                        label: "Name",
                        icon: Icons.person,
                        validator: (val) => val!.trim().isEmpty ? "Name is required" : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: genderController,
                        label: "Gender",
                        icon: Icons.transgender,
                        validator: (val) => val!.trim().isEmpty ? "Gender is required" : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: ageController,
                        label: "Age",
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val!.trim().isEmpty) return "Age is required";
                          if (int.tryParse(val) == null || int.parse(val) <= 0) return "Enter a valid age";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: heightController,
                        label: "Height (cm)",
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val!.trim().isEmpty) return "Height is required";
                          if (double.tryParse(val) == null || double.parse(val) <= 0) return "Enter a valid height";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: weightController,
                        label: "Weight (kg)",
                        icon: Icons.fitness_center,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val!.trim().isEmpty) return "Weight is required";
                          if (double.tryParse(val) == null || double.parse(val) <= 0) return "Enter a valid weight";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Preferences",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: "Goal",
                      value: selectedGoal,
                      items: goals,
                      onChanged: (val) => setState(() => selectedGoal = val),
                      icon: Icons.star,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField(
                      label: "Activity Level",
                      value: selectedActivity,
                      items: activities,
                      onChanged: (val) => setState(() => selectedActivity = val),
                      icon: Icons.directions_run,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? CircularProgressIndicator(color: colorScheme.primary)
                : GestureDetector(
              onTapDown: (_) => setState(() => _isButtonPressed = true),
              onTapUp: (_) => setState(() => _isButtonPressed = false),
              onTapCancel: () => setState(() => _isButtonPressed = false),
              onTap: saveProfileChanges,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue, // No tertiary color in theme; using blue
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
                    "Save Changes",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTapDown: (_) => setState(() => _isLogoutPressed = true),
              onTapUp: (_) => setState(() => _isLogoutPressed = false),
              onTapCancel: () => setState(() => _isLogoutPressed = false),
              onTap: () => _confirmLogout(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isLogoutPressed ? 0.95 : 1.0),
                child: Card(
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: colorScheme.error.withOpacity(0.3),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.error, colorScheme.error.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: colorScheme.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Logout",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: colorScheme.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle,
        hintStyle: theme.inputDecorationTheme.hintStyle,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: theme.inputDecorationTheme.filled,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ),
      ),
      validator: validator,
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
    return DropdownButtonFormField<String>(
      value: value,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: theme.inputDecorationTheme.filled,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
      ),
      dropdownColor: theme.colorScheme.surface,
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Please select a $label" : null,
    );
  }
}