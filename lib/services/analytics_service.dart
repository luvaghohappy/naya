import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/AnalyticsModel.dart';

class AnalyticsService {
  final supabase = Supabase.instance.client;

  Future<AnalyticsModel> loadAnalytics() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("user_not_authenticated".tr());
    }

    /// Mood entries

    final moods = await supabase
        .from('mood_history')
        .select()
        .eq('user_id', user.id);

    int moodEntries = moods.length;

    double averageMood = 0;

    if (moods.isNotEmpty) {
      averageMood =
          moods
              .map((e) => (e['mood_score'] ?? 0) as int)
              .reduce((a, b) => a + b) /
          moods.length;
    }

    /// Conversations analytics

    final conversations = await supabase
        .from('Conversations')
        .select('duration_minutes, created_at')
        .eq('user_id', user.id);

    int totalConversations = conversations.length;

    int totalMinutes = conversations.fold<int>(
      0,
      (sum, item) => sum + ((item['duration_minutes'] ?? 0) as int),
    );

    /// Latest weekly report

    final report = await supabase
        .from('weekly_insights')
        .select()
        .eq('user_id', user.id)
        .order('period_start', ascending: false)
        .limit(1)
        .maybeSingle();

    double sleep = 0;

    if (report != null) {
      sleep = (report['average_sleep'] ?? 0).toDouble();
    }

    /// Streak

    int streak = _calculateStreak(moods);

    /// Stress

    String stress;

    if (averageMood >= 60) {
      stress = "low".tr();
    } else if (averageMood >= 40) {
      stress = "medium".tr();
    } else {
      stress = "high".tr();
    }

    /// Mindfulness

    int mindfulness = moodEntries == 0
        ? 0
        : ((moodEntries / 7) * 100).clamp(0, 100).round();

    return AnalyticsModel(
      moodEntries: moodEntries,
      totalConversations: totalConversations,
      totalMinutes: totalMinutes,
      currentStreak: streak,
      averageMood: averageMood,
      sleepQuality: sleep,
      stressLevel: stress,
      mindfulness: mindfulness,
      moodChange: 4.5,
      streakChange: 2,
      sleepChange: 5,
      mindfulnessChange: 10,
    );
  }

  int _calculateStreak(List moods) {
    if (moods.isEmpty) return 0;

    moods.sort(
      (a, b) => DateTime.parse(
        b['created_at'],
      ).compareTo(DateTime.parse(a['created_at'])),
    );

    int streak = 1;

    DateTime previous = DateTime.parse(moods.first['created_at']);

    for (int i = 1; i < moods.length; i++) {
      final current = DateTime.parse(moods[i]['created_at']);

      if (previous.difference(current).inDays == 1) {
        streak++;

        previous = current;
      } else {
        break;
      }
    }
    return streak;
  }
}
