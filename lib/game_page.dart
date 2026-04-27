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

  /// ✅ UPDATED: store obstacle type + position
  List<Map<String, dynamic>> obstacles = [];

  /// obstacle rotation
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

    obstacles.clear();
    generateNewPaper();
  }

  // ---------------- SETTINGS ----------------

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

      /// ✅ UPDATED obstacle collision
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
            obstacles.any((o) => o['index'] == newObstacle)) &&
        attempts < 100);

    /// ✅ cycle type
    String type = obstacleTypes[obstacleIndex];
    obstacleIndex = (obstacleIndex + 1) % obstacleTypes.length;

    obstacles.add({
      'index': newObstacle,
      'type': type,
    });
  }

  void generateNewPaper() {
    final random = Random();

    int attempts = 0;
    do {
      paper = random.nextInt(totalSquares);
      attempts++;
    } while (
        (worker.contains(paper) ||
            obstacles.any((o) => o['index'] == paper)) &&
        attempts < 100);
  }

  // ---------------- GAME OVER ----------------

  void showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        onSubmit: (name) {},
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

  // ---------------- UI ----------------

  String getHeadImage() {
    if (isGirl) {
      switch (direction) {
        case Direction.up:
          return 'gb.png';
        default:
          return 'gf.png';
      }
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
      /// ✅ render obstacle by type
      final obstacle = obstacles.firstWhere(
        (o) => o['index'] == index,
        orElse: () => {},
      );

      if (obstacle.isNotEmpty) {
        return Image.asset('${obstacle['type']}.png');
      }

      return Container(color: const Color(0xFFF2F3F8));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
    );
  }
}