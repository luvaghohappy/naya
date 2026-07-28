import 'package:flutter/material.dart';

class AchievementModel {
  final String id;
  final String title;
  final String category;
  final String level;
  final IconData icon;
  final Color color;
  final int progress;
  final int target;
  final bool unlocked;

  AchievementModel({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.icon,
    required this.color,
    required this.progress,
    required this.target,
    required this.unlocked,
  });

  double get percentage {
    if (target == 0) return 0;

    return (progress / target).clamp(0.0, 1.0);
  }
}