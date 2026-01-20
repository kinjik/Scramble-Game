import 'dart:math';

class WordScrambler {
  final Map<int, List<String>> wordsByDifficulty = {
    1: ['cat', 'dog', 'sun', 'pen', 'cup'],
    2: ['apple', 'chair', 'house', 'table', 'plant'],
    3: ['bottle', 'school', 'garden', 'window', 'market'],
    4: ['elephant', 'mountain', 'computer', 'language', 'chocolate'],
    5: ['microphone', 'television', 'imagination', 'development', 'perfection'],
  };

  String getRandomWordByDifficulty(int difficulty) {
    final list = wordsByDifficulty[difficulty]!;
    list.shuffle();
    return list.first;
  }

  String scrambleWord(String word) {
    final letters = word.split('')..shuffle();
    return letters.join();
  }
}

