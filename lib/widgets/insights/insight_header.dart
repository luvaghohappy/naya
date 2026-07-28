import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/InsightModel.dart';

class InsightHeader extends StatefulWidget {
  final InsightPeriod period;
  final DateTime selectedDate;

  final ValueChanged<InsightPeriod> onPeriodChanged;
  final ValueChanged<DateTime> onDateChanged;

  const InsightHeader({
    super.key,
    required this.period,
    required this.selectedDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
  });

  @override
  State<InsightHeader> createState() => _InsightHeaderState();
}

class _InsightHeaderState extends State<InsightHeader> {
  String get periodLabel {
    switch (widget.period) {
      case InsightPeriod.daily:
        return "today_Insight".tr();

      case InsightPeriod.weekly:
        return "this_week_Insight".tr();

      case InsightPeriod.monthly:
        return "this_month_Insight".tr();
    }
  }

  String get dateLabel {
    final d = widget.selectedDate;

    switch (widget.period) {
      case InsightPeriod.daily:
        return "${d.day}/${d.month}/${d.year}";

      case InsightPeriod.weekly:
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        return "${monday.day}/${monday.month} - ${sunday.day}/${sunday.month}";

      case InsightPeriod.monthly:
        const months = [
          "",
          "January",
          "February",
          "March",
          "April",
          "May",
          "June",
          "July",
          "August",
          "September",
          "October",
          "November",
          "December",
        ];

        return "${months[d.month]} ${d.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "insights_title".tr(),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "understand_yourself_better".tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.65),
                fontSize: 17,
              ),
            ),
          ],
        ),

        Container(
          margin: const EdgeInsets.only(top: 25),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE5DAFF)),
          ),

          child: Row(
            children: [
              PopupMenuButton<InsightPeriod>(
                onSelected: widget.onPeriodChanged,

                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: InsightPeriod.daily,
                    child: Text("today".tr()),
                  ),

                  PopupMenuItem(
                    value: InsightPeriod.weekly,
                    child: Text("this_week".tr()),
                  ),

                  PopupMenuItem(
                    value: InsightPeriod.monthly,
                    child: Text("this_month".tr()),
                  ),
                ],

                child: Row(
                  children: [
                    Text(
                      periodLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xff6C63FF),
                      ),
                    ),

                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xff6C63FF),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    widget.onDateChanged(picked);
                  }
                },

                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xff6C63FF)),

                    const SizedBox(width: 8),

                    Text(
                      dateLabel.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}
