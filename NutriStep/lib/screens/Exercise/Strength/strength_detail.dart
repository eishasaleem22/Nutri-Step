import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StrengthDetailPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;
  final String userId;
  final String? docId;

  const StrengthDetailPage({
    super.key,
    required this.exerciseData,
    required this.userId,
    this.docId,
  });

  @override
  State<StrengthDetailPage> createState() => _StrengthDetailPageState();
}

class _StrengthDetailPageState extends State<StrengthDetailPage> {
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.exerciseData;
    setsController.text = e['sets']?.toString() ?? '';
    repsController.text = e['repetitions_per_set']?.toString() ?? '';
    weightController.text = e['weight_per_repetition']?.toString() ?? '';
    caloriesController.text = e['calories_burned']?.toString() ?? '';
  }

  Future<void> saveExercise() async {
    final sets = int.tryParse(setsController.text.trim()) ?? 0;
    final reps = int.tryParse(repsController.text.trim()) ?? 0;
    final weight = double.tryParse(weightController.text.trim()) ?? 0;
    final calories = double.tryParse(caloriesController.text.trim()) ?? 0;

    if (sets <= 0 || reps <= 0 || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter all required values.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('logs')
        .doc(today)
        .collection('strength');

    final entry = {
      'name': widget.exerciseData['name'],
      'sets': sets,
      'repetitions_per_set': reps,
      'weight_per_repetition': weight,
      'calories_burned': calories,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'strength',
    };

    if (widget.docId != null) {
      final docSnapshot = await ref.doc(widget.docId!).get();
      if (docSnapshot.exists) {
        await ref.doc(widget.docId!).update(entry);
      } else {
        await ref.add(entry);
      }
    } else {
      await ref.add(entry);
    }

    Navigator.pop(context, true);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool requiredField = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: requiredField ? 'Required' : 'Optional',
          labelStyle: theme.inputDecorationTheme.labelStyle,
          hintStyle: theme.inputDecorationTheme.hintStyle,
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: theme.inputDecorationTheme.border,
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
        ),
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
    final titleText = widget.exerciseData['name'] as String;
    final isEditing = widget.docId != null;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            isEditing ? "Edit Exercise" : "Add Exercise",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        actions: [
          IconButton(
            icon: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
            ),
            onPressed: saveExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  children: [
                    _buildTextField(
                      label: "# of Sets",
                      controller: setsController,
                      requiredField: true,
                    ),
                    _buildTextField(
                      label: "Repetitions / Set",
                      controller: repsController,
                      requiredField: true,
                    ),
                    _buildTextField(
                      label: "Weight per Repetition (kg)",
                      controller: weightController,
                      requiredField: false,
                    ),
                    _buildTextField(
                      label: "Calories Burned",
                      controller: caloriesController,
                      requiredField: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveExercise,
                icon: Icon(Icons.check, color: colorScheme.onPrimary),
                label: Text(
                  isEditing ? "Update Exercise" : "Save Exercise",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}