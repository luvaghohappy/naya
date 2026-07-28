class AnalyticsModel {
  final int moodEntries;
  final int currentStreak;
  final double averageMood;
  final double sleepQuality;
  final String stressLevel;
  final int mindfulness;
  final int totalConversations;
  final int totalMinutes;
  final double moodChange;
  final double streakChange;
  final double sleepChange;
  final double mindfulnessChange;

  AnalyticsModel({
    required this.moodEntries,
    required this.currentStreak,
    required this.averageMood,
    required this.sleepQuality,
    required this.stressLevel,
    required this.mindfulness,
    required this.totalConversations,
    required this.totalMinutes,
    required this.moodChange,
    required this.streakChange,
    required this.sleepChange,
    required this.mindfulnessChange,
  });
}