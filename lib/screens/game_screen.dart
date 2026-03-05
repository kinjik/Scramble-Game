import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../app_theme.dart';
import '../models/game_data.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';

class ScrambleGameScreen extends StatefulWidget {
  final int level;
  const ScrambleGameScreen({super.key, required this.level});

  @override
  State<ScrambleGameScreen> createState() => _ScrambleGameScreenState();
}

class _ScrambleGameScreenState extends State<ScrambleGameScreen> {
  // Services
  final AudioService _audio = AudioService();
  final SpeechService _speechService = SpeechService();
  final StorageService _storage = StorageService();

  // Game state
  List<String> wordPool = [];
  String answer = '';
  String scrambled = '';
  bool answered = false;
  bool loading = true;
  bool isListening = false;
  int currentIndex = 0;
  int perLevelWords = 5;
  int points = 0;
  String recognized = '';

  // Hint state
  Set<int> revealedIndices = {};

  // Timer state
  static const int _maxSeconds = 30;
  int _secondsLeft = _maxSeconds;
  Timer? _timer;

  // UI controllers
  late ConfettiController _confettiController;
  final TextEditingController _guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _setupLevel();
  }

  Future<void> _setupLevel() async {
    wordPool = await GameData.wordsForLevel(widget.level);
    currentIndex = 0;
    points = 0;
    _loadWord();
    setState(() => loading = false);
  }

  void _loadWord() {
    answer = wordPool[currentIndex % wordPool.length];
    scrambled = GameData.scramble(answer);
    answered = false;
    recognized = '';
    revealedIndices.clear();
    _guessController.clear();
    _startTimer();
    setState(() {});
  }

  // ── Timer ─────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _maxSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _showSnack('⏰  Time\'s up!', false);
        _advanceOrComplete();
      }
    });
  }

  // ── Hint ──────────────────────────────────────────────────────────────

  void _useHint() {
    if (points < 10) {
      _showSnack('Need 10+ points for a hint', false);
      return;
    }
    // Find an un-revealed position
    for (int i = 0; i < answer.length; i++) {
      if (!revealedIndices.contains(i)) {
        setState(() {
          revealedIndices.add(i);
          points -= 10;
        });
        return;
      }
    }
    _showSnack('All letters already revealed!', false);
  }

  // ── Shuffle ───────────────────────────────────────────────────────────

  void _reshuffleWord() {
    setState(() => scrambled = GameData.scramble(answer));
  }

  // ── Guess handling ────────────────────────────────────────────────────

  Future<void> _onSubmitGuess(String val) async {
    if (val.trim().toLowerCase() == answer.toLowerCase()) {
      setState(() => answered = true);
      _timer?.cancel();
      await _audio.playSuccess();
      await _audio.speak('Great! Now pronounce the word.');
    } else {
      await _audio.playFail();
      _guessController.clear();
      _showSnack('Wrong — try again', false);
    }
  }

  // ── Pronunciation ─────────────────────────────────────────────────────

  Future<void> _listenAndVerifyPronunciation() async {
    setState(() => isListening = true);

    final result = await _speechService.listenForPronunciation(
      onPartialResult: (text) => setState(() => recognized = text),
    );

    if (!mounted) return;
    setState(() => isListening = false);

    if (!result.available) {
      _showSnack(
          'Microphone permission denied or speech service unavailable. '
          'Please allow microphone access in Settings.',
          false);
      return;
    }

    if (result.recognised.isEmpty) {
      _showSnack(
          'No speech detected — speak closer to the mic and try again.',
          false);
      return;
    }

    if (_speechService.isPronunciationCorrect(result.recognised, answer)) {
      points += 20;
      _confettiController.play();
      await _audio.playSuccess();
      _showSnack('Nice pronunciation! +20 ✨', true);
      await Future.delayed(const Duration(milliseconds: 800));
      _advanceOrComplete();
    } else {
      await _audio.playFail();
      _showSnack('Could not detect correct pronunciation. Try again.', false);
    }
  }

  // ── Progression ───────────────────────────────────────────────────────

  void _advanceOrComplete() async {
    currentIndex++;
    if (currentIndex >= perLevelWords) {
      _timer?.cancel();
      await _onLevelComplete();
    } else {
      _loadWord();
    }
  }

  Future<void> _onLevelComplete() async {
    await _storage.tryUnlockNext(widget.level);
    await _storage.tryUpdateHighScore(points);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.bgMid,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Level Complete! 🎉',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/lottie/confetti.json',
                  width: 160, height: 120, repeat: false),
              const SizedBox(height: 12),
              Text('You finished Level ${widget.level}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppGradients.accentButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$points pts',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white)),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Back to Levels')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setupLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.bgStart,
                ),
                child: const Text('Play Again')),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _showSnack(String message, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _guessController.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.accent)));
    }

    final progress = (currentIndex / perLevelWords).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12),
                child: Column(
                  children: [
                    // ── Top bar ──
                    _buildTopBar(),
                    const SizedBox(height: 14),

                    // ── Progress ──
                    _buildProgressBar(progress),
                    const SizedBox(height: 18),

                    // ── Timer ──
                    _buildTimer(),
                    const SizedBox(height: 14),

                    // ── Word Card ──
                    Expanded(child: _buildWordCard()),

                    const SizedBox(height: 12),

                    // ── Controls ──
                    _buildControls(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                maxBlastForce: 20,
                minBlastForce: 6,
                numberOfParticles: 24,
                emissionFrequency: 0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
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
        const SizedBox(width: 12),
        Text('Level ${widget.level}',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const Spacer(),
        GlassContainer(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: 12,
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              Text('$points',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Word ${currentIndex + 1} / $perLevelWords',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.cardBg,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    final isLow = _secondsLeft <= 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer,
            color: isLow ? AppColors.error : AppColors.textSecondary,
            size: 18),
        const SizedBox(width: 6),
        Text(
          '${_secondsLeft}s',
          style: TextStyle(
            color: isLow ? AppColors.error : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 12),
        // Timer progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: _secondsLeft / _maxSeconds,
                backgroundColor: AppColors.cardBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                    isLow ? AppColors.error : AppColors.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      borderRadius: 22,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('UNSCRAMBLE',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2)),
            const SizedBox(height: 14),

            // ── Letter tiles ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Wrap(
                key: ValueKey(scrambled),
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: List.generate(scrambled.length, (i) {
                  return _LetterTile(
                    letter: scrambled[i],
                    index: i,
                  );
                }),
              ),
            ),

            // Hint display
            if (revealedIndices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: List.generate(answer.length, (i) {
                  final revealed = revealedIndices.contains(i);
                  return Container(
                    width: 28,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: revealed
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: revealed
                              ? AppColors.accent
                              : AppColors.textMuted,
                          width: 1),
                    ),
                    child: Text(
                      revealed ? answer[i].toUpperCase() : '_',
                      style: TextStyle(
                        color: revealed
                            ? AppColors.accent
                            : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 18),

            if (!answered)
              Column(
                children: [
                  // Input field
                  TextField(
                    controller: _guessController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Type your guess',
                      hintStyle:
                          const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                    onSubmitted: _onSubmitGuess,
                  ),
                  const SizedBox(height: 12),
                  // Hint + Shuffle buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SmallActionButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Hint (-10)',
                        color: AppColors.warning,
                        onTap: _useHint,
                      ),
                      const SizedBox(width: 12),
                      _SmallActionButton(
                        icon: Icons.shuffle,
                        label: 'Shuffle',
                        color: AppColors.accentPurple,
                        onTap: _reshuffleWord,
                      ),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text('Now pronounce: "$answer"',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 16)),
                  const SizedBox(height: 16),
                  // Pulsing mic button
                  GestureDetector(
                    onTap:
                        isListening ? null : _listenAndVerifyPronunciation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isListening
                            ? const LinearGradient(
                                colors: [AppColors.error, AppColors.accentPink])
                            : AppGradients.accentButton,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening
                                    ? AppColors.error
                                    : AppColors.accent)
                                .withValues(alpha: 0.4),
                            blurRadius: isListening ? 24 : 12,
                            spreadRadius: isListening ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                      .animate(
                          target: isListening ? 1.0 : 0.0,
                          onPlay: (c) {
                            if (isListening) c.repeat(reverse: true);
                          })
                      .scaleXY(begin: 1.0, end: 1.1, duration: 600.ms),
                  const SizedBox(height: 10),
                  Text(
                    recognized.isEmpty
                        ? 'Tap to pronounce'
                        : 'Heard: $recognized',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Skip button
        _ActionChip(
          icon: Icons.skip_next_rounded,
          label: 'Skip (-5)',
          gradient: AppGradients.warmButton,
          onTap: () {
            if (points >= 5) {
              points -= 5;
              _advanceOrComplete();
              _showSnack('Skipped! -5 points', false);
            } else {
              _showSnack('You need at least 5 points to skip.', false);
            }
            setState(() {});
          },
        ),
        // Hear word
        _ActionChip(
          icon: Icons.volume_up_rounded,
          label: 'Hear Word',
          gradient: const LinearGradient(
              colors: [AppColors.accentSoft, AppColors.accentPurple]),
          onTap: () => _audio.speak(answer),
        ),
      ],
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────

class _LetterTile extends StatelessWidget {
  final String letter;
  final int index;

  const _LetterTile({required this.letter, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3A5C), Color(0xFF1B2838)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 300.ms, delay: Duration(milliseconds: 60 * index))
        .slideY(begin: 0.3, end: 0);
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
