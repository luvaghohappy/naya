import 'package:flutter/material.dart';
import 'package:naya/Mainpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/notification_service.dart' show NotificationService;

class Settings extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDarkMode;

  const Settings({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final nicknameController = TextEditingController();

  String nickname = "Friend";

  bool isLoggedIn = false;

  String email = "";

  String currentLanguage = "en";

  bool dailyCheckIn = true;

  String reminderTime = "9:00 PM";

  String getLanguageName() {
    switch (currentLanguage) {
      case "fr":
        return "Français";

      case "es":
        return "Español";

      default:
        return "English";
    }
  }

  @override
  void initState() {
    super.initState();
    loadLanguage();

    loadUserData();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final user = session?.user;

      if (user == null) return;

      try {
        final nickname = await getNickname();

        await Supabase.instance.client.from('UsersTable').upsert({
          'id': user.id,
          'email': user.email,
          'nickname': nickname,
          'avatar_url': null,
        });

        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("email", user.email ?? "");

        if (mounted) {
          loadUserData();
        }
        print("AUTH USER ID = ${user.id}");

        print("INSERT SUCCESS");
      } catch (e) {
        print("INSERT ERROR: $e");
      }
    });
  }

  ///GET LANGUAGE
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      currentLanguage = prefs.getString("language") ?? "en";
    });
  }

  /// LANGUAGE DIALOG
  Future<void> showLanguageDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("language".tr()),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text("🇺🇸"),
                title: const Text("English"),
                onTap: () => Navigator.pop(context, "en"),
              ),

              ListTile(
                leading: const Text("🇫🇷"),
                title: const Text("Français"),
                onTap: () => Navigator.pop(context, "fr"),
              ),

              ListTile(
                leading: const Text("🇪🇸"),
                title: const Text("Español"),
                onTap: () => Navigator.pop(context, "es"),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("language", result);

    await context.setLocale(Locale(result));

    setState(() {
      currentLanguage = result;
    });
  }

  /// ---------------- GET NICKNAME ----------------

  Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("nickname") ?? "Friend";
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nickname = prefs.getString("nickname") ?? "Friend";

      isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

      email = prefs.getString("email") ?? "";
    });
  }

  /// ---------------- LOGOUT ----------------

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => IntroPage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
      (_) => false,
    );
  }

  ///----------Email Sign in------------

  Future<void> signInWithEmail() async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      debugPrint("Login Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  ///------------Google Sign in----------

  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 10),

              /// ---------------- TITLE ----------------
              Text(
                "settings_title".tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 22),
              Text(
                "Profil",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              /// ---------------- PROFILE CARD ----------------
              Container(
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),

                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,

                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    /// ---------------- AVATAR ----------------
                    Container(
                      width: 72,
                      height: 72,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: Theme.of(context).cardColor,

                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2,
                        ),
                      ),

                      child: Center(
                        child: Text(
                          nickname.isNotEmpty ? nickname[0].toUpperCase() : "N",

                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    /// ---------------- USER INFO ----------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            nickname,

                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          /// EMAIL IF LOGGED IN
                          if (isLoggedIn)
                            Text(
                              email,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(.65),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                          const SizedBox(height: 6),

                          Text(
                            "privacy_message".tr(),

                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(.65),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// ---------------- CREATE ACCOUNT CARD ----------------
              if (!isLoggedIn)
                Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),

                    color: Theme.of(context).cardColor,

                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).cardColor,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 38,
                      ),

                      const SizedBox(height: 14),

                      Text(
                        "Create an account",
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "personalize_naya".tr(),

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.65),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// ---------------- BUTTONS ----------------
                      Row(
                        children: [
                          /// EMAIL BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await signInWithEmail();
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (_) => buildEmailSheet(),
                                );
                              },

                              child: Container(
                                height: 50,

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Theme.of(context).cardColor,

                                  // gradient: const LinearGradient(
                                  //   colors: [
                                  //     Color(0xFF1F1F2B),
                                  //     Color.fromRGBO(42, 42, 58, 1),
                                  //   ],
                                  // ),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      color: Colors.blue,
                                      size: 18,
                                    ),

                                    SizedBox(width: 8),

                                    Text(
                                      "email".tr(),

                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// GOOGLE BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await signInWithGoogle();
                              },
                              child: Container(
                                height: 50,

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Theme.of(context).cardColor,

                                  // gradient: const LinearGradient(
                                  //   colors: [
                                  //     Color(0xFFFFFFFF),
                                  //     Color(0xFFF2F2F2),
                                  //   ],
                                  // ),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Colors.red,
                                      size: 28,
                                    ),

                                    SizedBox(width: 4),

                                    Text(
                                      "google",

                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              /// ---------------- ACCOUNT OPTIONS ----------------
              if (isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Theme.of(context).cardColor,

                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).cardColor,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      // buildTile(
                      //   icon: Icons.history_rounded,
                      //   title: "conversation_history".tr(),
                      // ),

                      // const Divider(),

                      // buildTile(
                      //   icon: Icons.graphic_eq_rounded,
                      //   title: "voice_preferences".tr(),
                      // ),

                      // const Divider(),
                      GestureDetector(
                        onTap: logout,

                        child: buildTile(
                          icon: Icons.logout_rounded,
                          title: "logout".tr(),
                          isLogout: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 20),
              Text(
                "voice_personality".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Card(
                elevation: 3,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      /// ---------------- VOICE ----------------
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.record_voice_over_rounded,
                            size: 20,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),

                        title: Text(
                          "voice".tr(),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        trailing: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Theme.of(
                                context,
                              ).scaffoldBackgroundColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),

                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(22),

                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,

                                    children: [
                                      Text(
                                        "choose_voice".tr(),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      buildVoiceOption(
                                        title: "calm_female".tr(),
                                        subtitle: "soft_comforting".tr(),
                                        selected: true,
                                      ),

                                      buildVoiceOption(
                                        title: "friendly_female".tr(),
                                        subtitle: "warm_cheerful".tr(),
                                      ),

                                      buildVoiceOption(
                                        title: "gentle_male".tr(),
                                        subtitle: "relaxed_supportive".tr(),
                                      ),

                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                );
                              },
                            );
                          },

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "calm_female".tr(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              SizedBox(width: 6),

                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Theme.of(context).iconTheme.color,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// SHORT DIVIDER
                      Center(
                        child: Container(
                          width: 180,
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),

                      /// ---------------- PERSONALITY ----------------
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            size: 20,
                            color: Colors.blueAccent,
                          ),
                        ),

                        title: Text(
                          "personality".tr(),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        trailing: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white70,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),

                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(22),

                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,

                                    children: [
                                      Text(
                                        "choose_personality".tr(),
                                        style: TextStyle(
                                          color: Theme.of(context).cardColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      buildVoiceOption(
                                        title: "calm".tr(),
                                        subtitle: "calm_description".tr(),
                                        selected: true,
                                      ),

                                      buildVoiceOption(
                                        title: "friendly".tr(),
                                        subtitle: "friendly_description".tr(),
                                      ),

                                      buildVoiceOption(
                                        title: "motivational".tr(),
                                        subtitle: "motivational_description"
                                            .tr(),
                                      ),

                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                );
                              },
                            );
                          },

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "calm".tr(),
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              SizedBox(width: 6),

                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Theme.of(context).iconTheme.color,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// ---------------- REMINDERS TITLE ----------------
              Text(
                "reminders".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              /// ---------------- REMINDERS CARD ----------------
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    /// DAILY CHECK-IN
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),

                      title: Text(
                        "daily_checkin".tr(),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      trailing: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: dailyCheckIn,

                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF8B5CF6),

                          onChanged: (value) async {
                            setState(() {
                              dailyCheckIn = value;
                            });

                            if (!value) {
                              await NotificationService.cancelReminder();
                              return;
                            }
                          },
                        ),
                      ),
                    ),

                    /// SHORT DIVIDER
                    Center(
                      child: Container(
                        width: 220,
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),

                    /// REMINDER TIME
                    ListTile(
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 21, minute: 0),
                        );

                        if (picked != null) {
                          setState(() {
                            reminderTime = picked.format(context);
                          });

                          await NotificationService.scheduleReminder(
                            time: picked,

                            title: "naya_daily_checkin".tr(),

                            body: "daily_checkin_message".tr(),
                          );
                        }
                      },

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),

                      title: Text(
                        "reminder_time".tr(),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reminderTime,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(.65),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// ---------------- PREFERENCES TITLE ----------------
              Text(
                "preferences".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              /// ---------------- PREFERENCES CARD ----------------
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    /// ---------------- DARK MODE ----------------
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),

                      title: Text(
                        "dark_mode".tr(),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      trailing: IconButton(
                        icon: Icon(
                          widget.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        onPressed: () =>
                            widget.onToggleTheme(!widget.isDarkMode),
                      ),
                    ),

                    /// SHORT DIVIDER
                    Center(
                      child: Container(
                        width: 220,
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),

                    /// ---------------- LANGUAGE ----------------
                    ListTile(
                      onTap: showLanguageDialog,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),

                      title: Text(
                        "language".tr(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getLanguageName(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ],
                      ),
                    ),

                    /// SHORT DIVIDER
                    Center(
                      child: Container(
                        width: 220,
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),

                    /// ---------------- PRIVACY ----------------
                    ListTile(
                      onTap: () {
                        /// PRIVACY PAGE
                      },

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),

                      title: Text(
                        "privacy_data".tr(),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  ///--------BUILD EMAIL SHEET

  Widget buildEmailSheet() {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TOP ICON
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "create_your_account".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "save_conversations".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              AutofillGroup(
                child: Column(
                  children: [
                    /// NICKNAME
                    TextField(
                      controller: nicknameController,
                      autofillHints: const [AutofillHints.nickname],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: "nickname".tr(),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF8B5CF6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// EMAIL
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: "email_address".tr(),
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: Color(0xFF8B5CF6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// PASSWORD
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: "create_password".tr(),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF8B5CF6),
                        ),
                        suffixIcon: const Icon(Icons.visibility_off_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// CREATE ACCOUNT BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () async {
                    final supabase = Supabase.instance.client;

                    try {
                      final response = await supabase.auth.signUp(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      if (response.user != null) {
                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("check_email".tr())),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    "create_account_button".tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "maybe_later".tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- SETTINGS TILE ----------------

  Widget buildTile({
    required IconData icon,
    required String title,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: isLogout
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xFF8B5CF6).withOpacity(0.1),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: isLogout ? Colors.red : const Color(0xFF8B5CF6),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,

              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isLogout
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Theme.of(context).iconTheme.color,
          ),
        ],
      ),
    );
  }

  Widget buildVoiceOption({
    required String title,
    required String subtitle,
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        color: selected
            ? const Color(0xFF8B5CF6).withOpacity(0.18)
            : Colors.white.withOpacity(0.05),

        border: Border.all(
          color: selected ? const Color(0xFF8B5CF6) : Colors.white10,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: LinearGradient(
                colors: selected
                    ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                    : [Colors.grey.shade700, Colors.grey.shade800],
              ),
            ),

            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          if (selected)
            const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)),
        ],
      ),
    );
  }
}
