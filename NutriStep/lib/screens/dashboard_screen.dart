import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_prefernces.dart';
import '../services/notification_service.dart';
import '../utils/calorie_calculator.dart';
import '../widgets/native_ad_card.dart';
import 'Exercise/Cardio/add_cardio.dart';
import 'Exercise/Cardio/cardio_detail.dart';
import 'Exercise/Strength/add_strength.dart';
import 'Exercise/Strength/strength_detail.dart';
import 'Food/add_food_page.dart';
import 'Food/food_detail_page.dart';
import 'Water/add_water.dart';
import 'calorie_detail_page.dart';
import 'notifications_page.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double goal = 0;
  double totalFood = 0;
  double totalExercise = 0;
  double totalWater = 0;

  Map<String, List<Map<String, dynamic>>> meals = {
    "breakfast": [],
    "lunch": [],
    "dinner": [],
    "others": [],
  };

  List<Map<String, dynamic>> exercises = [];

  @override
  void initState() {
    super.initState();
    _loadUserGoalAndEntries();
  }

  Future<void> _loadUserGoalAndEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    // 1) Read the raw profile fields
    final doc = await userDocRef.get();
    final weight  = (doc.get('weight_kg')  as num).toDouble();
    final height  = (doc.get('height_cm')  as num).toDouble();
    final age     = doc.get('age')         as int;
    final gender  = doc.get('gender')      as String;
    final actRaw  = doc.get('activity')    as String;
    final goalRaw = doc.get('goal')        as String;

    // 2) Compute daily target
    final activity = parseActivity(actRaw);
    final goalType = parseGoal(goalRaw);
    final dailyTarget = CalorieCalculator(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: gender,
      activity: activity,
      goal: goalType,
    ).calculate();

    // 3) **Save** it back into Firestore so it's stored for next time
    await userDocRef.update({
      'dailyCalorieTarget': dailyTarget,
    });

    // 4) Update local state
    setState(() => goal = dailyTarget);

    // 5) Now fetch today’s entries using the real goal
    await fetchLoggedEntries(dailyTarget);
  }

  Future<void> fetchLoggedEntries([double? dailyTarget]) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    goal = dailyTarget ?? this.goal;

    double foodTotal = 0.0;
    double exerciseTotal = 0.0;
    double waterTotal = 0.0;

    Map<String, List<Map<String, dynamic>>> updatedMeals = {
      "breakfast": [],
      "lunch": [],
      "dinner": [],
      "others": [],
    };

    for (final meal in updatedMeals.keys) {
      final mealSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(todayStr)
          .collection(meal)
          .get();

      final List<Map<String, dynamic>> foodList = mealSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] = doc.id;
        return data;
      }).toList();

      updatedMeals[meal] = foodList;

      foodTotal += foodList.fold(0.0, (sum, item) {
        return sum + ((item['total_calories'] as num?)?.toDouble() ?? 0.0);
      });
    }

    final cardioSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('logs')
        .doc(todayStr)
        .collection('cardio')
        .get();

    List<Map<String, dynamic>> cardioExercises = cardioSnap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['docId'] = doc.id;
      data['type'] = 'cardio';
      return data;
    }).toList();

    final strengthSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('logs')
        .doc(todayStr)
        .collection('strength')
        .get();

    List<Map<String, dynamic>> strengthExercises = strengthSnap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['docId'] = doc.id;
      data['type'] = 'strength';
      return data;
    }).toList();

    final allExercises = <Map<String, dynamic>>[]
      ..addAll(cardioExercises)
      ..addAll(strengthExercises);

    exerciseTotal = allExercises.fold(0.0, (sum, item) {
      return sum + ((item['calories_burned'] as num?)?.toDouble() ?? 0.0);
    });

    final todayDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('logs')
        .doc(todayStr);

    final todayDocSnap = await todayDocRef.get();
    if (todayDocSnap.exists) {
      final todayData = todayDocSnap.data();
      if (todayData != null && todayData['water'] != null) {
        waterTotal = ((todayData['water']['total_water_ml'] as num?)?.toDouble() ?? 0.0);
      }
    }

    final goalEnabled = prefs.getBool('goal_alert_enabled') ?? false;
    final goalShownDate = prefs.getString('goal_alert_shown_date') ?? '';
    if (goalEnabled && foodTotal >= goal && goalShownDate != todayStr) {
      NotificationService().showNotification(
        id: NotificationService.goalId,
        channelId: NotificationService.goalChannelId,
        channelName: 'Goal Achievement Alerts',
        title: "🎉 Congratulations!",
        body: "You’ve hit your daily calorie goal of ${goal.toStringAsFixed(0)} cal.",
      );
      prefs.setString('goal_alert_shown_date', todayStr);
    }

    final inactivityEnabled = prefs.getBool('inactivity_alert_enabled') ?? false;
    if (inactivityEnabled) {
      DateTime? lastExercise;
      final recentSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(todayStr)
          .collection('exercise')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (recentSnap.docs.isNotEmpty) {
        lastExercise = (recentSnap.docs.first.data()['timestamp'] as Timestamp).toDate();
      } else {
        final yesterdayStr = DateFormat('yyyy-MM-dd')
            .format(DateTime.now().subtract(const Duration(days: 1)));
        final prevSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('logs')
            .doc(yesterdayStr)
            .collection('exercise')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (prevSnap.docs.isNotEmpty) {
          lastExercise = (prevSnap.docs.first.data()['timestamp'] as Timestamp).toDate();
        }
      }

      if (lastExercise != null) {
        final diff = DateTime.now().difference(lastExercise);
        final lastInactivityAlertDate = prefs.getString('inactivity_alert_shown_date') ?? '';

        if (diff.inHours >= 48 && lastInactivityAlertDate != todayStr) {
          NotificationService().showNotification(
            id: NotificationService.inactivityId,
            channelId: NotificationService.inactivityChannelId,
            channelName: 'Inactivity Alerts',
            title: "👟 Time to Move!",
            body: "You haven’t logged exercise in over 48 hours. Let’s get active!",
          );

          prefs.setString('inactivity_alert_shown_date', todayStr);
        }
      }
    }

    setState(() {
      meals = updatedMeals;
      totalFood = foodTotal;
      totalExercise = exerciseTotal;
      exercises = allExercises;
      totalWater = waterTotal;
    });
  }

  Widget _buildCalorieBoard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double remaining = (goal - totalFood + totalExercise);
    final double progress = (goal > 0) ? ((goal - totalFood + totalExercise) / goal).clamp(0.0, 1.0) : 0.0;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorScheme.primary, colorScheme.secondary],
    );

    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CalorieDetailsPage()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(1.0),
        child: Card(
          color: colorScheme.surface,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: gradient,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.local_fire_department, color: colorScheme.onPrimary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Calories",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Remaining = Goal – Food + Exercise",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            remaining.toStringAsFixed(0),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: remaining < 0 ? colorScheme.error : colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Remaining",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCalorieItem(Icons.flag, "Goal", goal.toStringAsFixed(0), colorScheme.primary),
                    _buildCalorieItem(Icons.restaurant, "Food", totalFood.toStringAsFixed(0), colorScheme.error),
                    _buildCalorieItem(Icons.fitness_center, "Exercise", totalExercise.toStringAsFixed(0), colorScheme.secondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieItem(IconData icon, String label, String value, Color iconColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 8),
        Text(
          "$label\n$value",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void showAddOtherDialog({
    Map<String, dynamic>? existingFood,
    String? docId,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController _nameController = TextEditingController(
      text: existingFood?['name'] ?? '',
    );
    final TextEditingController _calController = TextEditingController(
      text: existingFood != null
          ? (existingFood['calories']?.toString() ?? existingFood['total_calories']?.toString() ?? '')
          : '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext innerContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existingFood == null ? "Add Custom Food" : "Edit Custom Food",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: theme.inputDecorationTheme.labelStyle,
                    hintText: 'e.g. “Homemade Soup”',
                    hintStyle: theme.inputDecorationTheme.hintStyle,
                    border: theme.inputDecorationTheme.border,
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _calController,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    labelStyle: theme.inputDecorationTheme.labelStyle,
                    hintText: 'e.g. 250',
                    hintStyle: theme.inputDecorationTheme.hintStyle,
                    border: theme.inputDecorationTheme.border,
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                  ),
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(innerContext).pop(false);
              },
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
                final String name = _nameController.text.trim();
                final double? cal = double.tryParse(_calController.text.trim());

                if (name.isEmpty || cal == null || cal <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Please enter a valid name and calorie amount.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      backgroundColor: colorScheme.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final now = DateTime.now();
                final String today = DateFormat('yyyy-MM-dd').format(now);

                final Map<String, dynamic> entry = {
                  'name': name,
                  'calories': cal,
                  'servings': 1,
                  'total_calories': cal,
                  'timestamp': FieldValue.serverTimestamp(),
                };

                final String userId = FirebaseAuth.instance.currentUser!.uid;
                final CollectionReference othersRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('logs')
                    .doc(today)
                    .collection('others');

                try {
                  if (docId != null) {
                    await othersRef.doc(docId).update(entry);
                  } else {
                    await othersRef.add(entry);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Error saving to Firestore: $e",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      backgroundColor: colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                Navigator.of(innerContext).pop(true);
              },
              child: Text(
                existingFood == null ? "Add" : "Update",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    ).then((didChange) {
      if (didChange == true) {
        fetchLoggedEntries();
      }
    });
  }

  Widget _buildFormulaCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double remaining = (goal - totalFood + totalExercise);
    return Card(
      color: colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Calories Remaining",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _valueColumn(goal.toStringAsFixed(0), "Goal"),
                Text(
                  "–",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                _valueColumn(totalFood.toStringAsFixed(0), "Food"),
                Text(
                  "+",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                _valueColumn(totalExercise.toStringAsFixed(0), "Exercise"),
                Text(
                  "=",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                _valueColumn(
                  remaining.toStringAsFixed(0),
                  "Remaining",
                  isBold: true,
                  textColor: remaining < 0 ? colorScheme.error : colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueColumn(
      String number,
      String label, {
        bool isBold = false,
        Color? textColor,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          number,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: textColor ?? colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(String meal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final List<Map<String, dynamic>> items = meals[meal.toLowerCase()] ?? [];
    final String capitalMeal = meal[0].toUpperCase() + meal.substring(1);
    final double mealTotal = items.fold(
      0.0,
          (sum, item) => sum + (item['total_calories'] ?? 0),
    );

    return Card(
      color: colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  capitalMeal,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (meal == 'others') {
                      showAddOtherDialog();
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFoodPage(mealType: meal, userId: userId),
                        ),
                      );
                      if (result == true) fetchLoggedEntries();
                    }
                  },
                  child: Text(
                    "Add Food",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "No items added yet",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
            else
              Column(
                children: items.map((item) {
                  final safeItem = {
                    'name': item['name'] ?? '',
                    'calories': item['calories'] ?? item['total_calories'] ?? 0,
                    'serving_size': item['serving_size'] ?? '',
                    'servings': item['servings'] ?? 1,
                    'nutrients': {
                      'carbohydrates': item['carbohydrates'] ?? item['carbs'] ?? 0,
                      'fat': item['fat'] ?? 0,
                      'protein': item['protein'] ?? 0,
                    },
                  };
                  final String docId = item['docId'] ?? '';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        "${item['name']} (${item['servings']}×)",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "${(item['total_calories']).toStringAsFixed(0)} cal",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, size: 24, color: colorScheme.error),
                        onPressed: () async {
                          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(userId)
                              .collection("logs")
                              .doc(today)
                              .collection(meal)
                              .doc(docId)
                              .delete();
                          fetchLoggedEntries();
                        },
                      ),
                      onTap: () async {
                        if (meal == 'others') {
                          showAddOtherDialog(existingFood: item, docId: docId);
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailPage(
                                foodData: safeItem,
                                mealType: meal,
                                userId: userId,
                                docId: docId,
                              ),
                            ),
                          );
                          if (result == true) fetchLoggedEntries();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Divider(color: colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total: ${mealTotal.toStringAsFixed(0)} cal",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Card(
      color: colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "💪 Exercises",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _showExerciseDialog,
                  child: Text(
                    "Add Exercise",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "No exercises logged yet",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
            else
              Column(
                children: exercises.map((e) {
                  final String name = e['name'] ?? '';
                  final String type = e['type'] ?? 'cardio';
                  final String docId = e['docId'] ?? '';
                  final String calories = (e['calories_burned'] ?? 0).toStringAsFixed(0);
                  final String subtitle = (e['minutes'] != null)
                      ? "${e['minutes']} min"
                      : "${e['sets'] ?? '0'} sets";

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "$subtitle • $calories cal",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, size: 24, color: colorScheme.error),
                        onPressed: () async {
                          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(userId)
                              .collection("logs")
                              .doc(today)
                              .collection(type)
                              .doc(docId)
                              .delete();
                          fetchLoggedEntries();
                        },
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => (type == 'cardio')
                                ? CardioDetailPage(
                              exerciseData: e,
                              docId: docId,
                              userId: userId,
                            )
                                : StrengthDetailPage(
                              exerciseData: e,
                              docId: docId,
                              userId: userId,
                            ),
                          ),
                        );
                        if (result == true) fetchLoggedEntries();
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Card(
      color: colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "💧 Water Intake",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddWaterPage(userId: userId),
                      ),
                    );
                    if (result == true) fetchLoggedEntries();
                  },
                  icon: Icon(Icons.local_drink, color: colorScheme.onPrimary, size: 20),
                  label: Text(
                    "Add",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(80, 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4),
              child: Text(
                "Total: ${totalWater.toStringAsFixed(0)} ml",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            "Add Exercise",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Divider(color: colorScheme.onSurface.withOpacity(0.3)),
          ListTile(
            leading: Icon(Icons.directions_run, color: colorScheme.primary),
            title: Text(
              "Cardiovascular",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCardioPage(userId: FirebaseAuth.instance.currentUser!.uid),
                ),
              );
              if (result == true) fetchLoggedEntries();
            },
          ),
          ListTile(
            leading: Icon(Icons.fitness_center, color: colorScheme.secondary),
            title: Text(
              "Strength",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddStrengthPage(userId: FirebaseAuth.instance.currentUser!.uid),
                ),
              );
              if (result == true) fetchLoggedEntries();
            },
          ),
          const SizedBox(height: 16),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) {
            return gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            "NutriStep",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: colorScheme.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalorieBoard(),
            const SizedBox(height: 20),
            _buildFormulaCard(),
            const SizedBox(height: 24),
            NativeAdCard(),
            const SizedBox(height: 24),
            Text(
              "🍽 Add Food",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildMealSection("breakfast"),
            _buildMealSection("lunch"),
            _buildMealSection("dinner"),
            _buildMealSection("others"),
            const SizedBox(height: 24),
            _buildExerciseSection(),
            const SizedBox(height: 24),
            _buildWaterSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                runSpacing: 12,
                children: [
                  ListTile(
                    leading: Icon(Icons.fastfood, color: colorScheme.primary),
                    title: Text(
                      "Add Food",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFoodPage(
                            mealType: "breakfast",
                            userId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      ).then((res) {
                        if (res == true) fetchLoggedEntries();
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fitness_center, color: colorScheme.secondary),
                    title: Text(
                      "Add Exercise",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showExerciseDialog();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.local_drink, color: Colors.blue),
                    title: Text(
                      "Add Water",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddWaterPage(userId: FirebaseAuth.instance.currentUser!.uid),
                        ),
                      ).then((res) {
                        if (res == true) fetchLoggedEntries();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}