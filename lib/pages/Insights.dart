import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:naya/widgets/insights/WeeklyReportCard.dart';
import 'package:naya/widgets/insights/analytics_grid.dart';
import 'package:naya/widgets/insights/mood_chart.dart';
import 'package:naya/widgets/insights/top_emotions_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/InsightModel.dart';
import '../widgets/insights/insight_header.dart';
import '../widgets/insights/overall_mood_card.dart';
import '../widgets/insights/emotion_distribution.dart';
import '../widgets/insights/activity_heatmap.dart';
import '../widgets/insights/achievement_card.dart';
import 'package:easy_localization/easy_localization.dart';

class Insights extends StatefulWidget {
  const Insights({super.key});

  @override
  State<Insights> createState() => _InsightsState();
}

class _InsightsState extends State<Insights> {
  InsightPeriod selectedPeriod = InsightPeriod.weekly;

  String nickname = "Friend";

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    await loadNickname();
  }

  Future<void> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nickname = prefs.getString("nickname") ?? "Friend";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              //INSIGHTS HEADER
              FadeInDown(
                child: InsightHeader(
                  period: selectedPeriod,
                  selectedDate: selectedDate,

                  onPeriodChanged: (period) {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },

                  onDateChanged: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),

              //overall mood
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: OverallMoodCard(
                  period: selectedPeriod,
                  selectedDate: selectedDate,
                ),
              ),

              const SizedBox(height: 35),

              //Mood chart
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1200) {
                    // Desktop

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: MoodChart(period: selectedPeriod),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          flex: 4,
                          child: TopEmotionsCard(
                            period: selectedPeriod,
                            selectedDate: selectedDate,
                          ),
                        ),
                      ],
                    );
                  }

                  // Tablet / Small desktop
                  return Column(
                    children: [
                      MoodChart(period: selectedPeriod),

                      const SizedBox(height: 20),

                      TopEmotionsCard(
                        period: selectedPeriod,
                        selectedDate: selectedDate,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1200) {
                    // Desktop

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: EmotionDistribution(
                            period: selectedPeriod,
                            selectedDate: selectedDate,
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(flex: 4, child: const ActivityHeatmap()),
                      ],
                    );
                  }
                  // Tablet / Small desktop
                  return Column(
                    children: [
                      EmotionDistribution(
                        period: selectedPeriod,
                        selectedDate: selectedDate,
                      ),

                      const SizedBox(height: 20),

                      const ActivityHeatmap(),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),

              WeeklyReportCard(
                period: selectedPeriod,
                selectedDate: selectedDate,
              ),

              ///Sta
              const SizedBox(height: 30),
              const AnalyticsGrid(),

              const SizedBox(height: 45),

              const Divider(),

              const SizedBox(height: 30),

              Text(
                "achievements".tr(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                "achievements_description".tr(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),

              const SizedBox(height: 24),

              const AchievementCard(),
            ],
          ),
        ),
      ),
    );
  }
}
