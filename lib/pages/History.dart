import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ConversationModel.dart';

enum HistoryFilter { all, today, thisWeek, thisMonth }

class History extends StatefulWidget {
  final Function(String conversationId)? onConversationSelected;
  final VoidCallback? onNewConversation;
  const History({
    super.key,
    this.onConversationSelected,
    this.onNewConversation,
  });

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<ConversationModel> conversations = [];

  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  HistoryFilter selectedFilter = HistoryFilter.all;

  bool isLoading = true;

  late final StreamSubscription<AuthState> authSubscription;

  Future<void> refreshHistory() async {
    setState(() {
      isLoading = true;
    });

    await loadConversations();
  }

  Future<void> refreshPage() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        conversations = [];
      });

      return;
    }

    await loadConversations();
  }

  @override
  void initState() {
    super.initState();

    loadConversations();

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

  Future<void> loadConversations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('Conversations')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final List<ConversationModel> loaded = [];

      for (final conversation in data) {
        final messages = await Supabase.instance.client
            .from('Messages')
            .select('message_id')
            .eq('id_conversation', conversation['conversation_id']);

        loaded.add(
          ConversationModel.fromJson(
            conversation,
            messageCount: messages.length,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        conversations = loaded;
        isLoading = false;
      });
    } catch (e) {
      print("Supabase error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  List<ConversationModel> get filtered => conversations.where((c) {
    final titleMatch = c.title.toLowerCase().contains(searchQuery);

    final emotionMatch = c.emotion.toLowerCase().contains(searchQuery);

    bool dateMatch = true;

    final now = DateTime.now();

    switch (selectedFilter) {
      case HistoryFilter.today:
        dateMatch =
            c.updatedAt.year == now.year &&
            c.updatedAt.month == now.month &&
            c.updatedAt.day == now.day;
        break;

      case HistoryFilter.thisWeek:
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        dateMatch =
            !c.updatedAt.isBefore(startOfWeek) &&
            c.updatedAt.isBefore(endOfWeek);

      case HistoryFilter.thisMonth:
        dateMatch =
            c.updatedAt.month == now.month && c.updatedAt.year == now.year;
        break;

      case HistoryFilter.all:
        dateMatch = true;
        break;
    }

    return (titleMatch || emotionMatch) && dateMatch;
  }).toList();

  ///Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('Messages')
        .delete()
        .eq('id_conversation', conversationId);

    await Supabase.instance.client
        .from('Conversations')
        .delete()
        .eq('conversation_id', conversationId);

    setState(() {
      conversations.removeWhere((c) => c.conversationId == conversationId);
    });
  }

  //Icon
  IconData getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case "joy":
      case "happy":
        return Icons.wb_sunny_rounded;

      case "sadness":
      case "sad":
        return Icons.cloud_rounded;

      case "stress":
        return Icons.flash_on_rounded;

      case "anxiety":
        return Icons.psychology_rounded;

      case "anger":
      case "angry":
        return Icons.local_fire_department_rounded;

      case "fear":
        return Icons.nightlight_round;

      case "depression":
        return Icons.cloud_off_rounded;

      case "calm":
        return Icons.spa_rounded;

      default:
        return Icons.auto_awesome_rounded;
    }
  }

  //Color
  Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case "joy":
      case "happy":
        return Colors.orange;

      case "sadness":
      case "sad":
        return Colors.blue;

      case "stress":
        return Colors.deepOrange;

      case "anxiety":
        return Colors.deepPurple;

      case "anger":
      case "angry":
        return Colors.red;

      case "fear":
        return Colors.indigo;

      case "depression":
        return Colors.blueGrey;

      case "calm":
        return Colors.green;

      default:
        return const Color(0xff6C63FF);
    }
  }

  ///Dialog delete
  Future<void> showDeleteDialog(String conversationId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("delete_conversation".tr()),
          content: Text("delete_conversation_confirmation".tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("cancel".tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await deleteConversation(conversationId);
              },
              child: Text("delete".tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              Text(
                "my_memories".tr(),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                "every_conversation_step_forward.".tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).cardColor,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),

                child: TextFormField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "search_conversations".tr(),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      filterChip(HistoryFilter.all, "all".tr()),
                      const SizedBox(width: 8),

                      filterChip(HistoryFilter.today, "today".tr()),
                      const SizedBox(width: 8),

                      filterChip(HistoryFilter.thisWeek, "this_week".tr()),
                      const SizedBox(width: 8),

                      filterChip(HistoryFilter.thisMonth, "this_month".tr()),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  itemCount: filtered.length,

                  itemBuilder: (context, index) {
                    final conversation = filtered[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),

                      child: Conversations(
                        conversation: conversation,
                        onTap: () {
                          widget.onConversationSelected?.call(
                            conversation.conversationId,
                          );
                        },
                      ),
                    );
                  },
                ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 50, right: 30, bottom: 140),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xff6C63FF),

            onPressed: widget.onNewConversation,

            icon: const Icon(Icons.add, color: Colors.white),

            label: Text(
              "new_conversation".tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget filterChip(HistoryFilter filter, String label) {
    final selected = selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff6C63FF)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? const Color(0xff6C63FF)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class Conversations extends StatelessWidget {
  final VoidCallback onTap;
  final ConversationModel conversation;

  const Conversations({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String formatDate(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat("h:mm a").format(date);
    }

    return DateFormat("MMM d").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HistoryState>();

    final emotionColor =
        state?.getEmotionColor(conversation.emotion) ?? const Color(0xff6C63FF);

    final emotionIcon =
        state?.getEmotionIcon(conversation.emotion) ?? Icons.auto_awesome;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),

        leading: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: emotionColor.withOpacity(.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(emotionIcon, color: emotionColor, size: 30),
        ),

        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.emotion,
                style: TextStyle(
                  color: emotionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    "${conversation.messageCount} messages",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.65),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Text("•"),

                  const SizedBox(width: 8),

                  Text(
                    formatDate(conversation.updatedAt),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),

          onSelected: (value) {
            if (value == "delete".tr()) {
              state?.showDeleteDialog(conversation.conversationId);
            }
          },

          itemBuilder: (context) => [
            PopupMenuItem(
              value: "delete".tr(),
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),

                  SizedBox(width: 10),

                  Text("delete".tr(), style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
