import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Centralised audio helper — wraps TTS and sound-effect playback.
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfx = AudioPlayer();

  /// Speak [text] aloud at a slow, learner-friendly rate.
  Future<void> speak(String text) async {
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  /// Play a short sound effect from [assetPath] (relative to `assets/`).
  Future<void> playSfx(String assetPath) async {
    try {
      await _sfx.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (_) {}
  }

  /// Play the "correct answer" chime.
  Future<void> playSuccess() => playSfx('assets/sounds/success.mp3');

  /// Play the "wrong answer" buzz.
  Future<void> playFail() => playSfx('assets/sounds/fail.mp3');

  void dispose() {
    _tts.stop();
    _sfx.dispose();
  }
}
