import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final int unlocked;
  const LevelSelectionScreen({super.key, required this.unlocked});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late int unlockedLevel;

  @override
  void initState() {
    super.initState();
    unlockedLevel = widget.unlocked;
  }

  void _openLevel(int level) {
    if (level > unlockedLevel) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ScrambleGameScreen(level: level),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    ).then((_) async {
      final sp = await SharedPreferences.getInstance();
      setState(() {
        unlockedLevel = sp.getInt('unlockedLevel') ?? unlockedLevel;
      });
    });
  }

  String _labelForLevel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Master';
      default:
        return '';
    }
  }

  Widget _levelTile(int level) {
    final locked = level > unlockedLevel;
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.deepPurple,
      Colors.teal,
    ];
    return GestureDetector(
      onTap: () => _openLevel(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: locked
              ? null
              : LinearGradient(colors: [
                  colors[level - 1].shade400,
                  colors[level - 1].shade700
                ]),
          color: locked ? Colors.grey.shade200 : null,
          boxShadow: locked
              ? null
              : [
                  BoxShadow(
                      color: colors[level - 1].withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Level $level',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: locked ? Colors.black54 : Colors.white)),
                  const SizedBox(height: 8),
                  Text(_labelForLevel(level),
                      style: TextStyle(
                          color: locked ? Colors.black45 : Colors.white70)),
                ],
              ),
            ),
            if (locked)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.lock, color: Colors.grey.shade700),
              )
            else
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.star, color: Colors.white70),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Level'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: List.generate(5, (i) => _levelTile(i + 1)),
        ),
      ),
    );
  }
}
