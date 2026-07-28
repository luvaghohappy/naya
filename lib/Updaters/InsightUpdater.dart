import 'package:supabase_flutter/supabase_flutter.dart';

class InsightUpdater {

  Future<void> refreshInsights() async {

  await updateMoodHistory(emotion: '', moodScore: 0);

  await updateWeeklyInsights();

  await updateWeeklyReport();

}

 final supabase = Supabase.instance.client;

  /// ===========================
  /// Mood History
  /// ===========================
  Future<void> updateMoodHistory({
    required String emotion,
    required int moodScore,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase.from("mood_history").insert({
      "user_id": user.id,
      "mood": emotion,
      "mood_score": moodScore,
    });
  }

  /// ===========================
  /// Weekly Insights
  /// ===========================
  Future<void> updateWeeklyInsights() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    // We'll implement this next.
  }

  /// ===========================
  /// Weekly Report
  /// ===========================
  Future<void> updateWeeklyReport() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    // We'll implement this next.
  }

}