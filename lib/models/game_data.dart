import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class GameData {
  static Map<int, List<String>>? _cache;

  /// Load word lists from the JSON asset. Results are cached after first load.
  static Future<Map<int, List<String>>> loadWords() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString('assets/data/words.json');
    final Map<String, dynamic> raw = json.decode(jsonString);

    _cache = raw.map((key, value) =>
        MapEntry(int.parse(key), List<String>.from(value)));
    return _cache!;
  }

  /// Return the word list for a given [level], shuffled.
  static Future<List<String>> wordsForLevel(int level) async {
    final all = await loadWords();
    final list = List<String>.from(all[level] ?? ['test']);
    list.shuffle(Random());
    return list;
  }

  /// Scramble a word. Guarantees the scrambled result differs from the original
  /// (unless the word is a single character, in which case it's returned as-is).
  static String scramble(String word) {
    if (word.length <= 1) return word;

    final chars = word.split('')..shuffle(Random());
    final joined = chars.join();

    // Re-scramble if the result is identical to the original.
    if (joined == word) return scramble(word);
    return joined;
  }
}
