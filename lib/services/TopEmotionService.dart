import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/period_helper.dart';
import '../models/InsightModel.dart';
import '../models/top_emotion_model.dart';

class TopEmotionService {
  final supabase = Supabase.instance.client;

  Future<List<EmotionStat>> loadTopEmotions(
    InsightPeriod period,
    DateTime selectedDate,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("user_not_logged_in".tr());
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

      return [EmotionStat(emotion: emotion, count: 1, percent: 1.0)];
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

    final Map<String, int> counts = {};

    for (final row in response) {
      final emotion = (row["mood"] ?? "Unknown").toString().trim();

      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }

    final total = response.length;

    final list = counts.entries.map((entry) {
      return EmotionStat(
        emotion: entry.key,
        count: entry.value,
        percent: entry.value / total,
      );
    }).toList();

    list.sort((a, b) => b.count.compareTo(a.count));

    return list.take(5).toList();
  }
}
