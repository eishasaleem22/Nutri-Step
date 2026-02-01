import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CardioDetailPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;
  final String userId;
  final String? docId;

  const CardioDetailPage({super.key, required this.exerciseData, required this.userId, this.docId});

  @override
  State<CardioDetailPage> createState() => _CardioDetailPageState();
}

class _CardioDetailPageState extends State<CardioDetailPage> {
  late TextEditingController minutesController;
  late TextEditingController caloriesController;

  @override
  void initState() {
    super.initState();
    minutesController = TextEditingController(
      text: widget.exerciseData['minutes']?.toString() ?? '',
    );
    caloriesController = TextEditingController(
      text: widget.exerciseData['calories_burned']?.toString() ?? '',
    );
  }

  void addCardioToLog() async {
    final minutes = double.tryParse(minutesController.text.trim()) ?? 0;
    final calories = double.tryParse(caloriesController.text.trim()) ?? 0;

    if (minutes <= 0 || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter valid values.",
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
        .collection('cardio');

    final entry = {
      'name': widget.exerciseData['name'],
      'minutes': minutes,
      'calories_burned': calories,
      'type': 'cardio',
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (widget.docId != null) {
      await ref.doc(widget.docId!).update(entry);
    } else {
      await ref.add(entry);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = widget.exerciseData['name'];

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
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
            onPressed: addCardioToLog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minutes performed',
                hintText: 'e.g. 30',
                labelStyle: theme.inputDecorationTheme.labelStyle,
                hintStyle: theme.inputDecorationTheme.hintStyle,
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
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
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calories Burned',
                hintText: 'e.g. 120',
                labelStyle: theme.inputDecorationTheme.labelStyle,
                hintStyle: theme.inputDecorationTheme.hintStyle,
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}