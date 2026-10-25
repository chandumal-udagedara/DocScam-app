import 'package:flutter_test/flutter_test.dart';
import 'package:doc_scam_mobile_app/question_bank.dart';

void main() {
  group('Q model', () {
    test('required fields are stored correctly', () {
      const q = Q(
        prompt: 'Is this a scam?',
        options: ['Yes', 'No'],
        correctIndices: [0],
      );
      expect(q.prompt, 'Is this a scam?');
      expect(q.options, ['Yes', 'No']);
      expect(q.correctIndices, [0]);
    });

    test('optional fields default to null', () {
      const q = Q(
        prompt: 'Test?',
        options: ['A', 'B'],
        correctIndices: [1],
      );
      expect(q.explanation, isNull);
      expect(q.assetImage, isNull);
      expect(q.imageUrl, isNull);
    });

    test('optional fields are stored when provided', () {
      const q = Q(
        prompt: 'Test?',
        options: ['A', 'B'],
        correctIndices: [0],
        explanation: 'Because A.',
        assetImage: 'assets/img.png',
      );
      expect(q.explanation, 'Because A.');
      expect(q.assetImage, 'assets/img.png');
    });
  });

  group('questionBank integrity', () {
    test('contains expected categories', () {
      expect(questionBank.keys, containsAll(['Seasons', 'Delivery', 'Job Offers']));
    });

    test('each category has at least one question', () {
      for (final entry in questionBank.entries) {
        expect(entry.value, isNotEmpty,
            reason: 'Category "${entry.key}" has no questions');
      }
    });

    group('per-question rules', () {
      for (final entry in questionBank.entries) {
        final category = entry.key;
        final questions = entry.value;

        for (var i = 0; i < questions.length; i++) {
          final q = questions[i];
          final label = '$category[${i + 1}]: "${q.prompt.substring(0, q.prompt.length.clamp(0, 40))}"';

          test('$label — has at least 2 options', () {
            expect(q.options.length, greaterThanOrEqualTo(2));
          });

          test('$label — has at least 1 correct answer', () {
            expect(q.correctIndices, isNotEmpty);
          });

          test('$label — correctIndices are valid option indices', () {
            for (final idx in q.correctIndices) {
              expect(idx, greaterThanOrEqualTo(0),
                  reason: 'Index $idx is negative');
              expect(idx, lessThan(q.options.length),
                  reason: 'Index $idx out of range (${q.options.length} options)');
            }
          });

          test('$label — no duplicate correctIndices', () {
            final unique = q.correctIndices.toSet();
            expect(unique.length, q.correctIndices.length,
                reason: 'Duplicate correct indices found');
          });

          test('$label — prompt is not empty', () {
            expect(q.prompt.trim(), isNotEmpty);
          });

          test('$label — options are all non-empty strings', () {
            for (final opt in q.options) {
              expect(opt.trim(), isNotEmpty, reason: 'An option is blank');
            }
          });
        }
      }
    });
  });
}
