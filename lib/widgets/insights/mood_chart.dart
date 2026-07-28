import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:naya/models/InsightModel.dart' show InsightPeriod;
import 'package:naya/services/MoodChartService.dart';

class MoodPoint {
  final int dayIndex;
  final double mood;

  MoodPoint({required this.dayIndex, required this.mood});
}

class MoodChart extends StatefulWidget {
  final InsightPeriod period;
  const MoodChart({super.key, required this.period});

  @override
  State<MoodChart> createState() => _MoodChartState();
}

class _MoodChartState extends State<MoodChart> {
  late Future<List<MoodPoint>> moodFuture;

  @override
  void initState() {
    super.initState();
   refresh();
  }

  void refresh() {
    if (!mounted) return;

    setState(() {
       moodFuture = MoodChartService().loadWeekMood();
    });
  }

  String getWeekRange() {
    final now = DateTime.now();

    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));

   final months = [
  "",
  "jan".tr(),
  "feb".tr(),
  "mar".tr(),
  "apr".tr(),
  "may".tr(),
  "jun".tr(),
  "jul".tr(),
  "aug".tr(),
  "sep".tr(),
  "oct".tr(),
  "nov".tr(),
  "dec".tr(),
];

    return "${months[start.month]} ${start.day} - ${months[end.month]} ${end.day}";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MoodPoint>>(
      future: moodFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 400,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 400,
            alignment: Alignment.center,
            child: Text("unable_to_load_mood_data".tr()),
          );
        }

        final points = snapshot.data ?? [];

        if (points.isEmpty) {
          return Container(
            height: 400,
            width: 500,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, size: 60, color: Theme.of(context).iconTheme.color,),
                  SizedBox(height: 16),
                  Text(
                    "no_mood_data_this_week".tr(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "start_chatting_mood_trend".tr(),
                    style: TextStyle(color: Theme.of(context).iconTheme.color,),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 400,
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(.04),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "mood_trend".tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        getWeekRange(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Expanded(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, animationValue, child) {
                    return LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: 4,

                        borderData: FlBorderData(show: false),

                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              dashArray: [6, 6],
                              strokeWidth: 1,
                            );
                          },
                        ),

                        /// TOOLTIP
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                return LineTooltipItem(
                                  "${"mood".tr()}: ${spot.y.toStringAsFixed(1)}",
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),

                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const emojis = ["😭", "☹️", "😐", "🙂", "😊"];

                                if (value < 0 || value > 4) {
                                  return const SizedBox();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    emojis[value.toInt()],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                );
                              },
                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (value, meta) {
                                final days = [
                                  "mon".tr(),
                                  "tue".tr(),
                                  "wed".tr(),
                                  "thu".tr(),
                                  "fri".tr(),
                                  "sat".tr(),
                                  "sun".tr(),
                                ];

                                if (value < 0 || value > 6) {
                                  return const SizedBox();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: const Color(0xff7B4DFF),
                            barWidth: 4,
                            isStrokeCapRound: true,

                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: const Color(0xff7B4DFF),
                                );
                              },
                            ),

                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xff7B4DFF).withOpacity(.20),
                                  Colors.transparent,
                                ],
                              ),
                            ),

                            spots: points
                                .map(
                                  (e) => FlSpot(
                                    e.dayIndex.toDouble(),
                                    e.mood * animationValue,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
