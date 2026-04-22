import 'package:flutter/material.dart';

class GameOverDialog extends StatelessWidget {
  final int score;
  final VoidCallback onPlayAgain;
  final VoidCallback onQuit;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.onPlayAgain,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Game Over 💀"),
      content: Text("You collected $score papers!"),
      actions: [
        TextButton(
          onPressed: onPlayAgain,
          child: const Text("Play Again"),
        ),
        TextButton(
          onPressed: onQuit,
          child: const Text("Quit"),
        ),
      ],
    );
  }
}