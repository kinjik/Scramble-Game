import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'level_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  int unlockedLevel = 1;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final level = await _storage.getUnlockedLevel();
    final score = await _storage.getHighScore();
    setState(() {
      unlockedLevel = level;
      highScore = score;
    });
  }

  void _goToLevelSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => LevelSelectionScreen(unlocked: unlockedLevel)),
    ).then((_) => _loadProgress());
  }

  void _showHowTo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('How to Play'),
        content: const Text(
          '1) Choose a level.\n'
          '2) Unscramble the displayed word (type it).\n'
          '3) When correct, press Pronounce and speak the word.\n'
          '4) Correct pronunciation unlocks the next level.\n'
          'Each level contains multiple words and gives points.\nGood luck!',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade600, Colors.indigo.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scramble',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('High Score',
                            style: TextStyle(color: Colors.white70)),
                        Text('$highScore',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Card
                        Hero(
                          tag: 'logo',
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22)),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white,
                                  Colors.teal.shade50
                                ]),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lightbulb,
                                      size: 64, color: Colors.teal),
                                  SizedBox(height: 12),
                                  Text('Word Scramble',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  Text('Speak • Solve • Level Up',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 34, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _goToLevelSelection,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('How to Play'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          onPressed: _showHowTo,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                    'Built for BEED Thesis — Informative Game, unlockable levels, voice check.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
