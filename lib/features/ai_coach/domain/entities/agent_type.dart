enum AgentType {
  workoutCoach,
  nutritionCoach,
  recoveryCoach,
  motivationCoach,
  mealAnalysis,
  dailyPlanner;

  String get key => switch (this) {
        AgentType.workoutCoach => 'workout_coach',
        AgentType.nutritionCoach => 'nutrition_coach',
        AgentType.recoveryCoach => 'recovery_coach',
        AgentType.motivationCoach => 'motivation_coach',
        AgentType.mealAnalysis => 'meal_analysis',
        AgentType.dailyPlanner => 'daily_planner',
      };

  String get label => switch (this) {
        AgentType.workoutCoach => 'Workout Coach',
        AgentType.nutritionCoach => 'Nutrition Coach',
        AgentType.recoveryCoach => 'Recovery Coach',
        AgentType.motivationCoach => 'Motivation Coach',
        AgentType.mealAnalysis => 'Meal Analysis',
        AgentType.dailyPlanner => 'Daily Planner',
      };

  String get description => switch (this) {
        AgentType.workoutCoach => 'Programming, form cues, and progression',
        AgentType.nutritionCoach => 'Macros, meal ideas, and nutrition Q&A',
        AgentType.recoveryCoach => 'Sleep, mobility, and avoiding burnout',
        AgentType.motivationCoach => 'Accountability and encouragement',
        AgentType.mealAnalysis => 'Photo-based nutrition estimates',
        AgentType.dailyPlanner => "Your full day's plan in one shot",
      };

  static AgentType fromKey(String key) =>
      AgentType.values.firstWhere((e) => e.key == key, orElse: () => AgentType.workoutCoach);

  /// Agents surfaced as conversational chat tabs. `mealAnalysis` and
  /// `dailyPlanner` are invoked as structured one-shot actions from the
  /// nutrition and home screens instead.
  static const chatAgents = [
    AgentType.workoutCoach,
    AgentType.nutritionCoach,
    AgentType.recoveryCoach,
    AgentType.motivationCoach,
  ];
}
