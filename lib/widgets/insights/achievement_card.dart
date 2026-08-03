import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/achievement_model.dart';
import '../../services/achievement_service.dart';
import 'achievement_badge.dart';
import 'dart:async';

class AchievementCard extends StatefulWidget {
  const AchievementCard({super.key});

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> {
  late Future<List<AchievementModel>> future;

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
      future = AchievementService().loadAchievements();
    });
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

    return FutureBuilder<List<AchievementModel>>(
      future: future,

      builder: (context, snapshot) {
        // Loading
        if (snapshot.hasError) {
          debugPrint("Achievement Error: ${snapshot.error}");

          return Container(
            height: 500,
            width: double.infinity,
            decoration: _decoration(),
            child: Center(
              child: Text(
                "unable_to_load_achievements".tr(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _decoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 45, color: Colors.red),

                const SizedBox(height: 12),

                Text(
                  "unable_to_load_achievements".tr(),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      future = AchievementService().loadAchievements();
                    });
                  },
                  child: Text("retry".tr()),
                ),
              ],
            ),
          );
        }

        // Empty
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: _decoration(),
            child: Center(child: Text("no_achievements_available".tr())),
          );
        }

        final achievements = snapshot.data!;

        return Container(
          width: double.infinity,
          height: 520,
          padding: const EdgeInsets.all(20),
          decoration: _decoration(),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "achievements".tr(),
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView.separated(
                  itemCount: achievements.length,

                  separatorBuilder: (_, __) => const SizedBox(height: 14),

                  itemBuilder: (context, index) {
                    return AchievementTile(achievement: achievements[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(blurRadius: 18, color: Colors.black.withOpacity(.05)),
      ],
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(.15), color.withOpacity(.05)],
          ),

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: color.withOpacity(.25)),
        ),

        child: Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),

            const SizedBox(height: 12),

            Text(
              title.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "unlocked".tr(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
