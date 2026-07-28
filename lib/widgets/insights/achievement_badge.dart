import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';

class AchievementTile extends StatelessWidget {
  final AchievementModel achievement;

  const AchievementTile({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final percent = (achievement.progress / achievement.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: achievement.color.withOpacity(.07),
        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: achievement.color.withOpacity(.20)),
      ),

      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: achievement.color,
                child: Icon(achievement.icon, color: Colors.white),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      achievement.category,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              _levelBadge(achievement.level),
            ],
          ),

          const SizedBox(height: 18),

          LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(30),
            color: achievement.color,
            backgroundColor: Colors.grey.shade300,
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${achievement.progress}/${achievement.target}"),

              Text(
                achievement.unlocked ? "completed".tr() : "in_progress".tr(),
                style: TextStyle(
                  color: achievement.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(String level) {
    Color color;

    IconData icon;

    switch (level) {
      case "Gold":
        color = Colors.amber;
        icon = Icons.workspace_premium;
        break;

      case "Silver":
        color = Colors.grey;
        icon = Icons.military_tech;
        break;

      default:
        color = Colors.brown;
        icon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),

          const SizedBox(width: 4),

          Text(
            level.toLowerCase().tr(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
