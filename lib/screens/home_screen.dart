import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_theme.dart';
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
    if (!mounted) return;
    setState(() {
      unlockedLevel = level;
      highScore = score;
    });
  }

  void _goToLevelSelection() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            LevelSelectionScreen(unlocked: unlockedLevel),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    ).then((_) => _loadProgress());
  }

  void _showHowTo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.bgMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('How to Play',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _howToStep(Icons.touch_app, 'Choose a level from the grid'),
            _howToStep(Icons.edit, 'Unscramble the letters and type the word'),
            _howToStep(Icons.mic, 'Pronounce the word when prompted'),
            _howToStep(Icons.star, 'Earn points and unlock the next level'),
            _howToStep(Icons.lightbulb_outline,
                'Use Hint (-10 pts) or Shuffle for help'),
            _howToStep(Icons.timer, 'Beat the timer before it runs out!'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _howToStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            // Floating decorative shapes
            ..._buildFloatingShapes(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Scramble',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800))
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: -0.2),
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('HIGH SCORE',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1)),
                              Text('$highScore',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Center content
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            GlassContainer(
                              padding: const EdgeInsets.all(28),
                              borderRadius: 28,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        AppColors.accent,
                                        AppColors.accentPurple
                                      ]),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(Icons.extension,
                                        size: 48, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Word Scramble',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  const Text('Speak • Solve • Level Up',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 1)),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 800.ms, delay: 300.ms)
                                .scaleXY(begin: 0.85, end: 1),
                            const SizedBox(height: 36),
                            // Start button
                            _GradientButton(
                              gradient: AppGradients.accentButton,
                              icon: Icons.play_arrow_rounded,
                              label: 'Start Game',
                              onPressed: _goToLevelSelection,
                            )
                                .animate()
                                .fadeIn(duration: 600.ms, delay: 600.ms)
                                .slideY(begin: 0.3),
                            const SizedBox(height: 14),
                            // How to play
                            TextButton.icon(
                              onPressed: _showHowTo,
                              icon: const Icon(Icons.help_outline,
                                  color: AppColors.textSecondary, size: 18),
                              label: const Text('How to Play',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            )
                                .animate()
                                .fadeIn(duration: 600.ms, delay: 800.ms),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Built for BEED Thesis — Informative Game',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingShapes() {
    final rng = Random(42); // deterministic seed
    return List.generate(6, (i) {
      final size = 40.0 + rng.nextDouble() * 80;
      final left = rng.nextDouble() * 350;
      final top = rng.nextDouble() * 700;
      return Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (i.isEven ? AppColors.accent : AppColors.accentPurple)
                .withValues(alpha: 0.06),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
                begin: 0,
                end: 15 + rng.nextDouble() * 15,
                duration: Duration(milliseconds: 3000 + rng.nextInt(2000)))
            .fadeIn(duration: 1.seconds),
      );
    });
  }
}

/// A reusable gradient-filled button.
class _GradientButton extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.gradient,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
