import '../models/InsightModel.dart';

class PeriodRange {
  final DateTime start;
  final DateTime end;

  const PeriodRange({
    required this.start,
    required this.end,
  });
}

class PeriodHelper {
  static PeriodRange getRange(
    InsightPeriod period,
    DateTime selectedDate,
  ) {
    switch (period) {
      case InsightPeriod.daily:
        final start = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );

        return PeriodRange(
          start: start,
          end: start.add(const Duration(days: 1)),
        );

      case InsightPeriod.weekly:
        final monday = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        ).subtract(Duration(days: selectedDate.weekday - 1));

        return PeriodRange(
          start: monday,
          end: monday.add(const Duration(days: 7)),
        );

      case InsightPeriod.monthly:
        final firstDay = DateTime(
          selectedDate.year,
          selectedDate.month,
          1,
        );

        final nextMonth = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          1,
        );

        return PeriodRange(
          start: firstDay,
          end: nextMonth,
        );
    }
  }
}