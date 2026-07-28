import 'package:easy_localization/easy_localization.dart';
import 'package:naya/models/InsightModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/period_helper.dart';

class InsightService {
  final supabase = Supabase.instance.client;

  Future<OverallMoodModel> getOverallMood(
    InsightPeriod period,
    DateTime selectedDate,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in".tr());
    }

    final range = PeriodHelper.getRange(period, selectedDate);

    Duration duration = range.end.difference(range.start);

    final previousStart = range.start.subtract(duration);

    final table = switch (period) {
      InsightPeriod.daily => "daily_insights",
      InsightPeriod.weekly => "weekly_insights",
      InsightPeriod.monthly => "monthly_insights",
    };

    final current = await supabase
        .from(table)
        .select()
        .eq("user_id", user.id)
        .gte("period_start", range.start.toIso8601String())
        .lt("period_start", range.end.toIso8601String())
        .maybeSingle();

    final previous = await supabase
        .from(table)
        .select()
        .eq("user_id", user.id)
        .gte("period_start", previousStart.toIso8601String())
        .lt("period_start", range.start.toIso8601String())
        .maybeSingle();

    return OverallMoodModel(
      emotion: current?["dominant_emotion"] ?? "Neutral",
      positivePercent: current?["positive_percent"] ?? 0,
      previousPercent: previous?["positive_percent"] ?? 0,
    );
  }

  _PeriodConfig _getPeriodConfig(InsightPeriod period) {
    final now = DateTime.now();

    switch (period) {
      case InsightPeriod.daily:
        final today = DateTime(now.year, now.month, now.day);

        return _PeriodConfig(
          table: "daily_insights",
          currentStart: today,
          previousStart: today.subtract(const Duration(days: 1)),
        );

      case InsightPeriod.weekly:
        final monday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        return _PeriodConfig(
          table: "weekly_insights",
          currentStart: monday,
          previousStart: monday.subtract(const Duration(days: 7)),
        );

      case InsightPeriod.monthly:
        final firstDay = DateTime(now.year, now.month);

        return _PeriodConfig(
          table: "monthly_insights",
          currentStart: firstDay,
          previousStart: DateTime(now.year, now.month - 1),
        );
    }
  }
}

class _PeriodConfig {
  final String table;
  final DateTime currentStart;
  final DateTime previousStart;

  const _PeriodConfig({
    required this.table,
    required this.currentStart,
    required this.previousStart,
  });
}
