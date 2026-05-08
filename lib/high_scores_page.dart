import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighScoresPage extends StatefulWidget {
  const HighScoresPage({super.key});

  @override
  State<HighScoresPage> createState() => _HighScoresPageState();
}

class _HighScoresPageState extends State<HighScoresPage> {
  List<Map<String, dynamic>> scores = [];

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  // LOAD SCORES
  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('leaderboard');

    if (data != null) {
      final decoded = jsonDecode(data) as List;

      scores = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Sort highest -> lowest
      scores.sort(
        (a, b) => (b['score'] as int).compareTo(a['score'] as int),
      );
    }

    setState(() {});
  }

  // SAVE A NEW SCORE
  static Future<void> saveScore(String name, int score) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing leaderboard
    final data = prefs.getString('leaderboard');

    List<Map<String, dynamic>> scores = [];

    if (data != null) {
      final decoded = jsonDecode(data) as List;

      scores = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // Add new score
    scores.add({
      'name': name,
      'score': score,
    });

    // Sort scores
    scores.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    // Optional: keep only top 10
    if (scores.length > 10) {
      scores = scores.sublist(0, 10);
    }

    // Save back to phone storage
    await prefs.setString(
      'leaderboard',
      jsonEncode(scores),
    );
  }

  // OPTIONAL: CLEAR ALL SCORES
  Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('leaderboard');

    setState(() {
      scores = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏆 High Scores"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearScores,
          ),
        ],
      ),
      body: scores.isEmpty
          ? const Center(
              child: Text("No scores yet!"),
            )
          : ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final item = scores[index];

                return ListTile(
                  leading: Text("#${index + 1}"),
                  title: Text(item['name']),
                  trailing: Text(
                    "${item['score']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
    );
  }
}