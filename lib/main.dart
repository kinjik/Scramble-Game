// lib/main.dart
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock the app to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ScrambleCapstoneApp());
}

class ScrambleCapstoneApp extends StatelessWidget {
  const ScrambleCapstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scramble — Capstone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/* ===========================
   Home Screen
   =========================== */

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int unlockedLevel = 1;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      unlockedLevel = sp.getInt('unlockedLevel') ?? 1;
      highScore = sp.getInt('highScore') ?? 0;
    });
  }

  void _goToLevelSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LevelSelectionScreen(unlocked: unlockedLevel)),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        //here is the error on _buildBackgroundGradient
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scramble', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('High Score', style: TextStyle(color: Colors.white70)),
                        Text('$highScore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.white, Colors.teal.shade50]),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.lightbulb, size: 64, color: Colors.teal),
                                  SizedBox(height: 12),
                                  Text('Word Scramble', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('Speak • Solve • Level Up', style: TextStyle(fontSize: 12)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _goToLevelSelection,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('How to Play'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Text('Built for BEED Thesis — Informative Game, unlockable levels, voice check.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.teal.shade600, Colors.indigo.shade600],
      ),
    );
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }
}

/* ===========================
   Level Selection (unlockable)
   =========================== */

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
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    ).then((result) async {
      // reload unlocked level from SharedPreferences after returning
      final sp = await SharedPreferences.getInstance();
      setState(() {
        unlockedLevel = sp.getInt('unlockedLevel') ?? unlockedLevel;
      });
    });
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
          gradient: locked ? null : LinearGradient(colors: [colors[level - 1].shade400, colors[level - 1].shade700]),
          color: locked ? Colors.grey.shade200 : null,
          boxShadow: locked ? null : [BoxShadow(color: colors[level - 1].withOpacity(0.25), blurRadius: 8, offset: const Offset(0,6))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Level $level', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: locked ? Colors.black54 : Colors.white)),
                  const SizedBox(height: 8),
                  Text(_labelForLevel(level), style: TextStyle(color: locked ? Colors.black45 : Colors.white70)),
                ],
              ),
            ),
            if (locked)
              Positioned(
                top: 8, right: 8,
                child: Icon(Icons.lock, color: Colors.grey.shade700),
              )
            else
              Positioned(
                top: 8, right: 8,
                child: const Icon(Icons.star, color: Colors.white70),
              )
          ],
        ),
      ),
    );
  }

  String _labelForLevel(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Easy';
      case 3: return 'Medium';
      case 4: return 'Hard';
      case 5: return 'Master';
      default: return '';
    }
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

/* ===========================
   Game Screen
   - multiple words per level
   - scoring
   - speech check
   - TTS, SFX, confetti, lottie
   =========================== */

class ScrambleGameScreen extends StatefulWidget {
  final int level;
  const ScrambleGameScreen({super.key, required this.level});

  @override
  State<ScrambleGameScreen> createState() => _ScrambleGameScreenState();
}

class _ScrambleGameScreenState extends State<ScrambleGameScreen> with SingleTickerProviderStateMixin {
  final Map<int, List<String>> wordsByLevel = {
    1: ['cat','dog','sun','hat','bat'],
    2: ['apple','chair','water','house','plant'],
    3: ['banana','school','window','garden','flower'],
    4: ['computer','mountain','building','elephant','teacher'],
    5: ['chocolate','university','helicopter','adventure','beautiful'],
  };

  late List<String> wordPool;
  late String answer;
  late String scrambled;
  bool answered = false;
  int currentIndex = 0;
  int perLevelWords = 5;
  int points = 0;
  String recognized = '';

