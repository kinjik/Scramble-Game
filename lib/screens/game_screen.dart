import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
  int currentIndex = 0;
  int perLevelWords = 5;
  int points = 0;
  String recognized = '';

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
    _guessController.clear();
    setState(() {});
  }

  // ── Guess handling ──────────────────────────────────────────────────

  Future<void> _onSubmitGuess(String val) async {
    if (val.trim().toLowerCase() == answer.toLowerCase()) {
      setState(() => answered = true);
      await _audio.playSuccess();
      await _audio.speak('Great! Now pronounce the word.');
    } else {
      await _audio.playFail();
      _guessController.clear();
      _showSnack('Wrong — try again', false);
    }
  }

  // ── Pronunciation ───────────────────────────────────────────────────

  Future<void> _listenAndVerifyPronunciation() async {
    final heard = await _speechService.listenForPronunciation(
      onPartialResult: (text) => setState(() => recognized = text),
    );

    if (heard.isEmpty) {
      _showSnack('Speech not available on this device', false);
      return;
    }

    if (_speechService.isPronunciationCorrect(heard, answer)) {
      points += 20;
      _confettiController.play();
      await _audio.playSuccess();
      _showSnack('Nice pronunciation! +20', true);
      await Future.delayed(const Duration(milliseconds: 800));
      _advanceOrComplete();
    } else {
      await _audio.playFail();
      _showSnack(
          'Could not detect correct pronunciation. Try again.', false);
    }
  }

  // ── Progression ─────────────────────────────────────────────────────

  void _advanceOrComplete() async {
    currentIndex++;
    if (currentIndex >= perLevelWords) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Level Complete! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/lottie/confetti.json',
                  width: 160, height: 120, repeat: false),
              const SizedBox(height: 8),
              Text('You finished Level ${widget.level}'),
              const SizedBox(height: 6),
              Text('Points: $points',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // back to level select
                },
                child: const Text('Back to Levels')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setupLevel(); // replay
                },
                child: const Text('Play Again')),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  void _showSnack(String message, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _guessController.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = (currentIndex / perLevelWords).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
                child: Text('Pts: $points',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.white]))),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress, minHeight: 10),
                  const SizedBox(height: 18),
                  // Word card
                  Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 20),
                      width: double.infinity,
                      child: Column(
                        children: [
                          const Text('Unscramble',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Text(scrambled,
                                key: ValueKey(scrambled),
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4)),
                          ),
                          const SizedBox(height: 16),
                          if (!answered)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextField(
                                controller: _guessController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'Type your guess here',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onSubmitted: _onSubmitGuess,
                              ),
                            )
                          else
                            Column(
                              children: [
                                Text('Now pronounce: "$answer"',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _listenAndVerifyPronunciation,
                                  icon: const Icon(Icons.mic),
                                  label: const Text('Pronounce'),
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                ),
                                const SizedBox(height: 8),
                                Text(recognized.isEmpty
                                    ? 'Heard: ...'
                                    : 'Heard: $recognized'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Word ${currentIndex + 1} / $perLevelWords'),
                      Text('Level ${widget.level}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (points >= 5) {
                            points -= 5;
                            _advanceOrComplete();
                            _showSnack('Skipped! -5 points', false);
                          } else {
                            _showSnack(
                                'You need at least 5 points to skip.',
                                false);
                          }
                          setState(() {});
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip (-5)'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _audio.speak(answer),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Hear Word'),
                      ),
                    ],
                  )
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
    );
  }
}
