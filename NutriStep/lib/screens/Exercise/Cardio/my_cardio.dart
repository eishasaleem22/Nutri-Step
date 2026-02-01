import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/screens/Exercise/Cardio/cardio_detail.dart';

class MyCardioExercisesPage extends StatefulWidget {
  final String userId;

  const MyCardioExercisesPage({super.key, required this.userId});

  @override
  State<MyCardioExercisesPage> createState() => _MyCardioExercisesPageState();
}

class _MyCardioExercisesPageState extends State<MyCardioExercisesPage> {
  List<Map<String, dynamic>> myExercises = [];

  @override
  void initState() {
    super.initState();
    fetchMyExercises();
  }

  Future<void> fetchMyExercises() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("my_cardio_exercises")
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      myExercises = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    });
  }

  void showCreateDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController();
    final calPerMinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Create New Cardio Exercise",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g. Running',
                  labelStyle: theme.inputDecorationTheme.labelStyle,
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: calPerMinController,
                decoration: InputDecoration(
                  labelText: 'Calories / Minute',
                  hintText: 'e.g. 10.5',
                  labelStyle: theme.inputDecorationTheme.labelStyle,
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
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
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final cal = double.tryParse(calPerMinController.text.trim());

              if (name.isNotEmpty && cal != null) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .collection("my_cardio_exercises")
                    .add({
                  "name": name,
                  "calories_burned_per_min": cal,
                  "timestamp": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                fetchMyExercises();
              }
            },
            child: Text(
              "Add",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
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

    return Container(
      color: colorScheme.background,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: showCreateDialog,
              icon: Icon(Icons.add, size: 20, color: colorScheme.onPrimary),
              label: Text(
                "Create New Cardio Exercise",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: myExercises.isEmpty
                ? Center(
              child: Text(
                "No custom exercises found",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: fetchMyExercises,
              color: colorScheme.primary,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: myExercises.length,
                itemBuilder: (context, index) {
                  final e = myExercises[index];
                  final name = e['name'] ?? '';
                  final calPerMin = e['calories_burned_per_min']?.toStringAsFixed(1) ?? '0';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Card(
                      color: colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Calories/Min: $calPerMin",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        leading: IconButton(
                          icon: Icon(Icons.remove_circle, color: colorScheme.error, size: 28),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(widget.userId)
                                .collection("my_cardio_exercises")
                                .doc(e['docId'])
                                .delete();
                            fetchMyExercises();
                          },
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 28),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardioDetailPage(
                                  exerciseData: e,
                                  userId: widget.userId,
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
          ),
        ],
      ),
    );
  }
}