  // features
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfx = AudioPlayer();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _setupLevel();
  }

  void _setupLevel() {
    wordPool = List.from(wordsByLevel[widget.level] ?? ['test']);
    wordPool.shuffle();
    currentIndex = 0;
    points = 0;
    _loadWord();
  }

  void _loadWord() {
    answer = wordPool[currentIndex % wordPool.length];
    scrambled = _scramble(answer);
    answered = false;
    recognized = '';
    setState(() {});
  }

  String _scramble(String w) {
    final chars = w.split('')..shuffle(Random());
    final joined = chars.join();
    // Ensure scrambled differs from original (if short).
    if (joined == w && w.length > 1) {
      return _scramble(w);
    }
    return joined;
  }

  Future<void> _onSubmitGuess(String val) async {
    if (val.trim().toLowerCase() == answer.toLowerCase()) {
      // correct unscramble
      setState(() => answered = true);
      await _playSfx('assets/sfx/success.mp3'); // small success chime
      await _speak('Great! Now pronounce the word.');
    } else {
      await _playSfx('assets/sfx/fail.mp3');
      _showSnack('Wrong — try again', false);
    }
  }

  Future<void> _listenAndVerifyPronunciation() async {
    bool available = await _speech.initialize();
    if (!available) {
      _showSnack('Speech not available on this device', false);
      return;
    }
    _speech.listen(onResult: (res) {
      setState(() => recognized = res.recognizedWords);
    });
    // Listen for 2.5 seconds then stop
    await Future.delayed(const Duration(milliseconds: 2500));
    _speech.stop();

    final sim = ratio(recognized.toLowerCase(), answer.toLowerCase());
    if (sim > 75) {
      // success
      points += 20; // pronounce points
      _confettiController.play();
      await _playSfx('assets/sfx/success.mp3');
      _showSnack('Nice pronunciation! +20', true);
      await Future.delayed(const Duration(milliseconds: 800));
      _advanceOrComplete();
    } else {
      await _playSfx('assets/sfx/fail.mp3');
      _showSnack('Could not detect correct pronunciation. Try again.', false);
    }
  }

  void _advanceOrComplete() async {
    currentIndex++;
    if (currentIndex >= perLevelWords) {
      // level complete
      await _onLevelComplete();
    } else {
      _loadWord();
    }
  }

  Future<void> _onLevelComplete() async {
    // save unlock progress & high score
    final sp = await SharedPreferences.getInstance();
    final unlocked = sp.getInt('unlockedLevel') ?? 1;
    if (widget.level >= unlocked && unlocked < 5) {
      sp.setInt('unlockedLevel', unlocked + 1);
    }
    final high = sp.getInt('highScore') ?? 0;
    if (points > high) sp.setInt('highScore', points);

    // show celebration dialog with lottie + confetti
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Level Complete! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/lottie/confetti.json', width: 160, height: 120, repeat: false),
              const SizedBox(height: 8),
              Text('You finished Level ${widget.level}'),
              const SizedBox(height: 6),
              Text('Points: $points', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // back to level select
            }, child: const Text('Back to Levels')),
            ElevatedButton(onPressed: () {
              Navigator.pop(context);
              // replay same level (reset)
              _setupLevel();
            }, child: const Text('Play Again')),
          ],
        ),
      ),
    );
  }

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfx.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  void _showSnack(String message, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tts.stop();
    _sfx.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final progress = ((currentIndex) / perLevelWords).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(child: Text('Pts: $points', style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white]))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress, minHeight: 10),
                  const SizedBox(height: 18),
                  // Word card
                  Hero(
                    tag: 'word-card-${widget.level}',
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Text('Unscramble', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Text(scrambled, key: ValueKey(scrambled), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4)),
                            ),
                            const SizedBox(height: 16),
                            if (!answered)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: 'Type your guess here',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onSubmitted: _onSubmitGuess,
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Text('Now pronounce: "$answer"', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _listenAndVerifyPronunciation,
                                    icon: const Icon(Icons.mic),
                                    label: const Text('Pronounce'),
                                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(recognized.isEmpty ? 'Heard: ...' : 'Heard: $recognized'),
                                ],
                              ),
                          ],
                        ),
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
                  // controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (points >= 5) {
                            // Deduct 5 points and move to next word
                            points -= 5;
                            _advanceOrComplete();
                            _showSnack('Skipped! -5 points', false);
                          } else {
                            // Show warning message
                            _showSnack('You need at least 5 points to skip.', false);
                          }
                          setState(() {}); // refresh points display
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip (-5)'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _speak(answer),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Hear Word'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          // confetti overlay
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
