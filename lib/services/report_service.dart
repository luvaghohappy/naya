import 'package:easy_localization/easy_localization.dart';
import 'package:naya/helpers/period_helper.dart';
import 'package:naya/models/InsightModel.dart';
import 'package:naya/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final supabase = Supabase.instance.client;

  Future<ReportModel> loadReport(
    InsightPeriod period,
    DateTime selectedDate,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("user_not_authenticated".tr());
    }

    String table;
    DateTime periodStart;

    switch (period) {
      case InsightPeriod.daily:
        table = "daily_insights";
        periodStart = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        break;

      case InsightPeriod.weekly:
        table = "weekly_insights";
        periodStart = PeriodHelper.getRange(period, selectedDate).start;
        break;

      case InsightPeriod.monthly:
        table = "monthly_insights";
        periodStart = DateTime(selectedDate.year, selectedDate.month, 1);
        break;
    }

    final response = await supabase
        .from(table)
        .select()
        .eq("user_id", user.id)
        .eq("period_start", periodStart.toIso8601String().split("T").first)
        .maybeSingle();

    if (response == null) {
      return ReportModel(
        dominantEmotion: "unknown_emotion".tr(),
        moodScore: 0,
        positivePercent: 0,
        stressLevel: 0,
        sleepQuality: 0,
        energyLevel: 0,
        mindfulnessScore: 0,
        totalMinutes: 0,
        totalConversations: 0,
        summary: "no_report".tr(),
      );
    }

    return ReportModel(
      dominantEmotion: response["dominant_emotion"] ?? "unknown_emotion".tr(),
      moodScore: (response["mood_score"] ?? 0) as int,
      positivePercent: (response["positive_percent"] ?? 0) as int,
      stressLevel: (response["stress_level"] ?? 0) as int,
      sleepQuality: (response["sleep_quality"] ?? 0) as int,
      energyLevel: (response["energy_level"] ?? 0) as int,
      mindfulnessScore: (response["mindfulness_score"] ?? 0) as int,
      totalConversations: (response["total_conversations"] ?? 0) as int,
      totalMinutes: (response["total_minutes"] ?? 0) as int,
      summary: response["summary"] ?? "",
    );
  }
}
