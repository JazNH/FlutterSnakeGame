import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_over_dialog.dart';

enum Direction { up, down, left, right }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int rowSize = 20;
  static const int totalSquares = rowSize * rowSize;

  List<int> worker = [45, 65, 85];
  int paper = 300;
  List<int> obstacles = [];

  Direction direction = Direction.down;
  int score = 0;
  int highScore = 0;

  int papersCollected = 0;

  Timer? timer;
  int gameSpeed = 200;

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadHighScore();

    obstacles.clear();
    generateNewPaper();
    startGame();
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('highScore', score);
    }
  }

  void startGame() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: gameSpeed), (_) {
      moveWorker();
    });
  }

  void updateSpeed() {
    int newSpeed = (200 - score * 5).clamp(80, 200);
    if (newSpeed != gameSpeed) {
      gameSpeed = newSpeed;
      startGame();
    }
  }

  void moveWorker() {
    if (!mounted) return;

    setState(() {
      int newHead;

      switch (direction) {
        case Direction.down:
          newHead = worker.last + rowSize;
          break;
        case Direction.up:
          newHead = worker.last - rowSize;
          break;
        case Direction.left:
          newHead = worker.last - 1;
          break;
        case Direction.right:
          newHead = worker.last + 1;
          break;
      }

      bool hitWall = newHead < 0 || newHead >= totalSquares;
      bool hitLeft = direction == Direction.left && worker.last % rowSize == 0;
      bool hitRight =
          direction == Direction.right && worker.last % rowSize == rowSize - 1;

      if (hitWall || hitLeft || hitRight || obstacles.contains(newHead)) {
        timer?.cancel();
        saveHighScore();
        showGameOver();
        return;
      }

      if (worker.contains(newHead)) {
        timer?.cancel();
        saveHighScore();
        showGameOver();
        return;
      }

      worker.add(newHead);

      /// 📄 COLLECT PAPER
      if (newHead == paper) {
        score++;
        papersCollected++;

        generateNewPaper();
        updateSpeed();

        /// 🧱 progressive obstacle system
        if (papersCollected >= 2) {
          spawnObstacle();
        }
      } else {
        worker.removeAt(0);
      }
    });
  }

  /// 🧱 SAFE OBSTACLE SPAWN (NO CRASH / NO INFINITE LOOP)
  void spawnObstacle() {
    if (obstacles.length > 60) return;

    final random = Random();
    int newObstacle;
    int attempts = 0;

    do {
      newObstacle = random.nextInt(totalSquares);
      attempts++;
      if (attempts > 20) return; // safety escape
    } while (
        worker.contains(newObstacle) ||
        newObstacle == paper ||
        obstacles.contains(newObstacle));

    obstacles.add(newObstacle);
  }

  /// 📄 SAFE PAPER SPAWN
  void generateNewPaper() {
    final random = Random();

    int attempts = 0;
    do {
      paper = random.nextInt(totalSquares);
      attempts++;
      if (attempts > 20) return;
    } while (worker.contains(paper) || obstacles.contains(paper));
  }

  void showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        onPlayAgain: () {
          Navigator.pop(context);
          resetGame();
        },
        onQuit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void resetGame() {
    worker = [45, 65, 85];
    direction = Direction.down;
    score = 0;
    papersCollected = 0;
    gameSpeed = 200;
    obstacles.clear();

    generateNewPaper();
    startGame();
  }

  void changeDirection(Direction newDirection) {
    direction = newDirection;
  }

  Widget buildCell(int index) {
    if (index == worker.last) {
      return Image.asset('assets/worker.png');
    } else if (worker.contains(index)) {
      return Image.asset('assets/paper.png');
    } else if (index == paper) {
      return Image.asset('assets/paper.png');
    } else if (obstacles.contains(index)) {
      return Image.asset('assets/desk.png');
    } else {
      return Container(color: const Color(0xFFF2F3F8));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF6F7FB),
              Color(0xFFE9ECF5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// 🍎 HUD
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Text(
                      "📄 $score",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Best: $highScore",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🎮 BOARD
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          changeDirection(details.delta.dy > 0
                              ? Direction.down
                              : Direction.up);
                        },
                        onHorizontalDragUpdate: (details) {
                          changeDirection(details.delta.dx > 0
                              ? Direction.right
                              : Direction.left);
                        },
                        child: GridView.builder(
                          itemCount: totalSquares,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: rowSize,
                          ),
                          itemBuilder: (context, index) {
                            return buildCell(index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}