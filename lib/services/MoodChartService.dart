import 'package:naya/widgets/insights/mood_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodChartService {
  final supabase = Supabase.instance.client;

  Future<List<MoodPoint>> loadWeekMood() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final now = DateTime.now();

    // Monday at 00:00:00
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(
      Duration(days: now.weekday - DateTime.monday),
    );

    // Next Monday at 00:00:00
    final endOfWeek = startOfWeek.add(
      const Duration(days: 7),
    );

    final data = await supabase
        .from("Conversations")
        .select("emotion, created_at")
        .eq("user_id", user.id)
        .gte(
          "created_at",
          startOfWeek.toIso8601String(),
        )
        .lt(
          "created_at",
          endOfWeek.toIso8601String(),
        )
        .order(
          "created_at",
          ascending: true,
        );

    // Group moods by day.
    //
  
    final Map<int, List<double>> dailyMoods = {};

    for (final item in data) {
      final emotion = item["emotion"];

      if (emotion == null) continue;

      final date = DateTime.parse(
        item["created_at"],
      );

      // Monday = 0
      // Tuesday = 1
      // ...
      // Sunday = 6
      final dayIndex = date.weekday - DateTime.monday;

      dailyMoods.putIfAbsent(
        dayIndex,
        () => [],
      );

      dailyMoods[dayIndex]!.add(
        getScore(emotion.toString()),
      );
    }

    final List<MoodPoint> points = [];

    dailyMoods.forEach((dayIndex, moods) {
      final averageMood =
          moods.reduce((a, b) => a + b) / moods.length;

      points.add(
        MoodPoint(
          dayIndex: dayIndex,
          mood: averageMood,
        ),
      );
    });

    points.sort(
      (a, b) => a.dayIndex.compareTo(b.dayIndex),
    );

    return points;
  }

  double getScore(String emotion) {
    switch (emotion.toLowerCase()) {
      case "joy":
      case "gratitude":
      case "calm":
        return 4;

      case "hope":
      case "neutral":
        return 3;

      case "stress":
        return 2;

      case "sadness":
      case "fear":
      case "anxiety":
      case "depression":
        return 1;

      case "anger":
        return 0;

      default:
        return 2;
    }
  }
}