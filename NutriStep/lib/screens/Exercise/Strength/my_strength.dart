import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'strength_detail.dart';

class MyStrengthExercisesPage extends StatefulWidget {
  final String userId;

  const MyStrengthExercisesPage({super.key, required this.userId});

  @override
  State<MyStrengthExercisesPage> createState() => _MyStrengthExercisesPageState();
}

class _MyStrengthExercisesPageState extends State<MyStrengthExercisesPage> {
  List<Map<String, dynamic>> myExercises = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMyExercises();
  }

  Future<void> fetchMyExercises() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("my_strength_exercises")
        .orderBy("timestamp", descending: true)
        .get();

    myExercises = snapshot.docs.map((doc) {
      final data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();

    setState(() => isLoading = false);
  }

  void showCreateDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Create New Strength Exercise",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildDialogTextField(
                label: "Exercise Name",
                controller: nameController,
              ),
              _buildDialogTextField(
                label: "Sets",
                controller: setsController,
                keyboardType: TextInputType.number,
              ),
              _buildDialogTextField(
                label: "Reps/Set",
                controller: repsController,
                keyboardType: TextInputType.number,
              ),
              _buildDialogTextField(
                label: "Weight/Rep (kg)",
                controller: weightController,
                keyboardType: TextInputType.number,
              ),
              _buildDialogTextField(
                label: "Calories Burned",
                controller: caloriesController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final sets = int.tryParse(setsController.text.trim()) ?? 0;
              final reps = int.tryParse(repsController.text.trim()) ?? 0;
              final weight = double.tryParse(weightController.text.trim()) ?? 0;
              final calories = double.tryParse(caloriesController.text.trim()) ?? 0;

              if (name.isNotEmpty && sets > 0 && reps > 0 && weight > 0 && calories > 0) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .collection("my_strength_exercises")
                    .add({
                  "name": name,
                  "sets": sets,
                  "repetitions_per_set": reps,
                  "weight_per_repiration": weight,
                  "calories_burned": calories,
                  "timestamp": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                fetchMyExercises();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please fill out all fields correctly.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onError,
                      ),
                    ),
                    backgroundColor: colorScheme.error,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              "Add",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter $label',
          labelStyle: theme.inputDecorationTheme.labelStyle,
          hintStyle: theme.inputDecorationTheme.hintStyle,
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

    return Container(
      color: colorScheme.background,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: showCreateDialog,
              icon: Icon(Icons.add, color: colorScheme.onPrimary),
              label: Text(
                "Create Strength Exercise",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.onSurface.withOpacity(0.3)),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : myExercises.isEmpty
                ? Center(
              child: Text(
                "No custom strength exercises found",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: myExercises.length,
              itemBuilder: (context, index) {
                final e = myExercises[index];
                final docId = e['docId'] as String? ?? "";
                final name = e['name'] as String? ?? "";
                final sets = e['sets'] as int? ?? 0;
                final reps = e['repetitions_per_set'] as int? ?? 0;
                final weight = e['weight_per_repiration'] as num? ?? 0;
                final calories = e['calories_burned'] as num? ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Card(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: IconButton(
                        icon: Icon(Icons.remove_circle, color: colorScheme.error, size: 28),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(widget.userId)
                              .collection("my_strength_exercises")
                              .doc(docId)
                              .delete();
                          fetchMyExercises();
                        },
                      ),
                      title: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "$sets sets × $reps reps @ ${weight}kg\n$calories cal",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StrengthDetailPage(
                                exerciseData: e,
                                userId: widget.userId,
                                docId: docId,
                              ),
                            ),
                          );
                          if (result == true) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}