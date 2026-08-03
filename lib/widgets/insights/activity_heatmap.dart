import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/activity_heatmap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityModel {
  final DateTime day;
  final int count;

  ActivityModel({required this.day, required this.count});
}

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({super.key});

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  late Future<List<ActivityModel>> future;

   late final StreamSubscription<AuthState> authSubscription;


  @override
  void initState() {
    super.initState();
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


  void refresh() {
    if (!mounted) return;

    setState(() {
       future = ActivityHeatmapService().loadActivity();
    });
  }

  Color activityColor(int value) {
    if (value == 0) {
      return Colors.grey.shade200;
    }

    if (value <= 2) {
      return Colors.deepPurple.shade100;
    }

    if (value <= 5) {
      return Colors.deepPurple.shade200;
    }

    if (value <= 8) {
      return Colors.deepPurple.shade300;
    }

    return Colors.deepPurple;
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

    return FutureBuilder<List<ActivityModel>>(
      future: future,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final activity = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            // border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(24),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "activity".tr(),

                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 6,

                runSpacing: 6,

                children: activity.map((day) {
                  return Tooltip(
                    message:
                        "${day.count} conversation${day.count == 1 ? "" : "s"}",

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),

                      width: 22,

                      height: 22,

                      decoration: BoxDecoration(
                        color: activityColor(day.count),

                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "less".tr(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  const SizedBox(width: 8),

                  ...[
                    Colors.grey.shade200,
                    Colors.deepPurple.shade100,
                    Colors.deepPurple.shade200,
                    Colors.deepPurple.shade300,
                    Colors.deepPurple,
                  ].map(
                    (color) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    "more".tr(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
