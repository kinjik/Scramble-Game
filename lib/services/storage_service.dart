import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for game progress persistence.
class StorageService {
  static const _keyUnlockedLevel = 'unlockedLevel';
  static const _keyHighScore = 'highScore';

  Future<int> getUnlockedLevel() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_keyUnlockedLevel) ?? 1;
  }

  Future<int> getHighScore() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_keyHighScore) ?? 0;
  }

  /// Unlock the next level if [completedLevel] equals the current frontier.
  Future<void> tryUnlockNext(int completedLevel) async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getInt(_keyUnlockedLevel) ?? 1;
    if (completedLevel >= current && current < 5) {
      await sp.setInt(_keyUnlockedLevel, current + 1);
    }
  }

  /// Persist [score] if it exceeds the stored high score.
  Future<void> tryUpdateHighScore(int score) async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getInt(_keyHighScore) ?? 0;
    if (score > current) {
      await sp.setInt(_keyHighScore, score);
    }
  }
}
