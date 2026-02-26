import 'dart:async';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps speech-to-text initialisation, listening, and fuzzy pronunciation
/// matching in one reusable service.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Start listening for ~2.5 s.  Returns the recognised text (may be empty).
  Future<String> listenForPronunciation({
    required void Function(String) onPartialResult,
  }) async {
    final available = await _speech.initialize();
    if (!available) return '';

    String recognised = '';

    _speech.listen(onResult: (res) {
      recognised = res.recognizedWords;
      onPartialResult(recognised);
    });

    await Future.delayed(const Duration(milliseconds: 2500));
    _speech.stop();

    return recognised;
  }

  /// Compare [recognised] text against [expected] word.
  /// Returns `true` when the fuzzy similarity score exceeds the threshold.
  bool isPronunciationCorrect(String recognised, String expected,
      {int threshold = 75}) {
    if (recognised.isEmpty) return false;
    final sim = ratio(recognised.toLowerCase(), expected.toLowerCase());
    return sim > threshold;
  }
}
