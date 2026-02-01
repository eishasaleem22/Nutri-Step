/// In lib/models/user_preferences.dart (for example):

/// Represents the user’s chosen activity multiplier.
enum ActivityLevel {
  sedentary,  // little or no exercise
  moderate,   // moderate exercise/sports 3–5 days/week
  active,     // hard exercise/sports 6–7 days a week
}

/// Represents the user’s fitness goal.
enum GoalType {
  loseWeight,   // calorie deficit
  maintain,     // calorie maintenance
  gainMuscle,   // calorie surplus
}
// in lib/models/user_preferences.dart

ActivityLevel parseActivity(String raw) {
  switch (raw.toLowerCase()) {
    case 'sedentary': return ActivityLevel.sedentary;
    case 'moderate':  return ActivityLevel.moderate;
    case 'active':    return ActivityLevel.active;
    default:          return ActivityLevel.moderate;
  }
}

GoalType parseGoal(String raw) {
  switch (raw.toLowerCase()) {
    case 'lose weight': return GoalType.loseWeight;
    case 'stay fit':    return GoalType.maintain;
    case 'gain muscle': return GoalType.gainMuscle;
    default:            return GoalType.maintain;
  }
}
