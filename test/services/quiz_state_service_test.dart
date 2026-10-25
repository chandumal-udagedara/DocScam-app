import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc_scam_mobile_app/services/quiz_state_service.dart';
import 'package:doc_scam_mobile_app/question_bank.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  QuizState sampleState() => QuizState(
        category: 'Seasons',
        currentIndex: 2,
        score: 1,
        reviews: [
          {
            'question': 'Is this a scam?',
            'isCorrect': true,
          },
          {
            'question': 'What should you do?',
            'isCorrect': false,
          },
        ],
        questions: const [
          Q(
            prompt: 'Question 1',
            options: ['A', 'B', 'C'],
            correctIndices: [0],
            explanation: 'A is correct.',
          ),
          Q(
            prompt: 'Question 2',
            options: ['X', 'Y'],
            correctIndices: [1],
          ),
          Q(
            prompt: 'Question 3',
            options: ['P', 'Q', 'R', 'S'],
            correctIndices: [0, 2],
            assetImage: 'assets/test.png',
          ),
        ],
      );

  group('QuizStateService', () {
    test('load returns null when nothing saved', () async {
      final result = await QuizStateService.load();
      expect(result, isNull);
    });

    test('save and load round-trip preserves all fields', () async {
      final original = sampleState();
      await QuizStateService.save(original);
      final loaded = await QuizStateService.load();

      expect(loaded, isNotNull);
      expect(loaded!.category, 'Seasons');
      expect(loaded.currentIndex, 2);
      expect(loaded.score, 1);
      expect(loaded.reviews.length, 2);
      expect(loaded.reviews[0]['isCorrect'], true);
      expect(loaded.reviews[1]['isCorrect'], false);
    });

    test('save and load preserves question data', () async {
      await QuizStateService.save(sampleState());
      final loaded = await QuizStateService.load();

      expect(loaded!.questions.length, 3);

      // First question — all fields
      expect(loaded.questions[0].prompt, 'Question 1');
      expect(loaded.questions[0].options, ['A', 'B', 'C']);
      expect(loaded.questions[0].correctIndices, [0]);
      expect(loaded.questions[0].explanation, 'A is correct.');

      // Second question — no optional fields
      expect(loaded.questions[1].prompt, 'Question 2');
      expect(loaded.questions[1].explanation, isNull);
      expect(loaded.questions[1].assetImage, isNull);

      // Third question — multi-answer with asset image
      expect(loaded.questions[2].correctIndices, [0, 2]);
      expect(loaded.questions[2].assetImage, 'assets/test.png');
    });

    test('clear removes saved state', () async {
      await QuizStateService.save(sampleState());
      await QuizStateService.clear();
      final loaded = await QuizStateService.load();
      expect(loaded, isNull);
    });

    test('save overwrites previous state', () async {
      await QuizStateService.save(sampleState());

      final updated = QuizState(
        category: 'Delivery',
        currentIndex: 0,
        score: 0,
        reviews: const [],
        questions: const [
          Q(prompt: 'New Q', options: ['A', 'B'], correctIndices: [1]),
        ],
      );
      await QuizStateService.save(updated);

      final loaded = await QuizStateService.load();
      expect(loaded!.category, 'Delivery');
      expect(loaded.questions.length, 1);
    });

    test('load handles corrupted data gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('docscam_quiz_state', 'not valid json');
      final loaded = await QuizStateService.load();
      expect(loaded, isNull);
    });
  });
}
