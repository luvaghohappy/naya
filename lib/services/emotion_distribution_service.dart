import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/period_helper.dart';
import '../models/InsightModel.dart';
import '../widgets/insights/emotion_distribution.dart';

class EmotionDistributionService {
  final supabase = Supabase.instance.client;

  Future<List<EmotionDistributionModel>> loadDistribution(
    InsightPeriod period,
    DateTime selectedDate,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in".tr());
    }

    // ============================================================
    // DAILY
    // ============================================================

    if (period == InsightPeriod.daily) {
      final day = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final date = day.toIso8601String().split("T").first;

      final response = await supabase
          .from("daily_insights")
          .select("dominant_emotion")
          .eq("user_id", user.id)
          .eq("period_start", date)
          .maybeSingle();

      if (response == null ||
          response["dominant_emotion"] == null ||
          response["dominant_emotion"].toString().isEmpty) {
        return [];
      }

      final emotion = response["dominant_emotion"].toString();

      return [
        EmotionDistributionModel(
          emotion: emotion,
          count: 1,
          percent: 1.0,
          color: emotionColor(emotion),
          emoji: emotionEmoji(emotion),
        ),
      ];
    }

    // ============================================================
    // WEEKLY / MONTHLY
    // ============================================================

    final range = PeriodHelper.getRange(period, selectedDate);

    final response = await supabase
        .from("mood_history")
        .select("mood")
        .eq("user_id", user.id)
        .gte("created_at", range.start.toIso8601String())
        .lt("created_at", range.end.toIso8601String());

    if (response.isEmpty) {
      return [];
    }

    final Map<String, int> counter = {};

    for (final item in response) {
      final emotion = (item["mood"] ?? "Unknown").toString().trim();

      counter[emotion] = (counter[emotion] ?? 0) + 1;
    }

    final total = response.length;

    final result = counter.entries.map((entry) {
      return EmotionDistributionModel(
        emotion: entry.key,
        count: entry.value,
        percent: entry.value / total,
        color: emotionColor(entry.key),
        emoji: emotionEmoji(entry.key),
      );
    }).toList();

    result.sort((a, b) => b.count.compareTo(a.count));

    return result;
  }

  Color emotionColor(String emotion) {
    switch (emotion.toLowerCase().trim()) {
      case "happy":
      case "joy":
        return Colors.deepPurple;

      case "calm":
        return Colors.green;

      case "sad":
      case "sadness":
        return Colors.blue;

      case "anxiety":
      case "anxious":
        return Colors.orange;

      case "anger":
      case "angry":
        return Colors.red;

      case "stress":
        return Colors.deepPurple;

      case "depressed":
      case "depression":
        return Colors.blueGrey;

      case "fear":
        return Colors.teal;

      case "hope":
        return Colors.pink;

      case "gratitude":
        return Colors.amber;

      case "neutral":
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  String emotionEmoji(String emotion) {
    switch (emotion.toLowerCase().trim()) {
      case "happy":
      case "joy":
        return "😊";

      case "calm":
        return "😌";

      case "sad":
      case "sadness":
        return "😢";

      case "anxiety":
      case "anxious":
        return "😰";

      case "stress":
        return "😫";

      case "hope":
        return "🌈";

      case "gratitude":
        return "🙏";

      case "depressed":
      case "depression":
        return "😞";

      case "anger":
      case "angry":
        return "😠";

      case "fear":
        return "😨";

      case "neutral":
        return "😐";

      default:
        return "🙂";
    }
  }
}
