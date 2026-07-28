class OverallMoodModel {
  final String emotion;
  final int positivePercent;
  final int previousPercent;

  const OverallMoodModel({
    required this.emotion,
    required this.positivePercent,
    required this.previousPercent,
  });

  bool get isImproving => positivePercent >= previousPercent;

  int get difference => positivePercent - previousPercent;
}

enum InsightPeriod {
  daily,
  weekly,
  monthly,
}