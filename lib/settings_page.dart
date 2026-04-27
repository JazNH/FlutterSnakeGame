import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isBoy = true;
  bool isEasy = true;

  Widget dualToggle({
    required String leftLabel,
    required String rightLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// LEFT LABEL
          Expanded(
            child: Text(
              leftLabel,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: value ? Colors.black : Colors.black38,
              ),
            ),
          ),

          /// SWITCH (CENTER)
          Switch(
            value: value,
            onChanged: onChanged,
          ),

          /// RIGHT LABEL
          Expanded(
            child: Text(
              rightLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: !value ? Colors.black : Colors.black38,
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
          /// 🌈 SAME BACKGROUND
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
                /// 🔙 Back button + title
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

                /// 👦 BOY / GIRL
                /// 👦 BOY / GIRL
                dualToggle(
                  leftLabel: "Boy",
                  rightLabel: "Girl",
                  value: isBoy,
                  onChanged: (val) {
                    setState(() => isBoy = val);
                  },
                ),

                /// 🎯 EASY / HARD
                dualToggle(
                  leftLabel: "Easy",
                  rightLabel: "Hard",
                  value: isEasy,
                  onChanged: (val) {
                    setState(() => isEasy = val);
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