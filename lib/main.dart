import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:naya/Mainpage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'Navigation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// LOAD ENV
  await dotenv.load(fileName: ".env");

  //Notification
  tz.initializeTimeZones();
  await NotificationService.initialize();

  //SUPABASE

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,

    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  print(dotenv.env['SUPABASE_URL']);

  print(dotenv.env['SUPABASE_ANON_KEY']);

  /// LOAD PREFS
  final prefs = await SharedPreferences.getInstance();

  /// CHECK IF ONBOARDING IS DONE
  final bool onboardingDone = prefs.getBool("onboarding_done") ?? false;

  //Language
  await EasyLocalization.ensureInitialized();

  String language = prefs.getString("language") ?? "en";

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(language),
      child: MyApp(onboardingDone: onboardingDone),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool onboardingDone;

  const MyApp({super.key, required this.onboardingDone});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();

    loadThemePreference();
  }

  /// ---------------- LOAD THEME ----------------

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();

    final bool isDarkMode = prefs.getBool("isDarkMode") ?? false;

    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /// ---------------- TOGGLE THEME ----------------

  Future<void> toggleTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("isDarkMode", isDarkMode);

    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,

      supportedLocales: context.supportedLocales,

      locale: context.locale,

      title: "Naya",

      themeMode: _themeMode,

      /// ---------------- LIGHT THEME ----------------
      theme: ThemeData(
        brightness: Brightness.light,

        scaffoldBackgroundColor: const Color(0xFFF6F4FB),

        fontFamily: "Roboto",

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6)),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        cardColor: Colors.white,
      ),

      /// ---------------- DARK THEME ----------------
      darkTheme: ThemeData(
        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF0F0F17),

        fontFamily: "Roboto",

        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF8B5CF6),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        cardColor: const Color(0xFF1B1B2B),
      ),

      /// ---------------- START PAGE ----------------
      home: widget.onboardingDone
          ? NavigationPage(
              isDarkMode: _themeMode == ThemeMode.dark,

              onToggleTheme: toggleTheme,
            )
          : IntroPage(
              isDarkMode: _themeMode == ThemeMode.dark,

              onToggleTheme: toggleTheme,
            ),
    );
  }
}
