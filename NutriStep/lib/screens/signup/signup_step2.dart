import 'package:flutter/material.dart';
import 'signup_step3.dart';

class SignupStep2 extends StatefulWidget {
  final String name, email, password;
  SignupStep2({required this.name, required this.email, required this.password});

  @override
  _SignupStep2State createState() => _SignupStep2State();
}

class _SignupStep2State extends State<SignupStep2> {
  final _formKey = GlobalKey<FormState>();
  String? _gender = 'Male';
  String? _age, _height, _weight;
  bool _isButtonPressed = false;

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
            "Personal Details",
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
              _buildProgressBar(step: 2, totalSteps: 3),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  "Step 2: Personal Details",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tell us about yourself to personalize your plan.",
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
                          label: "Gender",
                          value: _gender,
                          items: ['Male', 'Female', 'Other'],
                          onChanged: (val) => setState(() => _gender = val),
                          icon: Icons.people,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Age",
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _age = val,
                          validator: (value) =>
                          (value == null || int.tryParse(value) == null)
                              ? 'Enter valid age'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Height (cm)",
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _height = val,
                          validator: (value) =>
                          (value == null || double.tryParse(value) == null)
                              ? 'Enter valid height'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Weight (kg)",
                          icon: Icons.fitness_center,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _weight = val,
                          validator: (value) =>
                          (value == null || double.tryParse(value) == null)
                              ? 'Enter valid weight'
                              : null,
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
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupStep3(
                          name: widget.name,
                          email: widget.email,
                          password: widget.password,
                          gender: _gender!,
                          age: int.parse(_age!),
                          height: double.parse(_height!),
                          weight: double.parse(_weight!),
                        ),
                      ),
                    );
                  }
                },
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
                      "Next",
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle,
        hintText: 'Enter $label',
        hintStyle: theme.inputDecorationTheme.hintStyle,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
      ),
      validator: validator,
      onChanged: onChanged,
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