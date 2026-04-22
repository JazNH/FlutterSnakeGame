import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  bool started = false;

  final AudioPlayer player = AudioPlayer();
  final Random random = Random();

  late AnimationController floatController;

  @override
  void initState() {
    super.initState();

    /// 🌫️ floating animation controller
    floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    /// 🎵 loop menu music
    _startMusic();
  }

  Future<void> _startMusic() async {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/menu.mp3'));
  }

  @override
  void dispose() {
    floatController.dispose();
    player.dispose();
    super.dispose();
  }

  /// 🎴 floating paper background
  Widget floatingPaper(double size, double delay) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        final offset = sin(floatController.value * 2 * pi + delay) * 20;

        return Transform.translate(
          offset: Offset(offset, offset / 2),
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.description,
              size: size,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  /// ✨ arcade button
  Widget arcadeButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 1),
        duration: const Duration(milliseconds: 150),
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() {}),
          onTapUp: (_) => setState(() {}),
          onTap: () {
            player.play(AssetSource('click.mp3'));

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GamePage()),
            );
          },
          child: Container(
            height: 72,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: Colors.black87),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void startGameIntro() {
    setState(() => started = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌈 gradient base
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

          /// 🎴 floating background layer
          if (started)
            Positioned.fill(
              child: Stack(
                children: [
                  floatingPaper(80, 0),
                  floatingPaper(60, 1),
                  floatingPaper(100, 2),
                ],
              ),
            ),

          /// 🌫️ blur glass overlay
          Container(
            color: Colors.white.withOpacity(0.08),
          ),

          SafeArea(
            child: started ? buildMenu() : buildIntro(),
          ),
        ],
      ),
    );
  }

  /// 🎮 INTRO SCREEN (arcade start feel)
  Widget buildIntro() {
    return Center(
      child: GestureDetector(
        onTap: startGameIntro,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "PRESS START",
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 6,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "START",
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 4,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎮 MAIN MENU
  Widget buildMenu() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),

        const Text(
          "OFFICE RUSH",
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Tap • Collect • Survive",
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 40),

        arcadeButton(
          text: "Start Game",
          icon: Icons.play_arrow_rounded,
          onTap: () {},
        ),

        arcadeButton(
          text: "Settings",
          icon: Icons.settings,
          onTap: () {},
        ),

        arcadeButton(
          text: "High Scores",
          icon: Icons.emoji_events,
          onTap: () {},
        ),

        const Spacer(),
      ],
    );
  }
}