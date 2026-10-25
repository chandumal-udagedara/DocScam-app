import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc_scam_mobile_app/services/question_service.dart';
import 'package:doc_scam_mobile_app/question_bank.dart';

void main() {
  const cacheKey = 'docscam_questions_Seasons';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Local fallback (no Firestore)
  // ---------------------------------------------------------------------------

  group('local fallback (no Firestore)', () {
    test('returns bundled questionBank when Firestore not initialised',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      final questions = await service.getQuestions('Seasons');

      expect(questions, isNotEmpty);
      expect(questions.length, questionBank['Seasons']!.length);
      expect(questions.first.prompt, questionBank['Seasons']!.first.prompt);
    });

    test('returns empty list for unknown category', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      final questions = await service.getQuestions('Nonexistent');

      expect(questions, isEmpty);
    });

    test('second call returns in-memory cached result', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      final first = await service.getQuestions('Seasons');
      final second = await service.getQuestions('Seasons');

      expect(identical(first, second), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Disk cache (SharedPreferences)
  // ---------------------------------------------------------------------------

  group('disk cache', () {
    test('loads from disk cache when available', () async {
      // Pre-populate SharedPreferences with cached questions.
      final cachedData = [
        {
          'prompt': 'Cached question?',
          'options': ['A', 'B'],
          'correctIndices': [0],
          'explanation': 'Cached explanation.',
        },
      ];
      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode(cachedData),
      });

      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      final questions = await service.getQuestions('Seasons');

      expect(questions.length, 1);
      expect(questions.first.prompt, 'Cached question?');
      expect(questions.first.options, ['A', 'B']);
      expect(questions.first.correctIndices, [0]);
      expect(questions.first.explanation, 'Cached explanation.');
    });

    test('falls back to local bank when disk cache is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        cacheKey: 'not valid json {{{{',
      });

      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      final questions = await service.getQuestions('Seasons');

      // Should fall through to bundled local bank
      expect(questions.length, questionBank['Seasons']!.length);
    });

    test('clearCache removes both memory and disk cache', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      // Load to populate memory cache
      await service.getQuestions('Seasons');
      // Manually set a disk cache entry
      await prefs.setString(cacheKey, jsonEncode([]));

      await service.clearCache('Seasons');

      expect(prefs.getString(cacheKey), isNull);

      // Next fetch should return local bank (not empty)
      final questions = await service.getQuestions('Seasons');
      expect(questions, isNotEmpty);
    });

    test('clearAllCaches removes all cached categories', () async {
      SharedPreferences.setMockInitialValues({
        'docscam_questions_Seasons': jsonEncode([]),
        'docscam_questions_Delivery': jsonEncode([]),
        'unrelated_key': 'should stay',
      });

      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      await service.clearAllCaches();

      expect(prefs.getString('docscam_questions_Seasons'), isNull);
      expect(prefs.getString('docscam_questions_Delivery'), isNull);
      expect(prefs.getString('unrelated_key'), 'should stay');
    });
  });

  // ---------------------------------------------------------------------------
  // Disk cache round-trip (serialise → deserialise)
  // ---------------------------------------------------------------------------

  group('serialisation round-trip', () {
    test('Q fields survive JSON round-trip through disk cache', () async {
      final original = [
        {
          'prompt': 'Is this legit?',
          'options': ['Yes', 'No', 'Maybe'],
          'correctIndices': [1],
          'explanation': 'Definitely not.',
          'assetImage': 'assets/test.png',
        },
        {
          'prompt': 'Multi-answer question',
          'options': ['A', 'B', 'C', 'D'],
          'correctIndices': [0, 2],
        },
      ];
      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode(original),
      });

      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      final questions = await service.getQuestions('Seasons');

      expect(questions.length, 2);

      // First question — all fields
      expect(questions[0].prompt, 'Is this legit?');
      expect(questions[0].options, ['Yes', 'No', 'Maybe']);
      expect(questions[0].correctIndices, [1]);
      expect(questions[0].explanation, 'Definitely not.');
      expect(questions[0].assetImage, 'assets/test.png');
      expect(questions[0].imageUrl, isNull);

      // Second question — optional fields omitted
      expect(questions[1].correctIndices, [0, 2]);
      expect(questions[1].explanation, isNull);
      expect(questions[1].assetImage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // invalidate()
  // ---------------------------------------------------------------------------

  group('invalidate()', () {
    test('invalidate causes next call to re-resolve (not use memory cache)',
        () async {
      // Pre-populate disk cache with a different question set.
      final cachedData = [
        {
          'prompt': 'Disk cached Q',
          'options': ['X', 'Y'],
          'correctIndices': [0],
        },
      ];
      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode(cachedData),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      // First call loads from disk cache.
      final first = await service.getQuestions('Seasons');
      expect(first.length, 1);
      expect(first.first.prompt, 'Disk cached Q');

      // Invalidate memory cache — disk cache still there.
      service.invalidate('Seasons');

      // Second call should re-resolve (hits disk cache again, new list instance).
      final second = await service.getQuestions('Seasons');
      expect(second.length, 1);
      expect(second.first.prompt, 'Disk cached Q');
      // Not the same object reference since it was re-resolved.
      expect(identical(first, second), isFalse);
    });

    test('invalidateAll clears all in-memory caches', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = QuestionService.forTesting(prefs: prefs);

      // Load two categories into memory cache.
      await service.getQuestions('Seasons');
      await service.getQuestions('Delivery');

      service.invalidateAll();

      // After invalidation, fetching again should work without errors.
      final seasons = await service.getQuestions('Seasons');
      final delivery = await service.getQuestions('Delivery');
      expect(seasons, isNotEmpty);
      expect(delivery, isNotEmpty);
    });
  });
}
