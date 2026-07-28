import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement_model.dart';

class AchievementService {
  final supabase = Supabase.instance.client;

  Future<List<AchievementModel>> loadAchievements() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    //--------------------------------------------------
    // Conversations
    //--------------------------------------------------

    final conversations = await supabase
        .from("Conversations")
        .select("created_at")
        .eq("user_id", user.id);

    final conversationCount = conversations.length;

    //--------------------------------------------------
    // Messages
    //--------------------------------------------------

    final messages = await supabase
        .from("Messages")
        .select("message_id")
        .eq("user_id", user.id);

    final messageCount = messages.length;

    //--------------------------------------------------
    // Mood History
    //--------------------------------------------------

    final moods = await supabase
        .from("mood_history")
        .select("created_at")
        .eq("user_id", user.id);

    final moodCount = moods.length;

    //--------------------------------------------------
    // Daily Insights
    //--------------------------------------------------

    final daily = await supabase
        .from("daily_insights")
        .select("id")
        .eq("user_id", user.id);

    final dailyCount = daily.length;

    //--------------------------------------------------
    // Weekly Insights
    //--------------------------------------------------

    final weekly = await supabase
        .from("weekly_insights")
        .select("id")
        .eq("user_id", user.id);

    final weeklyCount = weekly.length;

    //--------------------------------------------------
    // Monthly Insights
    //--------------------------------------------------

    final monthly = await supabase
        .from("monthly_insights")
        .select("id")
        .eq("user_id", user.id);

    final monthlyCount = monthly.length;

    //--------------------------------------------------
    // Active Minutes
    //--------------------------------------------------

    final minutes = await supabase
        .from("Conversations")
        .select("duration_minutes")
        .eq("user_id", user.id);

    int totalMinutes = 0;

    for (final row in minutes) {
      totalMinutes += (row["duration_minutes"] as num?)?.toInt() ?? 0;
    }

    //--------------------------------------------------
    // Streak
    //--------------------------------------------------

    final streak = _calculateStreak(conversations);

    //--------------------------------------------------
    // Achievement List
    //--------------------------------------------------

    final achievements = [
      createAchievement(
        id: "messages",
        title: "message_explorer".tr(),
        category: "messages_Insight".tr(),
        value: messageCount,
        icon: Icons.message,
      ),

      createAchievement(
        id: "conversations",
        title: "conversation_master".tr(),
        category: "conversations".tr(),
        value: conversationCount,
        icon: Icons.chat,
      ),

      createAchievement(
        id: "minutes",
        title: "time_with_naya".tr(),
        category: "minutes_Insight".tr(),
        value: totalMinutes,
        icon: Icons.timer,
      ),

      createAchievement(
        id: "moods",
        title: "mood_tracker".tr(),
        category: "mood_history".tr(),
        value: moodCount,
        icon: Icons.favorite,
      ),

      createAchievement(
        id: "daily",
        title: "daily_reflection".tr(),
        category: "daily_insights".tr(),
        value: dailyCount,
        icon: Icons.today,
      ),

      createAchievement(
        id: "weekly",
        title: "weekly_reflection".tr(),
        category: "weekly_insights".tr(),
        value: weeklyCount,
        icon: Icons.date_range,
      ),

      createAchievement(
        id: "monthly".tr(),
        title: "monthly_reflection".tr(),
        category: "monthly_insights".tr(),
        value: monthlyCount,
        icon: Icons.calendar_month,
      ),

      createAchievement(
        id: "streak".tr(),
        title: "consistency".tr(),
        category: "streak".tr(),
        value: streak,
        icon: Icons.local_fire_department,
      ),
    ];

    await _saveUnlockedAchievements(user.id, achievements);

    return achievements;
  }

  String calculateLevel(int value) {
    if (value >= 500) {
      return "gold".tr();
    }

    if (value >= 100) {
      return "silver".tr();
    }

    return "bronze".tr();
  }

  Color badgeColor(String level) {
    switch (level) {
      case "Gold":
        return Colors.amber;

      case "Silver":
        return Colors.grey;

      default:
        return Colors.brown;
    }
  }

  AchievementModel createAchievement({
    required String id,
    required String title,
    required String category,
    required int value,
    required IconData icon,
  }) {
    final level = calculateLevel(value);

    return AchievementModel(
      id: id,
      title: title,
      category: category,
      level: level,
      icon: icon,
      color: badgeColor(level),
      progress: value,
      target: calculateTarget(value),
      unlocked: value >= 1,
    );
  }

  int calculateTarget(int value) {
    if (value < 100) {
      return 100;
    }

    if (value < 500) {
      return 500;
    }

    return 500;
  }

  Future<void> _saveUnlockedAchievements(
    String userId,
    List<AchievementModel> achievements,
  ) async {
    for (final achievement in achievements) {
      final exists = await supabase
          .from("user_achievements")
          .select()
          .eq("user_id", userId)
          .eq("achievement_id", achievement.id)
          .maybeSingle();

      if (exists == null) {
        await supabase.from("user_achievements").insert({
          "user_id": userId,
          "achievement_id": achievement.id,
          "achievement": achievement.title,
          "category": achievement.category,
          "level": achievement.level,
          "progress": achievement.progress,
          "target": achievement.target,
          "unlocked": achievement.unlocked,
          "unlocked_at": achievement.unlocked
              ? DateTime.now().toIso8601String()
              : null,
        });
      } else {
        await supabase
            .from("user_achievements")
            .update({
              "level": achievement.level,
              "progress": achievement.progress,
              "target": achievement.target,
              "unlocked": achievement.unlocked,
            })
            .eq("achievement_id", achievement.id)
            .eq("user_id", userId);
      }
    }
  }

  int _calculateStreak(List conversations) {
    if (conversations.isEmpty) return 0;

    final dates = conversations
        .map((e) => DateTime.parse(e["created_at"]))
        .map((e) => DateTime(e.year, e.month, e.day))
        .toSet()
        .toList();

    dates.sort();

    int streak = 1;

    for (int i = dates.length - 1; i > 0; i--) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
