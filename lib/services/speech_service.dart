import 'dart:async';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Result from a pronunciation listening attempt.
class SpeechResult {
  final bool available;
  final String recognised;

  const SpeechResult({required this.available, required this.recognised});
}

/// Wraps speech-to-text initialisation, listening, and fuzzy pronunciation
/// matching in one reusable service.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Start listening for ~2.5 s.  Returns a [SpeechResult] indicating
  /// whether speech recognition is available and what text was heard.
  Future<SpeechResult> listenForPronunciation({
    required void Function(String) onPartialResult,
  }) async {
    final available = await _speech.initialize();
    if (!available) {
      return const SpeechResult(available: false, recognised: '');
    }

    String recognised = '';

    _speech.listen(onResult: (res) {
      recognised = res.recognizedWords;
      onPartialResult(recognised);
    });

    await Future.delayed(const Duration(milliseconds: 2500));
    _speech.stop();

    return SpeechResult(available: true, recognised: recognised);
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
