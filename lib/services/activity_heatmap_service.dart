import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/insights/activity_heatmap.dart';

class ActivityHeatmapService {
  final supabase = Supabase.instance.client;

  Future<List<ActivityModel>> loadActivity() async {
    final user = supabase.auth.currentUser!;

    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 34));

    final conversations = await supabase
        .from("Conversations")
        .select("created_at")
        .eq("user_id", user.id)
        .gte("created_at", start.toIso8601String());

    Map<String, int> counts = {};

    for (final conversation in conversations) {
      final date = DateTime.parse(conversation["created_at"]);

      final key = "${date.year}-${date.month}-${date.day}";

      counts[key] = (counts[key] ?? 0) + 1;
    }

    List<ActivityModel> activity = [];

    for (int i = 0; i < 35; i++) {
      final day = start.add(Duration(days: i));

      final key = "${day.year}-${day.month}-${day.day}";

      activity.add(ActivityModel(day: day, count: counts[key] ?? 0));
    }

    return activity;
  }
}
