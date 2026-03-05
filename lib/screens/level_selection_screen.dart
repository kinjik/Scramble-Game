import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final int unlocked;
  const LevelSelectionScreen({super.key, required this.unlocked});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late int unlockedLevel;

  static const _levelEmojis = ['🌱', '🌿', '🌳', '🔥', '💎'];
  static const _levelLabels = [
    'Beginner',
    'Easy',
    'Medium',
    'Hard',
    'Master'
  ];

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

  Widget _levelTile(int level, int index) {
    final locked = level > unlockedLevel;
    final completed = level < unlockedLevel;
    final gradient = AppGradients.levelGradient(level);

    return GestureDetector(
      onTap: () => _openLevel(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: locked
            ? GlassDecoration.card(borderRadius: 20)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
        child: Stack(
          children: [
            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_levelEmojis[level - 1],
                      style: TextStyle(fontSize: locked ? 28 : 36)),
                  const SizedBox(height: 8),
                  Text('Level $level',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: locked
                              ? AppColors.textMuted
                              : AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_levelLabels[level - 1],
                      style: TextStyle(
                          fontSize: 12,
                          color: locked
                              ? AppColors.textMuted
                              : AppColors.textSecondary)),
                ],
              ),
            ),
            // Lock / Star
            if (locked)
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.lock_rounded,
                    color: AppColors.textMuted, size: 20),
              )
            else if (completed)
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.check_circle,
                    color: Colors.white70, size: 20),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * index))
        .scaleXY(begin: 0.85, end: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const GlassContainer(
                        padding: EdgeInsets.all(10),
                        borderRadius: 12,
                        blur: 8,
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('Select Level',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    'Level ${unlockedLevel > 5 ? 5 : unlockedLevel} of 5 unlocked',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                // Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: List.generate(
                        5, (i) => _levelTile(i + 1, i)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
