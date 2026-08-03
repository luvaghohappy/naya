import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/InsightModel.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyReportCard extends StatefulWidget {
  final InsightPeriod period;

  final DateTime selectedDate;

  const WeeklyReportCard({
    super.key,
    required this.period,
    required this.selectedDate,
  });

  @override
  State<WeeklyReportCard> createState() => _WeeklyReportCardState();
}

class _WeeklyReportCardState extends State<WeeklyReportCard> {
  late Future<ReportModel> future;

    late final StreamSubscription<AuthState> authSubscription;

  @override
  void initState() {
    super.initState();
    future = ReportService().loadReport(widget.period, widget.selectedDate);
    refresh();

     authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
    refresh();
  });
  }

  @override
void dispose() {
  authSubscription.cancel();
  super.dispose();
}

  Future<void> refresh() async {
    if (!mounted) return;

    setState(() {
      future = ReportService().loadReport(widget.period, widget.selectedDate);
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyReportCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period ||
        oldWidget.selectedDate != widget.selectedDate) {
      refresh();
      setState(() {
        future = ReportService().loadReport(widget.period, widget.selectedDate);
      });
    }
  }

  String get title {
    switch (widget.period) {
      case InsightPeriod.daily:
        return "daily_report".tr();

      case InsightPeriod.weekly:
        return "weekly_report".tr();

      case InsightPeriod.monthly:
        return "monthly_report".tr();
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
              Icon(Icons.person_off_outlined, size: 42, color: Colors.grey),
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
    return FutureBuilder<ReportModel>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final report = snapshot.data!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            // border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ReportTile(
                      icon: Icons.mood,
                      color: Colors.green,
                      title: "dominant_emotion".tr(),
                      value: report.dominantEmotion,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ReportTile(
                      icon: Icons.sentiment_satisfied,
                      color: Colors.deepPurple,
                      title: "mood_score".tr(),
                      value: "${report.moodScore}/100",
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ReportTile(
                      icon: Icons.thumb_up,
                      color: Colors.orange,
                      title: "positive_mood".tr(),
                      value: "${report.positivePercent}%",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: ReportTile(
                      icon: Icons.warning_amber,
                      color: Colors.red,
                      title: "stress_level".tr(),
                      value: "${report.stressLevel}/100",
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ReportTile(
                      icon: Icons.bedtime,
                      color: Colors.blue,
                      title: "sleep_quality".tr(),
                      value: "${report.sleepQuality}/100",
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ReportTile(
                      icon: Icons.bolt,
                      color: Colors.amber,
                      title: "energy_level".tr(),
                      value: "${report.energyLevel}/100",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: ReportTile(
                      icon: Icons.self_improvement,
                      color: Colors.teal,
                      title: "mindfulness".tr(),
                      value: "${report.mindfulnessScore}/100",
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ReportTile(
                      icon: Icons.chat,
                      color: Colors.pink,
                      title: "conversations".tr(),
                      value: "${report.totalConversations}",
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ReportTile(
                      icon: Icons.timer,
                      color: Colors.indigo,
                      title: "minutes".tr(),
                      value: "${report.totalMinutes} min",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xff6C63FF),
                      child: Icon(Icons.auto_awesome, color: Colors.white),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Text(
                        report.summary.tr(),
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportTile extends StatelessWidget {
  final IconData icon;

  final Color color;

  final String title;

  final String value;

  const ReportTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 18),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
