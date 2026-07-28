import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naya/services/analytics_service.dart';
import 'package:naya/widgets/insights/analytics_card.dart';
import '../../models/AnalyticsModel.dart';

class AnalyticsGrid extends StatefulWidget {
  const AnalyticsGrid({super.key});

  @override
  State<AnalyticsGrid> createState() => _AnalyticsGridState();
}

class _AnalyticsGridState extends State<AnalyticsGrid> {
  late Future<AnalyticsModel> analyticsFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    if (!mounted) return;

    setState(() {
      analyticsFuture = AnalyticsService().loadAnalytics();
    });
  }

  Widget buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    bool positive = true,
  }) {
    return Expanded(
      child: AnalyticsCard(
        icon: icon,
        color: color,
        title: title,
        value: value,
        subtitle: subtitle,
        positive: positive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnalyticsModel>(
      future: analyticsFuture,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("Analytics Error: ${snapshot.error}");

          return Center(
            child: Text(
              "unable_to_load_analytics".tr(),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text("no_analytics_data".tr(), textAlign: TextAlign.center),
          );
        }

        final data = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 20),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                "your_journey".tr(),

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  buildCard(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.pink,
                    title: "conversations".tr(),
                    value: "${data.totalConversations}",
                    subtitle: "with_naya".tr(),
                  ),

                  const SizedBox(width: 10),

                  buildCard(
                    icon: Icons.timer_outlined,
                    color: Colors.indigo,
                    title: "active_time".tr(),
                    value: "${data.totalMinutes} min",
                    subtitle: "talking".tr(),
                  ),

                  const SizedBox(width: 10),

                  buildCard(
                    icon: Icons.local_fire_department,
                    color: Colors.deepPurple,
                    title: "streak".tr(),
                    value: "${data.currentStreak}",
                    subtitle: "days".tr(),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  buildCard(
                    icon: Icons.psychology,
                    color: Colors.orange,
                    title: "mood".tr(),
                    value: data.averageMood.toStringAsFixed(0),
                    subtitle: "+${data.moodChange.toStringAsFixed(0)}%",
                  ),

                  const SizedBox(width: 10),

                  buildCard(
                    icon: Icons.warning_amber,
                    color: Colors.red,
                    title: "stress".tr(),
                    value: data.stressLevel,
                    subtitle: data.stressLevel == "low".tr() ? "-18%" : "+15%",
                    positive: data.stressLevel == "low".tr(),
                  ),

                  const SizedBox(width: 10),

                  buildCard(
                    icon: Icons.self_improvement,
                    color: Colors.green,
                    title: "mindfulness".tr(),
                    value: "${data.mindfulness}%",
                    subtitle: "+${data.mindfulnessChange.toStringAsFixed(0)}%",
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  buildCard(
                    icon: Icons.bedtime,
                    color: Colors.blue,
                    title: "sleep".tr(),
                    value: "${data.sleepQuality.toStringAsFixed(1)} hrs",
                    subtitle: "+${data.sleepChange.toStringAsFixed(0)}%",
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
