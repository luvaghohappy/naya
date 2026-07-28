import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:naya/pages/History.dart';
import 'package:naya/pages/Home.dart';
import 'package:naya/pages/Insights.dart';
import 'package:naya/pages/Settings.dart';

class NavigationPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const NavigationPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int currentIndex = 0;

  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  final List<IconData> icons = [
    Icons.home,
    Icons.history,
    Icons.insights,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> labels = [
      "home".tr(),
      "history".tr(),
      "insights".tr(),
      "settings".tr(),
    ];

    final List<Widget> screens = [
      HomePage(key: homeKey),

      History(
        onConversationSelected: (conversationId) async {
          await homeKey.currentState?.openConversation(conversationId);

          if (mounted) {
            setState(() {
              currentIndex = 0;
            });
          }
        },

        onNewConversation: () async {
          await homeKey.currentState?.startNewConversation();

          if (mounted) {
            setState(() {
              currentIndex = 0;
            });
          }
        },
      ),

      const Insights(),

      Settings(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,

      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 60),

        child: Container(
          height: 80,

          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,

            borderRadius: BorderRadius.circular(30),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: List.generate(icons.length, (index) {
              final bool isSelected = currentIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentIndex = index;
                  });
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),

                  curve: Curves.easeOut,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Transform.translate(
                        offset: Offset(0, isSelected ? -18 : 0),

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),

                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 127, 21, 146)
                                : Colors.transparent,

                            shape: BoxShape.circle,

                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                        255,
                                        127,
                                        21,
                                        146,
                                      ).withOpacity(0.4),

                                      blurRadius: 15,

                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : [],
                          ),

                          child: Icon(
                            icons[index],

                            size: 26,

                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(255, 82, 44, 148),
                          ),
                        ),
                      ),

                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),

                        opacity: isSelected ? 1 : 0.7,

                        child: Text(
                          labels[index],

                          style: TextStyle(
                            fontSize: 12,

                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,

                            color: isSelected
                                ? const Color.fromARGB(255, 127, 21, 146)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
