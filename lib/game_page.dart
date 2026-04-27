import 'dart:async';
import 'dart:math';
import 'dart:convert';
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
  Direction? pendingDirection;

  int score = 0;
  int highScore = 0;
  int papersCollected = 0;

  Timer? timer;
  Timer? settingsTimer; // ✅ LIVE SETTINGS WATCHER

  int gameSpeed = 200;
  bool isEasy = true;

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    loadSettings();
    loadHighScore();
    startWatchingSettings(); // ✅ REAL-TIME DIFFICULTY UPDATES

    obstacles.clear();
    generateNewPaper();
  }

  // ---------------- SETTINGS ----------------

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    isEasy = prefs.getBool('isEasy') ?? true;
    gameSpeed = isEasy ? 200 : 100;

    startGame();
  }

  void startWatchingSettings() {
    settingsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final prefs = await SharedPreferences.getInstance();
      bool newIsEasy = prefs.getBool('isEasy') ?? true;

      if (newIsEasy != isEasy) {
        setState(() {
          isEasy = newIsEasy;
          gameSpeed = isEasy ? 200 : 100;
        });

        startGame(); // restart timer only (NOT game state)
      }
    });
  }

  // ---------------- HIGH SCORE ----------------

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> updateHighScoreIfNeeded() async {
    if (score > highScore) {
      setState(() {
        highScore = score;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', highScore);
    }
  }

  // ---------------- LEADERBOARD ----------------

  Future<void> saveScore(String name) async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('leaderboard');
    List list = [];

    if (data != null) {
      list = jsonDecode(data);
    }

    list.add({
      "name": name.isEmpty ? "Player" : name,
      "score": score,
    });

    list.sort((a, b) => b['score'].compareTo(a['score']));

    if (list.length > 20) {
      list = list.sublist(0, 20);
    }

    await prefs.setString('leaderboard', jsonEncode(list));
  }

  // ---------------- GAME LOOP ----------------

  void startGame() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: gameSpeed), (_) {
      moveWorker();
    });
  }

  void updateSpeed() {
    int base = isEasy ? 200 : 100;
    int min = isEasy ? 80 : 50;

    int newSpeed = (base - score * 5).clamp(min, base);

    if (newSpeed != gameSpeed) {
      gameSpeed = newSpeed;
      startGame();
    }
  }

  void changeDirection(Direction newDirection) {
    pendingDirection = newDirection;
  }

  void applyDirection(Direction newDirection) {
    if ((direction == Direction.up && newDirection == Direction.down) ||
        (direction == Direction.down && newDirection == Direction.up) ||
        (direction == Direction.left && newDirection == Direction.right) ||
        (direction == Direction.right && newDirection == Direction.left)) {
      return;
    }
    direction = newDirection;
  }

  void moveWorker() {
    if (!mounted) return;

    setState(() {
      if (pendingDirection != null) {
        applyDirection(pendingDirection!);
        pendingDirection = null;
      }

      int currentHead = worker.last;
      int newHead;

      switch (direction) {
        case Direction.down:
          newHead = currentHead + rowSize;
          break;
        case Direction.up:
          newHead = currentHead - rowSize;
          break;
        case Direction.left:
          newHead = currentHead - 1;
          break;
        case Direction.right:
          newHead = currentHead + 1;
          break;
      }

      bool hitWall = newHead < 0 || newHead >= totalSquares;

      bool wrapped =
          (direction == Direction.left &&
              newHead ~/ rowSize != currentHead ~/ rowSize) ||
          (direction == Direction.right &&
              newHead ~/ rowSize != currentHead ~/ rowSize);

      bool hitObstacle = obstacles.contains(newHead);
      bool hitSelf = worker.contains(newHead);

      if (hitWall || wrapped || hitObstacle || hitSelf) {
        timer?.cancel();
        updateHighScoreIfNeeded();
        showGameOver();
        return;
      }

      worker.add(newHead);

      if (newHead == paper) {
        score++;
        papersCollected++;

        updateHighScoreIfNeeded();

        generateNewPaper();
        updateSpeed();

        if (papersCollected >= 2) {
          spawnObstacle();
        }
      } else {
        worker.removeAt(0);
      }
    });
  }

  // ---------------- WORLD ----------------

  void spawnObstacle() {
    if (obstacles.length > 60) return;

    final random = Random();
    int newObstacle;
    int attempts = 0;

    do {
      newObstacle = random.nextInt(totalSquares);
      attempts++;
    } while (
        (worker.contains(newObstacle) ||
            newObstacle == paper ||
            obstacles.contains(newObstacle)) &&
        attempts < 100);

    if (!worker.contains(newObstacle) &&
        newObstacle != paper &&
        !obstacles.contains(newObstacle)) {
      obstacles.add(newObstacle);
    }
  }

  void generateNewPaper() {
    final random = Random();

    int attempts = 0;
    do {
      paper = random.nextInt(totalSquares);
      attempts++;
    } while (
        (worker.contains(paper) || obstacles.contains(paper)) &&
        attempts < 100);
  }

  // ---------------- GAME OVER ----------------

  void showGameOver() {
    if (score <= 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Game Over 💀"),
          content: Text("You collected $score papers!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: const Text("Play Again"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Quit"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        onSubmit: (name) {
          saveScore(name);
        },
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
    pendingDirection = null;
    score = 0;
    papersCollected = 0;

    gameSpeed = isEasy ? 200 : 100;

    obstacles.clear();

    generateNewPaper();
    startGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    settingsTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  String getHeadImage() {
    switch (direction) {
      case Direction.up:
        return 'back.png';
      case Direction.down:
        return 'worker.png';
      case Direction.left:
        return 'lf.png';
      case Direction.right:
        return 'rf.png';
    }
  }

  Widget buildCell(int index) {
    if (index == worker.last) {
      return Image.asset(getHeadImage());
    } else if (worker.contains(index)) {
      return Image.asset('paper.png');
    } else if (index == paper) {
      return Image.asset('paper.png');
    } else if (obstacles.contains(index)) {
      return Image.asset('desk.png');
    } else {
      return Container(color: const Color(0xFFF2F3F8));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          Container(
            color: Colors.white.withOpacity(0.08),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

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
        ],
      ),
    );
  }
}