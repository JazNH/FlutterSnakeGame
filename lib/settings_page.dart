import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isGirl = false;
  bool isEasy = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // ✅ LOAD SETTINGS
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isGirl = prefs.getBool('isGirl') ?? false;
      isEasy = prefs.getBool('isEasy') ?? true;
    });
  }

  // ✅ SAVE SETTINGS
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isGirl', isGirl);
    await prefs.setBool('isEasy', isEasy);
  }

  // 🔥 NEW: SEGMENTED TOGGLE (THIS VS THAT)
  Widget dualToggle({
    required String leftLabel,
    required String rightLabel,
    required bool isRightSelected,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
          )
        ],
      ),
      child: Row(
        children: [
          /// LEFT OPTION
          Expanded(
            child: GestureDetector(
              onTap: onLeftTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !isRightSelected
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  leftLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !isRightSelected
                        ? Colors.black
                        : Colors.black38,
                  ),
                ),
              ),
            ),
          ),

          /// RIGHT OPTION
          Expanded(
            child: GestureDetector(
              onTap: onRightTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isRightSelected
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  rightLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRightSelected
                        ? Colors.black
                        : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌈 BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEAF2FF),
                  Color(0xFFFCE4EC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                /// 🔙 HEADER
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 👦 / 👧 CHARACTER
                dualToggle(
                  leftLabel: "Boy",
                  rightLabel: "Girl",
                  isRightSelected: isGirl,
                  onLeftTap: () {
                    setState(() => isGirl = false);
                    saveSettings();
                  },
                  onRightTap: () {
                    setState(() => isGirl = true);
                    saveSettings();
                  },
                ),

                /// 🎯 DIFFICULTY
                dualToggle(
                  leftLabel: "Easy",
                  rightLabel: "Hard",
                  isRightSelected: !isEasy,
                  onLeftTap: () {
                    setState(() => isEasy = true);
                    saveSettings();
                  },
                  onRightTap: () {
                    setState(() => isEasy = false);
                    saveSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}