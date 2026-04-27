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

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('leaderboard');

    if (data != null) {
      final decoded = jsonDecode(data) as List;
      scores = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      scores.sort((a, b) => b['score'].compareTo(a['score']));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏆 High Scores")),
      body: scores.isEmpty
          ? const Center(child: Text("No scores yet!"))
          : ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final item = scores[index];

                return ListTile(
                  leading: Text("#${index + 1}"),
                  title: Text(item['name']),
                  trailing: Text(
                    "${item['score']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }
}