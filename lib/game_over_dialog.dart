import 'package:flutter/material.dart';

class GameOverDialog extends StatefulWidget {
  final int score;
  final Function(String) onSubmit;
  final VoidCallback onPlayAgain;
  final VoidCallback onQuit;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.onSubmit,
    required this.onPlayAgain,
    required this.onQuit,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Game Over 💀"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("You collected ${widget.score} papers!"),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter your name",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSubmit(controller.text.trim());
            widget.onPlayAgain();
          },
          child: const Text("Save & Play Again"),
        ),
        TextButton(
          onPressed: () {
            widget.onSubmit(controller.text.trim());
            widget.onQuit();
          },
          child: const Text("Save & Quit"),
        ),
      ],
    );
  }
}