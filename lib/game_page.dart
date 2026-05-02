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

  List<Map<String, dynamic>> obstacles = [];
  final List<String> obstacleTypes = ['desk', 'water', 'trash'];
  int obstacleIndex = 0;

  Direction direction = Direction.down;
  Direction? pendingDirection;

  int score = 0;
  int highScore = 0;
  int papersCollected = 0;

  Timer? timer;
  Timer? settingsTimer;

  int gameSpeed = 200;
  bool isEasy = true;
  bool isGirl = false;

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadSettings();
    loadHighScore();
    startWatchingSettings();
    generateNewPaper();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isEasy = prefs.getBool('isEasy') ?? true;
    isGirl = prefs.getBool('isGirl') ?? false;
    gameSpeed = isEasy ? 200 : 100;
    startGame();
  }

  void startWatchingSettings() {
    settingsTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final prefs = await SharedPreferences.getInstance();

      bool newIsEasy = prefs.getBool('isEasy') ?? true;
      bool newIsGirl = prefs.getBool('isGirl') ?? false;

      if (newIsEasy != isEasy || newIsGirl != isGirl) {
        setState(() {
          isEasy = newIsEasy;
          isGirl = newIsGirl;
          gameSpeed = isEasy ? 200 : 100;
        });
        startGame();
      }
    });
  }

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

      bool hitObstacle =
          obstacles.any((o) => o['index'] == newHead);

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

  void spawnObstacle() {
    if (obstacles.length > 60) return;

    final random = Random();
    int newObstacle;

    do {
      newObstacle = random.nextInt(totalSquares);
    } while (
        worker.contains(newObstacle) ||
        newObstacle == paper ||
        obstacles.any((o) => o['index'] == newObstacle));

    String type = obstacleTypes[obstacleIndex];
    obstacleIndex = (obstacleIndex + 1) % obstacleTypes.length;

    obstacles.add({
      'index': newObstacle,
      'type': type,
    });
  }

  void generateNewPaper() {
    final random = Random();

    do {
      paper = random.nextInt(totalSquares);
    } while (
        worker.contains(paper) ||
        obstacles.any((o) => o['index'] == paper));
  }

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
    obstacleIndex = 0;

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

  String getHeadImage() {
    if (isGirl) {
      return direction == Direction.up ? 'gb.png' : 'gf.png';
    } else {
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
  }

  Widget buildCell(int index) {
    if (index == worker.last) {
      return Image.asset(getHeadImage());
    } else if (worker.contains(index)) {
      return Image.asset('paper.png');
    } else if (index == paper) {
      return Image.asset('paper.png');
    } else {
      final obstacle = obstacles.firstWhere(
        (o) => o['index'] == index,
        orElse: () => {},
      );

      if (obstacle.isNotEmpty) {
        return Image.asset('${obstacle['type']}.png');
      }

      return Container(color: Colors.transparent);
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
                colors: [Color(0xFFEAF2FF), Color(0xFFFCE4EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(color: Colors.white.withOpacity(0.08)),
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
                      Text("📄 $score",
                          style: const TextStyle(
                              fontSize: 34, fontWeight: FontWeight.bold)),
                      Text("Best: $highScore",
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;

                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Container(
                            margin: const EdgeInsets.all(8),
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
                              child: Stack(
                                children: [
                                  // 🖼 Background Image
                                  Positioned.fill(
                                    child: Image.asset(
                                      'background.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  // 🌫 Gray overlay (40% tint)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.grey.withOpacity(0.4),
                                    ),
                                  ),

                                  // 🎮 Game Grid
                                  GestureDetector(
                                    onPanUpdate: (details) {
                                      if (details.delta.dx.abs() > details.delta.dy.abs()) {
                                        changeDirection(details.delta.dx > 0
                                            ? Direction.right
                                            : Direction.left);
                                      } else {
                                        changeDirection(details.delta.dy > 0
                                            ? Direction.down
                                            : Direction.up);
                                      }
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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