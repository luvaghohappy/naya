import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:naya/models/InsightModel.dart' show InsightPeriod;
import '../../services/emotion_distribution_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmotionDistributionModel {
  final String emotion;
  final int count;
  final double percent;
  final Color color;
  final String emoji;

  EmotionDistributionModel({
    required this.emotion,
    required this.count,
    required this.percent,
    required this.color,
    required this.emoji,
  });
}

class EmotionDistribution extends StatefulWidget {
  final InsightPeriod period;
  final DateTime selectedDate;

  const EmotionDistribution({
    super.key,
    required this.period,
    required this.selectedDate,
  });

  @override
  State<EmotionDistribution> createState() => _EmotionDistributionState();
}

class _EmotionDistributionState extends State<EmotionDistribution> {
  late Future<List<EmotionDistributionModel>> future;

  late final StreamSubscription<AuthState> authSubscription;

  @override
  void initState() {
    super.initState();
    refresh();

    authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      refresh();
    });
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  void refresh() {
    if (!mounted) return;

    setState(() {
      future = EmotionDistributionService().loadDistribution(
        widget.period,
        widget.selectedDate,
      );
    });
  }

  @override
  void didUpdateWidget(covariant EmotionDistribution oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period ||
        oldWidget.selectedDate != widget.selectedDate) {
      refresh();
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
    return FutureBuilder<List<EmotionDistributionModel>>(
      future: future,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: Text("no_emotions".tr())),
          );
        }

        final emotions = snapshot.data!;

        return Container(
          width: double.infinity,
          height: 280,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            // border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "emotion_distribution".tr(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          /// Pie Chart
                          SizedBox(
                            width: 88,
                            height: 28,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 25,
                                sectionsSpace: 3,
                                sections: emotions.map((emotion) {
                                  return PieChartSectionData(
                                    value: emotion.percent,

                                    color: emotion.color,

                                    title:
                                        "${(emotion.percent * 100).round()}%",

                                    radius: 30,

                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          Spacer(),

                          /// Legend
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: emotions.map((emotion) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),

                                  child: legend(
                                    emotion.color,

                                    "${emotion.emoji} ${emotion.emotion}",

                                    "${(emotion.percent * 100).round()}%",
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
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

  Widget legend(Color color, String title, String percent) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title.tr(),

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),

        Text(percent, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
