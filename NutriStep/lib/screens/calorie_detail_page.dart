import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalorieDetailsPage extends StatefulWidget {
  const CalorieDetailsPage({super.key});

  @override
  State<CalorieDetailsPage> createState() => _CalorieDetailsPageState();
}

class _CalorieDetailsPageState extends State<CalorieDetailsPage> {
  double breakfastCal = 0;
  double lunchCal = 0;
  double dinnerCal = 0;
  double otherCal = 0;
  double total = 0;
  double net = 0;
  final double goal = 1420;
  double carbs = 0;
  double fat = 0;
  double protein = 0;

  @override
  void initState() {
    super.initState();
    fetchCalorieAndMacros();
  }

  Future<void> fetchCalorieAndMacros() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'others'];

    for (final meal in mealTypes) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(today)
          .collection(meal)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cal = data['total_calories']?.toDouble() ?? 0.0;
        final c = data['carbs']?.toDouble() ?? 0.0;
        final p = data['protein']?.toDouble() ?? 0.0;
        final f = data['fat']?.toDouble() ?? 0.0;

        setState(() {
          if (meal == 'breakfast') breakfastCal += cal;
          if (meal == 'lunch') lunchCal += cal;
          if (meal == 'dinner') dinnerCal += cal;
          if (meal == 'others') otherCal += cal;

          carbs += c;
          protein += p;
          fat += f;
        });
      }
    }

    setState(() {
      total = breakfastCal + lunchCal + dinnerCal + otherCal;
      net = goal - total;
    });
  }

  Widget buildMealBox(String label, double calories, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    double percentage = (calories / goal * 100).clamp(0, 100);
    return SizedBox(
      width: 100, // Constrain width for consistent scrolling
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            "${percentage.toStringAsFixed(0)}% (${calories.toStringAsFixed(0)} cal)",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget buildMacroRow(String label, double grams, double percentage, double goalPercentage, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 17,
                  height: 12,
                  color: color,
                  margin: const EdgeInsets.only(right: 8),
                ),
                Flexible(
                  child: Text(
                    "$label (${grams.toStringAsFixed(0)}g)",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "${percentage.isNaN ? 0 : percentage.toStringAsFixed(0)}%",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "${goalPercentage.toStringAsFixed(0)}%",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
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
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorScheme.primary, colorScheme.secondary],
    );
    double netCalories = net;
    double totalMacros = carbs + fat + protein;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "Calorie Details",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        "Calories by Meal",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              buildMealBox("Breakfast", breakfastCal, colorScheme.primary),
                              const SizedBox(width: 16),
                              buildMealBox("Lunch", lunchCal, colorScheme.secondary),
                              const SizedBox(width: 16),
                              buildMealBox("Dinner", dinnerCal, Colors.blue),
                              const SizedBox(width: 16),
                              buildMealBox("Others", otherCal, Colors.purple),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                        "Calories Summary",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Calories",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "${total.toStringAsFixed(0)} cal",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Net Calories",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "${netCalories.toStringAsFixed(0)} cal",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: netCalories >= 0 ? colorScheme.primary : colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Goal",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "${goal.toStringAsFixed(0)} cal",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        "Macronutrients",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Nutrient",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "Total",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "Goal",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      buildMacroRow(
                        "Carbohydrates",
                        carbs,
                        totalMacros > 0 ? (carbs / totalMacros) * 100 : 0,
                        50,
                        colorScheme.primary,
                      ),
                      buildMacroRow(
                        "Fat",
                        fat,
                        totalMacros > 0 ? (fat / totalMacros) * 100 : 0,
                        30,
                        colorScheme.secondary,
                      ),
                      buildMacroRow(
                        "Protein",
                        protein,
                        totalMacros > 0 ? (protein / totalMacros) * 100 : 0,
                        20,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}