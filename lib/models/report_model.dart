class ReportModel {
  final String dominantEmotion;
  final int moodScore;
  final int positivePercent;
  final int stressLevel;
  final int sleepQuality;
  final int energyLevel;
  final int mindfulnessScore;
  final int totalConversations;
  final int totalMinutes;
  final String summary;

  ReportModel({
    required this.dominantEmotion,
    required this.moodScore,
    required this.positivePercent,
    required this.stressLevel,
    required this.sleepQuality,
    required this.energyLevel,
    required this.mindfulnessScore,
    required this.totalConversations,
    required this.totalMinutes,
    required this.summary,
  });
}