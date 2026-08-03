import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late final StreamSubscription<AuthState> authSubscription;

  late stt.SpeechToText _speech;
  late FlutterTts tts;

  bool isListening = false;
  bool isSpeaking = false;

  String nickname = "Friend";

  String selectedLanguage = "en";

  String speechLocale = "en_US";
  String ttsLocale = "en-US";
  String aiLanguage = "English";

  String? currentConversationId;

  String lastDailyUpdate = "";

  String _mostFrequent(List list) {
    final map = <String, int>{};

    for (final e in list) {
      map[e] = (map[e] ?? 0) + 1;
    }

    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<Message> messages = [];

  Future<void> refreshPage() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        messages.clear();
        currentConversationId = null;
      });

      return;
    }

    await loadMessages();
  }

  final ScrollController _scrollController = ScrollController();

  final TextEditingController messageController = TextEditingController();

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _speech = stt.SpeechToText();

    tts = FlutterTts();

    initializeApp();

    authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      refreshPage();
    });
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  /// ---------------- INITIALIZE ----------------

  Future<void> initializeApp() async {
    final prefs = await SharedPreferences.getInstance();

    nickname = prefs.getString("nickname") ?? "Friend";
    selectedLanguage = prefs.getString("language") ?? "en";

    configureLanguage();

    await initializeTTS();

    // Wait until the conversation is ready
    await loadConversation();

    if (!mounted) return;

    // If there is still no conversation, stop here.
    if (currentConversationId == null) {
      debugPrint("No active conversation.");
      return;
    }

    // Load messages
    await loadMessages();

    // Build memory
    if (messages.isNotEmpty) {
      final conversationText = messages.map((m) => m.text).join("\n");

      await extractMemory(conversationText);

      await startListening();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      await speakGreeting();
    }
  }

  //CONFIGURE LANGUAGE

  void configureLanguage() {
    switch (selectedLanguage) {
      case "fr":
        speechLocale = "fr_FR";
        ttsLocale = "fr-FR";
        aiLanguage = "French";
        break;

      case "es":
        speechLocale = "es_ES";
        ttsLocale = "es-ES";
        aiLanguage = "Spanish";
        break;

      default:
        speechLocale = "en_US";
        ttsLocale = "en-US";
        aiLanguage = "English";
    }
  }

  //GREETINGS

  Future<void> speakGreeting() async {
    String greeting;

    switch (selectedLanguage) {
      case "fr":
        greeting =
            "Bonjour $nickname. Je suis Naya. Comment te sens-tu aujourd'hui ?";
        break;

      case "es":
        greeting = "Hola $nickname. Soy Naya. ¿Cómo te sientes hoy?";
        break;

      default:
        greeting = "Hello $nickname. I'm Naya. How are you feeling today?";
    }

    // Save greeting into database
    await saveMessage(greeting, false);

    // Speak it
    await speak(greeting);
  }

  /// ---------------- TTS ----------------

  Future<void> initializeTTS() async {
    await tts.setLanguage(ttsLocale);

    await tts.setPitch(1.0);

    await tts.setSpeechRate(0.45);

    await tts.setVolume(1.0);

    try {
      final voices = await tts.getVoices;

      if (voices is List) {
        for (final voice in voices) {
          if (voice["locale"] == ttsLocale) {
            await tts.setVoice({
              "name": voice["name"],
              "locale": voice["locale"],
            });
            break;
          }
        }
      }
    } catch (_) {}

    tts.setCompletionHandler(() async {
      setState(() {
        isSpeaking = false;
      });

      _controller.stop();

      await startListening();
    });
  }

  /// ---------------- SPEAK ----------------

  Future<void> speak(String text) async {
    setState(() {
      isSpeaking = true;
      isListening = false;

      messages.add(Message(text: text, isUser: false));
    });
    scrollToBottom();

    _controller.repeat(reverse: true);

    await tts.stop();

    await tts.speak(text);
  }

  /// ---------------- OPENAI ----------------

  Future<String> getAIResponse(String input) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

      // LOAD MEMORIES HERE
      final memories = await loadUserMemories();

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  """

You are Naya, a warm emotional companion.

You remember this about the user:
$memories

Rules:
- Use memory naturally
- Be supportive
- Ask follow-up questions when appropriate
                  """,
            },
            {"role": "user", "content": input},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["choices"][0]["message"]["content"];
      }

      return selectedLanguage == "fr"
          ? "Je rencontre un problème de connexion."
          : selectedLanguage == "es"
          ? "No puedo conectarme en este momento."
          : "I couldn't connect right now.";
    } catch (e) {
      return selectedLanguage == "fr"
          ? "Une erreur est survenue."
          : selectedLanguage == "es"
          ? "Ha ocurrido un error."
          : "Something went wrong.";
    }
  }

  /// ---------------- LISTEN ----------------

  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("STATUS: $status");
      },
      onError: (error) {
        print("ERROR: $error");
      },
    );

    if (!available) return;

    setState(() {
      isListening = true;
    });

    scrollToBottom();

    _controller.repeat(reverse: true);

    await _speech.listen(
      localeId: speechLocale,
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) async {
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          String userText = result.recognizedWords;

          setState(() {
            messages.add(Message(text: userText, isUser: true));
          });

          await handleConversation(userText);
        }
      },
    );
  }

  /// ---------------- STOP ----------------

  Future<void> stopListening() async {
    await _speech.stop();

    setState(() {
      isListening = false;
    });

    _controller.stop();
  }

  /// ---------------- CONVERSATION ----------------

  Future<void> handleConversation(String text) async {
    await stopListening();

    await saveMessage(text, true);

    final aiResponse = await getAIResponse(text);

    await saveMessage(aiResponse, false);

    await speak(aiResponse);

    // build conversation once
    final conversationText = await buildConversationText();

    // 1. analyze emotion + title
    await analyzeConversation();

    // 2. extract memory
    await extractMemory(conversationText);
  }

  ///--------Create conversations
  ///
  Future<String> createConversation() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception("user_not_logged_in".tr());
    }

    await Supabase.instance.client
        .from('Conversations')
        .update({'is_active': false})
        .eq('user_id', user.id);

    final response = await Supabase.instance.client
        .from('Conversations')
        .insert({
          'user_id': user.id,
          'title': '',
          'emotion': '',
          'is_active': true,
        })
        .select()
        .single();

    return response['conversation_id'];
  }

  ///-------LOAD CONVERSATION

  Future<void> loadConversation() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final conversation = await Supabase.instance.client
        .from('Conversations')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    if (conversation == null) {
      currentConversationId = await createConversation();

      await loadMessages();

      return;
    }

    currentConversationId = conversation['conversation_id'];

    final updatedAt = conversation['updated_at'] != null
        ? DateTime.parse(conversation['updated_at'])
        : DateTime.now();

    final difference = DateTime.now().difference(updatedAt);

    if (difference.inHours >= 24) {
      await calculateConversationMinutes(currentConversationId!);
      currentConversationId = await createConversation();

      messages.clear();

      await loadMessages();

      return;
    }
  }

  ///------LOAD MESSAGES

  Future<void> loadMessages() async {
    print("Loading messages for: $currentConversationId");

    if (currentConversationId == null) return;

    final data = await Supabase.instance.client
        .from('Messages')
        .select()
        .eq('id_conversation', currentConversationId!)
        .order('created_at', ascending: true);

    print("Database returned ${data.length} messages");

    setState(() {
      messages = data.map<Message>((m) {
        return Message(text: m['message'], isUser: m['is_user']);
      }).toList();
    });

    scrollToBottom();
  }

  ///------Save Messages----------
  ///
  Future<void> saveMessage(String text, bool isUser) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    if (currentConversationId == null) {
      currentConversationId = await createConversation();
    }

    await Supabase.instance.client.from('Messages').insert({
      'id_conversation': currentConversationId,
      'user_id': user.id,
      'message': text,
      'is_user': isUser,
      'created_at': DateTime.now().toIso8601String(),
    });

    await Supabase.instance.client
        .from('Conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', currentConversationId!);
  }

  ///---------Send messages
  ///
  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(Message(text: text, isUser: true));
    });

    messageController.clear();

    await saveMessage(text, true);

    // AI response later
  }

  ///------ANALYZE CONVERSATION

  Future<void> analyzeConversation() async {
    try {
      if (currentConversationId == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('Messages')
          .select()
          .eq('id_conversation', currentConversationId!)
          .order('created_at', ascending: true);

      if (data.length < 6) return;

      final conversationText = data.map((e) => e['message']).join("\n");

      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "response_format": {"type": "json_object"},
          "messages": [
            {
              "role": "system",
              "content": """
Return ONLY JSON:

{
  "title": "",
  "emotion": "",
  "mood_score": 0,
  "stress_level": 0,
  "energy_level": 0,
  "sleep_quality": 0,
  "mindfulness_score": 0,
  "summary": ""
}

Rules:
- 0–100 scores
- based on full conversation
- The title must summarize the main topic.
- Maximum 5 words.
- Never use generic titles like:
  "Conversation"
  "Chat"
  "New Conversation"

Determine the USER'S dominant emotion.

Possible emotions:

Joy
Sadness
Stress
Fear
Anger
Anxiety
depression
Neutral

Base your decision on the ENTIRE conversation,
not only the last message.

Summary rules:
- 40–80 words.
- Speak directly to the user.
- Be empathetic.
- Mention today's emotional pattern.
- Mention one strength.
- Give one practical suggestion.
""",
            },
            {"role": "user", "content": conversationText},
          ],
        }),
      );
      if (response.statusCode != 200) {
        print("AI ERROR: ${response.body}");
        return;
      }

      final result = jsonDecode(response.body);
      final content = result["choices"][0]["message"]["content"];
      final analysis = jsonDecode(content);

      final title = analysis["title"] ?? "";
      final emotion = analysis["emotion"] ?? "";
      final moodScore = analysis["mood_score"] ?? 50;
      final stress = analysis["stress_level"] ?? 50;
      final sleep = analysis["sleep_quality"] ?? 50;
      final energy = analysis["energy_level"] ?? 50;
      final mindfulness = analysis["mindfulness_score"] ?? 50;
      final summary = analysis["summary"] ?? "";

      if (title.isEmpty || emotion.isEmpty) return;

      // Calculate duration BEFORE updating conversation
      final duration = await calculateConversationMinutes(
        currentConversationId!,
      );

      // Update conversation
      await Supabase.instance.client
          .from('Conversations')
          .update({
            "title": title,
            "emotion": emotion,
            "duration_minutes": duration,
            "updated_at": DateTime.now().toIso8601String(),
          })
          .eq("conversation_id", currentConversationId!);

      // 2. insert mood history
      await saveMoodAnalysis(
        user: user,
        emotion: emotion,
        moodScore: moodScore,
        stress: stress,
        sleep: sleep,
        energy: energy,
        mindfulness: mindfulness,
      );

      await Supabase.instance.client
          .from("Conversations")
          .update({"duration_minutes": duration})
          .eq("conversation_id", currentConversationId!);

      // 3. trigger daily update
      await updateDailyInsights(summary);
    } catch (e) {
      print(e);
    }
  }

  //Calculate Conversations minutes
  Future<int> calculateConversationMinutes(String conversationId) async {
    final messages = await Supabase.instance.client
        .from("Messages")
        .select("created_at")
        .eq("id_conversation", conversationId)
        .order("created_at", ascending: true);

    if (messages.length < 2) {
      return 0;
    }

    final firstMessage = DateTime.parse(
      messages.first["created_at"].toString(),
    );

    final lastMessage = DateTime.parse(messages.last["created_at"].toString());
    final difference = lastMessage.difference(firstMessage).inMinutes;
    // Prevent unrealistic durations
    if (difference < 0) return 0;
    return difference;
  }

  //Anelyze mood

  Future<void> saveMoodAnalysis({
    required User user,
    required String emotion,
    required int moodScore,
    required int stress,
    required int sleep,
    required int energy,
    required int mindfulness,
  }) async {
    final existing = await Supabase.instance.client
        .from("mood_history")
        .select("id")
        .eq("conversation_id", currentConversationId!)
        .maybeSingle();

    if (existing == null) {
      await Supabase.instance.client.from("mood_history").insert({
        "conversation_id": currentConversationId,
        "user_id": user.id,
        "mood": emotion,
        "mood_score": moodScore,
        "stress_level": stress,
        "sleep_quality": sleep,
        "energy_level": energy,
        "mindfulness_score": mindfulness,
        "created_at": DateTime.now().toIso8601String(),
      });
    } else {
      await Supabase.instance.client
          .from("mood_history")
          .update({
            "mood": emotion,
            "mood_score": moodScore,
            "stress_level": stress,
            "sleep_quality": sleep,
            "energy_level": energy,
            "mindfulness_score": mindfulness,
          })
          .eq("conversation_id", currentConversationId!);
    }
  }

  ///Update daily insight
  ///
  Future<void> updateDailyInsights(String summary) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final today = DateTime.now();

    final startOfDay = DateTime(today.year, today.month, today.day);

    final moods = await Supabase.instance.client
        .from("mood_history")
        .select()
        .eq("user_id", user.id)
        .gte("created_at", startOfDay.toIso8601String());

    if (moods.isEmpty) return;

    final conversations = await Supabase.instance.client
        .from("Conversations")
        .select("duration_minutes")
        .eq("user_id", user.id)
        .gte("created_at", startOfDay.toIso8601String());

    final totalConversations = conversations.length;

    final totalMinutes = conversations.fold<int>(0, (sum, item) {
      final duration = (item["duration_minutes"] as num?)?.toInt() ?? 0;

      return sum + duration;
    });

    // Average Mood
    final moodScore =
        moods.map((e) => e["mood_score"] as int).reduce((a, b) => a + b) ~/
        moods.length;

    // Average Stress
    final stress =
        moods.map((e) => e["stress_level"] as int).reduce((a, b) => a + b) ~/
        moods.length;

    // Average Sleep
    final sleep =
        moods.map((e) => e["sleep_quality"] as int).reduce((a, b) => a + b) ~/
        moods.length;

    // Average Energy
    final energy =
        moods.map((e) => e["energy_level"] as int).reduce((a, b) => a + b) ~/
        moods.length;

    // Average Mindfulness
    final mindfulness =
        moods
            .map((e) => e["mindfulness_score"] as int)
            .reduce((a, b) => a + b) ~/
        moods.length;

    // Dominant Emotion
    final emotions = moods.map((e) => e["mood"].toString()).toList();

    final dominantEmotion = _mostFrequent(emotions);

    // Positive %
    final positive = moods.where((e) => (e["mood_score"] as int) >= 60).length;

    final positivePercent = ((positive / moods.length) * 100).round();

    await Supabase.instance.client.from("daily_insights").upsert({
      "user_id": user.id,
      "period_start": startOfDay.toIso8601String().split("T")[0],

      "total_conversations": totalConversations,
      "total_minutes": totalMinutes,

      "dominant_emotion": dominantEmotion,
      "mood_score": moodScore,
      "stress_level": stress,
      "sleep_quality": sleep,
      "energy_level": energy,
      "mindfulness_score": mindfulness,
      "positive_percent": positivePercent,
      "summary": summary,
    }, onConflict: "user_id,period_start");

    // Sunday

    updateWeeklyInsights();

    await updateMonthlyInsights();
  }

  ///Generate Weekly Report
  Future<void> updateWeeklyInsights() async {
    print("===== updateWeeklyInsights CALLED =====");

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print("No logged in user");
      return;
    }

    final weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );

    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekly = await Supabase.instance.client
        .from('mood_history')
        .select()
        .eq('user_id', user.id)
        .gte("created_at", weekStart.toIso8601String())
        .lt("created_at", weekEnd.toIso8601String());

    if (weekly.isEmpty) return;

    final conversations = await Supabase.instance.client
        .from("Conversations")
        .select("duration_minutes")
        .eq("user_id", user.id)
        .gte("created_at", weekStart.toIso8601String())
        .lt("created_at", weekEnd.toIso8601String());

    final totalConversations = conversations.length;

    final totalMinutes = conversations.fold<int>(0, (sum, item) {
      final duration = (item["duration_minutes"] as num?)?.toInt() ?? 0;

      return sum + duration;
    });

    final scores = weekly.map((e) => e['mood_score'] as int).toList();

    final avgMood = scores.reduce((a, b) => a + b) ~/ scores.length;

    final avgStress =
        weekly.map((e) => e["stress_level"] as int).reduce((a, b) => a + b) ~/
        weekly.length;

    final avgSleep =
        weekly.map((e) => e["sleep_quality"] as int).reduce((a, b) => a + b) ~/
        weekly.length;

    final avgEnergy =
        weekly.map((e) => e["energy_level"] as int).reduce((a, b) => a + b) ~/
        weekly.length;

    final avgMindfulness =
        weekly
            .map((e) => e["mindfulness_score"] as int)
            .reduce((a, b) => a + b) ~/
        weekly.length;

    final positive = weekly.where((e) => (e["mood_score"] as int) >= 60).length;

    final positivePercent = ((positive / weekly.length) * 100).round();

    final emotions = weekly.map((e) => e['mood'].toString()).toList();

    final dominantEmotion = _mostFrequent(emotions);

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    // AI SUMMARY
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "response_format": {"type": "json_object"},
        "messages": [
          {
            "role": "system",
            "content": """
Return ONLY JSON:

{
  "summary": ""
}

Write a supportive weekly mental health summary under 120 words.

Mention:
- the user's general emotional pattern
- one strength
- one practical suggestion
""",
          },
          {
            "role": "user",
            "content":
                """
Average mood: $avgMood
Dominant emotion: $dominantEmotion
Positive percentage: $positivePercent%
Average stress: $avgStress
Average sleep quality: $avgSleep
Average energy: $avgEnergy
Average mindfulness: $avgMindfulness
Total conversations: $totalConversations
Total minutes with Naya: $totalMinutes
""",
          },
        ],
      }),
    );

    final result = jsonDecode(response.body);

    final content = result["choices"][0]["message"]["content"];

    String summary;

    try {
      summary = jsonDecode(content)["summary"] ?? "";
    } catch (e) {
      print("OpenAI returned plain text instead of JSON.");
      summary = content.toString();
    }

    await Supabase.instance.client.from("weekly_insights").upsert({
      "user_id": user.id,
      "period_start": weekStart.toIso8601String().split("T")[0],

      "total_conversations": totalConversations,
      "total_minutes": totalMinutes,

      "dominant_emotion": dominantEmotion,
      "mood_score": avgMood,
      "positive_percent": positivePercent,
      "stress_level": avgStress,
      "sleep_quality": avgSleep,
      "energy_level": avgEnergy,
      "mindfulness_score": avgMindfulness,
      "summary": summary,
    }, onConflict: "user_id,period_start");
  }

  //Genarate Monthly Report
  Future<void> updateMonthlyInsights() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);

    final month = await Supabase.instance.client
        .from('mood_history')
        .select()
        .eq('user_id', user.id)
        .gte("created_at", monthStart.toIso8601String())
        .lt("created_at", nextMonth.toIso8601String());

    if (month.isEmpty) return;

    final conversations = await Supabase.instance.client
        .from("Conversations")
        .select("duration_minutes")
        .eq("user_id", user.id)
        .gte("created_at", monthStart.toIso8601String())
        .lt("created_at", nextMonth.toIso8601String());

    final totalMinutes = conversations.fold<int>(
      0,
      (sum, item) => sum + ((item["duration_minutes"] ?? 0) as int),
    );

    final scores = month.map((e) => e['mood_score'] as int).toList();

    final avgMood = scores.reduce((a, b) => a + b) ~/ scores.length;

    final avgStress =
        month.map((e) => e["stress_level"] as int).reduce((a, b) => a + b) ~/
        month.length;

    final avgSleep =
        month.map((e) => e["sleep_quality"] as int).reduce((a, b) => a + b) ~/
        month.length;

    final avgEnergy =
        month.map((e) => e["energy_level"] as int).reduce((a, b) => a + b) ~/
        month.length;

    final avgMindfulness =
        month
            .map((e) => e["mindfulness_score"] as int)
            .reduce((a, b) => a + b) ~/
        month.length;

    final positive = month.where((e) => (e["mood_score"] as int) >= 60).length;

    final positivePercent = ((positive / month.length) * 100).round();

    final emotions = month.map((e) => e['mood'].toString()).toList();

    final dominantEmotion = _mostFrequent(emotions);

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    // AI SUMMARY
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "response_format": {"type": "json_object"},
        "messages": [
          {
            "role": "system",
            "content":
                "Write a supportive monthly mental health summary under 120 words.",
          },
          {
            "role": "user",
            "content":
                """
Mood average: $avgMood
Dominant emotion: $dominantEmotion
Total entries: ${month.length}
""",
          },
        ],
      }),
    );

    final result = jsonDecode(response.body);

    final content = result["choices"][0]["message"]["content"];

    String summary;

    try {
      summary = jsonDecode(content)["summary"] ?? "";
    } catch (e) {
      print("OpenAI returned plain text instead of JSON.");
      summary = content.toString();
    }

    await Supabase.instance.client.from("monthly_insights").upsert({
      "user_id": user.id,
      "period_start": monthStart.toIso8601String().split("T")[0],
      "total_conversations": conversations.length,
      "total_minutes": totalMinutes,
      "dominant_emotion": dominantEmotion,
      "mood_score": avgMood,
      "positive_percent": positivePercent,
      "stress_level": avgStress,
      "sleep_quality": avgSleep,
      "energy_level": avgEnergy,
      "mindfulness_score": avgMindfulness,
      "summary": summary,
    }, onConflict: "user_id,period_start");
  }

  ///EXTRACT MEMORY

  Future<void> extractMemory(String conversationText) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "response_format": {"type": "json_object"},
        "messages": [
          {
            "role": "system",
            "content": """
You are Naya's long-term memory.

Your job is NOT to summarize the conversation.

Your job is to remember ONLY information that will help Naya know the user better in future conversations.

Extract AT MOST 2 memories from this entire conversation.

If nothing is important enough, return an empty list.

Return JSON:

{
  "memories":[
    {
      "text":"",
      "category":"",
      "importance":1-5
    }
  ]
}

Remember ONLY things such as:

• life goals
• important relationships
• education
• career
• family
• long-term hobbies
• values
• preferences that are likely to matter again
• important events
• recurring struggles
• medical information voluntarily shared
• long-term plans

DO NOT remember:

• greetings
• temporary emotions
• today's mood
• jokes
• small talk
• questions
• what Naya said
• facts about Naya
• information mentioned only casually
• details unlikely to matter again

Rules:

- Extract 0–2 memories only.
- Never create memories about Naya.
- Only create memories about the USER.
- Ignore one-time events unless they are life changing.
- Merge similar memories into one.
- Prefer quality over quantity.
- If unsure, do not save it.  
""",
          },
          {"role": "user", "content": conversationText},
        ],
      }),
    );

    // STEP 1: parse response
    final data = jsonDecode(response.body);

    final contentRaw = data["choices"][0]["message"]["content"];
    final content = jsonDecode(contentRaw);

    // STEP 2: safety check
    if (content["memories"] == null) return;

    // STEP 3: load existing memories (IMPORTANT)
    final existing = await Supabase.instance.client
        .from('user_memories')
        .select()
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

    // STEP 4: YOUR LOOP GOES HERE (THIS IS THE PLACE YOU ASKED)
    for (final mem in content["memories"]) {
      final text = mem["text"];
      final category = mem["category"];
      final importance = mem["importance"];

      // skip weak memories
      if (importance < 3) continue;

      // check duplicates
      final alreadyExists = existing.any(
        (e) =>
            e["memory"].toString().toLowerCase().contains(text.toLowerCase()) ||
            text.toLowerCase().contains(e["memory"].toString().toLowerCase()),
      );

      if (alreadyExists) continue;

      // insert new memory
      await Supabase.instance.client.from('user_memories').insert({
        "user_id": Supabase.instance.client.auth.currentUser!.id,
        "memory": text,
        "category": category,
        "importance": importance,
      });
    }
  }

  ///load memories
  ///
  Future<String> loadUserMemories() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "";

    final data = await Supabase.instance.client
        .from('user_memories')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);

    final memories = data.map((e) => e['memory']).join("\n");

    return memories;
  }

  ///OPEN CONVERSATION

  Future<void> openConversation(String conversationId) async {
    print("Opening conversation: $conversationId");

    currentConversationId = conversationId;

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      await Supabase.instance.client
          .from('Conversations')
          .update({'is_active': false})
          .eq('user_id', user.id);

      await Supabase.instance.client
          .from('Conversations')
          .update({'is_active': true})
          .eq('conversation_id', conversationId);
    }

    await loadMessages();

    print("Messages loaded: ${messages.length}");

    setState(() {});
  }

  ///Build Conversation

  Future<String> buildConversationText() async {
    final data = await Supabase.instance.client
        .from('Messages')
        .select()
        .eq('id_conversation', currentConversationId!)
        .order('created_at', ascending: true);

    return data
        .map((e) {
          final speaker = e['is_user'] ? "User" : "Naya";
          return "$speaker: ${e['message']}";
        })
        .join("\n");
  }

  ///---------Start new conversation
  Future<void> startNewConversation() async {
    currentConversationId = null;

    setState(() {
      messages.clear();
    });

    await startListening();
  }

  /// ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ///================ HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Naya",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C63FF),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            ///================ CHAT =================
            Expanded(
              child: Stack(
                children: [
                  /// CHAT LIST
                  ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 240),
                    itemCount: messages.length,

                    itemBuilder: (context, index) {
                      final message = messages[index];

                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 15,
                          ),

                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * .76,
                          ),

                          decoration: BoxDecoration(
                            gradient: message.isUser
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF9B6DFF),
                                      Color(0xFF6C63FF),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade900,
                                      const Color(0xFF23232E),
                                    ],
                                  ),

                            borderRadius: BorderRadius.circular(24),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                message.isUser ? nickname : "Naya",

                                style: TextStyle(
                                  color: message.isUser
                                      ? Colors.white70
                                      : Colors.purpleAccent,

                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                message.text,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  /// EMPTY STATE
                  if (messages.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 160),
                        child: Text(
                          "start_a_conversation".tr(),
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),

                  ///================ FLOATING ORB =================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 70,

                    child: Center(child: buildOrb()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrb() {
    return AnimatedBuilder(
      animation: _controller,

      builder: (_, child) {
        final double scale = (isListening || isSpeaking)
            ? 1.0 + (_controller.value * 0.08)
            : 1.0;
        return Transform.scale(
          scale: scale,

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Stack(
                alignment: Alignment.center,

                children: [
                  /// Animated waves
                  if (isListening || isSpeaking)
                    ...List.generate(
                      3,
                      (index) => Container(
                        width: 90 + (index * 30),

                        height: 90 + (index * 30),

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withOpacity(.22 - index * .05),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  /// Glass
                  Container(
                    width: 74,
                    height: 74,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: Colors.white.withOpacity(.12),

                      border: Border.all(color: Colors.white.withOpacity(.18)),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(.25),
                          blurRadius: 40,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),

                  /// Main Orb
                  GestureDetector(
                    onTap: () async {
                      if (isListening) {
                        await stopListening();
                      } else {
                        await startListening();
                      }
                    },

                    child: Container(
                      width: 60,
                      height: 60,

                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,

                        gradient: LinearGradient(
                          colors: [Color(0xFF9B6DFF), Color(0xFF6C63FF)],
                        ),
                      ),

                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),

                        child: Icon(
                          isSpeaking
                              ? Icons.graphic_eq
                              : isListening
                              ? Icons.mic
                              : Icons.mic_none,

                          key: ValueKey(
                            isSpeaking
                                ? 1
                                : isListening
                                ? 2
                                : 3,
                          ),

                          color: Colors.white,

                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),

                child: Text(
                  isSpeaking
                      ? "Naya is speaking..."
                      : isListening
                      ? "Listening..."
                      : "talk_to_naya".tr(),

                  key: ValueKey(
                    isSpeaking
                        ? 1
                        : isListening
                        ? 2
                        : 3,
                  ),

                  style: const TextStyle(
                    color: Colors.grey,

                    fontSize: 13,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
