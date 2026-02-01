

import '../models/user_prefernces.dart';

class CalorieCalculator {
  final double weightKg;
  final double heightCm;
  final int    age;
  final String gender; // "male" or "female"
  final ActivityLevel activity;
  final GoalType      goal;

  CalorieCalculator({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activity,
    required this.goal,
  });

  double _bmr() {
    if (gender.toLowerCase() == 'male') {
      return 10*weightKg + 6.25*heightCm - 5*age + 5;
    } else {
      return 10*weightKg + 6.25*heightCm - 5*age - 161;
    }
  }

  double _activityFactor() {
    switch (activity) {
      case ActivityLevel.sedentary: return 1.2;
      case ActivityLevel.moderate:  return 1.375;
      case ActivityLevel.active:    return 1.55;
    }
  }

  double _goalAdjustment() {
    switch (goal) {
      case GoalType.loseWeight:     return -500;
      case GoalType.maintain: return    0;
      case GoalType.gainMuscle:     return 300;
    }
  }

  /// Final daily calorie target
  double calculate() {
    final base = _bmr() * _activityFactor();
    return base + _goalAdjustment();
  }
}
