import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naya/Navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const IntroPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  String selectedLanguage = "en";

  final TextEditingController nicknameController = TextEditingController();

  bool isLoading = false;

  Future<void> continueToApp() async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("nickname", nickname);

    await prefs.setBool("onboarding_done", true);

    await prefs.setString("language", selectedLanguage);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationPage(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    }
  }

  Future<void> skip() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("nickname", "Friend");

    await prefs.setBool("onboarding_done", true);

    await prefs.setString("language", selectedLanguage);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationPage(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedLanguage = prefs.getString("language") ?? "en";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.25),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// Welcome
                  Text(
                    "welcome".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "question".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Nickname Field
                  TextField(
                    controller: nicknameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "nickname".tr(),
                      hintStyle: const TextStyle(color: Colors.white54),

                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                      ),

                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "language".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1F1F27),
                        value: selectedLanguage,
                        iconEnabledColor: Colors.white,
                        isExpanded: true,

                        style: const TextStyle(color: Colors.white),

                        items: const [
                          DropdownMenuItem(
                            value: "en",
                            child: Text("🇺🇸 English"),
                          ),

                          DropdownMenuItem(
                            value: "fr",
                            child: Text("🇫🇷 Français"),
                          ),

                          DropdownMenuItem(
                            value: "es",
                            child: Text("🇪🇸 Español"),
                          ),
                        ],

                        onChanged: (value) async {
                          if (value == null) return;

                          setState(() {
                            selectedLanguage = value;
                          });

                          context.setLocale(Locale(value));

                          final prefs = await SharedPreferences.getInstance();

                          await prefs.setString("language", value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : continueToApp,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              "continue".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// Skip
                  TextButton(
                    onPressed: skip,
                    child: Text(
                      "skip".tr(),
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// Privacy
                  Text(
                    "privacy".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
