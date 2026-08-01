import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naya/models/InsightModel.dart';
import 'package:naya/services/insight_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OverallMoodCard extends StatefulWidget {
  final InsightPeriod period;
  final DateTime selectedDate;

  const OverallMoodCard({
    super.key,
    required this.period,
    required this.selectedDate,
  });

  @override
  State<OverallMoodCard> createState() => _OverallMoodCardState();
}

class _OverallMoodCardState extends State<OverallMoodCard> {
  final InsightService service = InsightService();

  late Future<OverallMoodModel> moodFuture;

  Future<void> refresh() async {
    if (!mounted) return;

    setState(() {
      moodFuture = service.getOverallMood(widget.period, widget.selectedDate);
    });
  }

  @override
  void initState() {
    super.initState();
    moodFuture = service.getOverallMood(widget.period, widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant OverallMoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period ||
        oldWidget.selectedDate != widget.selectedDate) {
      refresh();

      setState(() {
        moodFuture = service.getOverallMood(widget.period, widget.selectedDate);
      });
    }
  }

  String comparisonText(OverallMoodModel mood) {
    switch (widget.period) {
      case InsightPeriod.daily:
        return mood.isImproving
            ? "better_than_yesterday".tr()
            : "needs_attention".tr();

      case InsightPeriod.weekly:
        return mood.isImproving
            ? "better_than_last_week".tr()
            : "needs_attention".tr();

      case InsightPeriod.monthly:
        return mood.isImproving
            ? "better_than_last_month".tr()
            : "needs_attention".tr();
    }
  }

  String getEmoji(String emotion) {
    switch (emotion) {
      case "Joy":
      case "Happy":
        return "😊";

      case "Stress":
        return "😰";

      case "Anxiety":
        return "😟";

      case "Fear":
        return "😨";

      case "Depression":
        return "😞";

      case "Sadness":
        return "😢";

      case "Anger":
        return "😠";

      default:
        return "😐";
    }
  }

  @override
  Widget build(BuildContext context) {
     final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 42,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              "user_not_logged_in".tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
    return FutureBuilder<OverallMoodModel>(
      future: moodFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint("Overall Mood Error: ${snapshot.error}");

          return SizedBox(
            height: 160,
            child: Center(
              child: Text(
                "unable_to_load_mood_data".tr(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return SizedBox(
            height: 160,
            child: Center(child: Text("no_mood_data_available".tr())),
          );
        }

        final mood = snapshot.data!;

        return Container(
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xffECE5FF)),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [Theme.of(context).cardColor, Color(0xffC8A8FF)],
                  ),
                ),
                child: Center(
                  child: Text(
                    getEmoji(mood.emotion),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "overall_mood".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comparisonText(mood),
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            style: TextStyle(
                              color: mood.isImproving
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      mood.emotion,
                      style: const TextStyle(
                        color: Color(0xff6D3DFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 26,
                    lineWidth: 7,
                    animation: true,
                    percent: mood.positivePercent / 100,
                    progressColor: const Color(0xff6D3DFF),
                    backgroundColor: const Color(0xffECE5FF),
                    circularStrokeCap: CircularStrokeCap.round,
                    center: Text(
                      "${mood.positivePercent}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
