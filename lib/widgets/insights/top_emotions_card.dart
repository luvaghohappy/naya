import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naya/services/TopEmotionService.dart';
import '../../models/InsightModel.dart';
import '../../models/top_emotion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopEmotionsCard extends StatefulWidget {
  final InsightPeriod period;
  final DateTime selectedDate;
  const TopEmotionsCard({
    super.key,
    required this.period,
    required this.selectedDate,
  });

  @override
  State<TopEmotionsCard> createState() => _TopEmotionsCardState();
}

class _TopEmotionsCardState extends State<TopEmotionsCard> {
  late Future<List<EmotionStat>> emotionsFuture;

   late final StreamSubscription<AuthState> authSubscription;


  @override
  void initState() {
    super.initState();
     emotionsFuture = TopEmotionService().loadTopEmotions(
      widget.period,
      widget.selectedDate,
    );
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

  Future<void> refresh() async {
    if (!mounted) return;

    setState(() {
      emotionsFuture = TopEmotionService().loadTopEmotions(
        widget.period,
        widget.selectedDate,
      );
    });
  }

  @override
  void didUpdateWidget(covariant TopEmotionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period ||
        oldWidget.selectedDate != widget.selectedDate) {
      refresh();
      setState(() {
        emotionsFuture = TopEmotionService().loadTopEmotions(
          widget.period,
          widget.selectedDate,
        );
      });
    }
  }

  String getEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case "joy":
        return "😊";

      case "sadness":
        return "😢";

      case "angry":
        return "😠";

      case "anger":
        return "😠";

      case "stress":
        return "😫";

      case "fear":
        return "😨";

      case "anxiety":
        return "😰";

      case "depression":
        return "😞";

      case "hope":
        return "🌈";

      case "gratitude":
        return "🙏";

      case "calm":
        return "😌";

      case "love":
        return "❤️";

      default:
        return "🙂";
    }
  }

  Color getColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case "joy":
        return Colors.orange;

      case "happy":
        return Colors.orange;

      case "sadness":
        return Colors.blue;

      case "sad":
        return Colors.blue;

      case "anger":
        return Colors.red;

      case "fear":
        return Colors.deepOrange;

      case "stress":
        return Colors.deepPurple;

      case "anxiety":
        return Colors.purple;

      case "depression":
        return Colors.blueGrey;

      case "calm":
        return Colors.green;

      case "hope":
        return Colors.amber;

      case "gratitude":
        return Colors.teal;

      case "love":
        return Colors.pink;

      default:
        return Colors.grey;
    }
  }

  String translateEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case "joy":
        return "joy".tr();

      case "sadness":
        return "sadness".tr();

      case "anger":
      case "angry":
        return "anger".tr();

      case "stress":
        return "stress".tr();

      case "fear":
        return "fear".tr();

      case "anxiety":
        return "anxiety".tr();

      case "depression":
        return "depression".tr();

      case "hope":
        return "hope".tr();

      case "gratitude":
        return "gratitude".tr();

      case "calm":
        return "calm".tr();

      case "love":
        return "love".tr();

      default:
        return emotion;
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
    return FutureBuilder<List<EmotionStat>>(
      future: emotionsFuture,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 460,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 460,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(child: Text("no_emotions_recorded".tr())),
          );
        }

        final emotions = snapshot.data!;
        return Container(
          height: 464,

          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),

            // border: Border.all(color: Colors.grey.shade200),

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    "top_emotions".tr(),

                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ...emotions.map((e) {
                return emotion(
                  getEmoji(e.emotion),

                  e.emotion,

                  e.percent,

                  getColor(e.emotion),
                  translateEmotion(e.emotion),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget emotion(
    String emoji,
    String title,
    double value,
    Color color,
    translateEmotion,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),

      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,

                backgroundColor: color.withOpacity(.15),

                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,

                    fontSize: 10,
                  ),
                ),
              ),

              Text(
                "${(value * 100).round()}%",

                style: const TextStyle(
                  fontWeight: FontWeight.bold,

                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: value,

              minHeight: 8,

              backgroundColor: Colors.grey.shade200,

              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
