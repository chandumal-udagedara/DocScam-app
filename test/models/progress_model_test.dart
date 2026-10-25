import 'package:flutter_test/flutter_test.dart';
import 'package:doc_scam_mobile_app/models/progress_model.dart';

void main() {
  final t0 = DateTime(2024, 1, 1, 10);
  final t1 = DateTime(2024, 1, 2, 12);
  final t2 = DateTime(2024, 1, 3, 9);

  QuizAttempt attempt({
    String category = 'Seasons',
    int score = 4,
    int total = 5,
    DateTime? at,
  }) =>
      QuizAttempt(
        category: category,
        score: score,
        total: total,
        completedAt: at ?? t0,
      );

  // ---------------------------------------------------------------------------
  // QuizAttempt
  // ---------------------------------------------------------------------------

  group('QuizAttempt', () {
    test('accuracy is score/total * 100 rounded', () {
      expect(attempt(score: 4, total: 5).accuracy, 80.0);
      expect(attempt(score: 3, total: 5).accuracy, 60.0);
      expect(attempt(score: 5, total: 5).accuracy, 100.0);
      expect(attempt(score: 0, total: 5).accuracy, 0.0);
    });

    test('toJson / fromJson round-trip', () {
      final a = attempt(score: 3, total: 5, at: t0);
      final roundTripped = QuizAttempt.fromJson(a.toJson());
      expect(roundTripped.category, a.category);
      expect(roundTripped.score, a.score);
      expect(roundTripped.total, a.total);
      expect(roundTripped.completedAt, a.completedAt);
    });

    test('fromJson throws FormatException on missing field', () {
      expect(
        () => QuizAttempt.fromJson({'category': 'Seasons', 'score': 4}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // CategoryStats
  // ---------------------------------------------------------------------------

  group('CategoryStats', () {
    CategoryStats stats(List<QuizAttempt> attempts) =>
        CategoryStats(category: 'Seasons', attempts: attempts);

    test('empty attempts return zero/null defaults', () {
      final s = stats([]);
      expect(s.bestScore, 0);
      expect(s.averageScore, 0.0);
      expect(s.attemptCount, 0);
      expect(s.averageAccuracy, 0.0);
      expect(s.lastAttemptDate, isNull);
    });

    test('bestScore returns max score', () {
      final s = stats([
        attempt(score: 2, total: 5),
        attempt(score: 5, total: 5),
        attempt(score: 3, total: 5),
      ]);
      expect(s.bestScore, 5);
    });

    test('averageScore computes mean', () {
      final s = stats([
        attempt(score: 2, total: 5),
        attempt(score: 4, total: 5),
      ]);
      expect(s.averageScore, 3.0);
    });

    test('attemptCount returns list length', () {
      expect(stats([attempt(), attempt()]).attemptCount, 2);
    });

    test('lastAttemptDate returns the last attempt completedAt', () {
      final s = stats([attempt(at: t0), attempt(at: t1)]);
      expect(s.lastAttemptDate, t1);
    });

    test('averageAccuracy is mean of individual accuracies', () {
      // 4/5 = 80%, 2/5 = 40% → average = 60%
      final s = stats([
        attempt(score: 4, total: 5),
        attempt(score: 2, total: 5),
      ]);
      expect(s.averageAccuracy, 60.0);
    });

    test('toJson / fromJson round-trip', () {
      final s = stats([attempt(score: 3, total: 5, at: t0)]);
      final rt = CategoryStats.fromJson(s.toJson());
      expect(rt.category, s.category);
      expect(rt.attemptCount, 1);
      expect(rt.attempts.first.score, 3);
    });

    test('fromJson throws FormatException on bad data', () {
      expect(
        () => CategoryStats.fromJson({'category': 'X', 'attempts': 'bad'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ProgressData
  // ---------------------------------------------------------------------------

  group('ProgressData', () {
    ProgressData empty() => const ProgressData(categories: {});

    ProgressData withAttempts() {
      final seasons = CategoryStats(category: 'Seasons', attempts: [
        attempt(category: 'Seasons', score: 4, total: 5, at: t0),
        attempt(category: 'Seasons', score: 2, total: 5, at: t1),
      ]);
      final delivery = CategoryStats(category: 'Delivery', attempts: [
        attempt(category: 'Delivery', score: 5, total: 5, at: t2),
      ]);
      return ProgressData(
          categories: {'Seasons': seasons, 'Delivery': delivery});
    }

    test('empty ProgressData has no attempts', () {
      final d = empty();
      expect(d.totalQuizzes, 0);
      expect(d.overallAccuracy, 0.0);
      expect(d.lastQuizDate, isNull);
      expect(d.hasAttempts, isFalse);
    });

    test('totalQuizzes sums across categories', () {
      expect(withAttempts().totalQuizzes, 3);
    });

    test('hasAttempts is true when data exists', () {
      expect(withAttempts().hasAttempts, isTrue);
    });

    test('overallAccuracy computes weighted correctness', () {
      // Seasons: 4+2=6 correct out of 10; Delivery: 5 out of 5 → 11/15 ≈ 73.3%
      final acc = withAttempts().overallAccuracy;
      expect(acc, closeTo(73.3, 0.1));
    });

    test('lastQuizDate returns the most recent across all categories', () {
      expect(withAttempts().lastQuizDate, t2);
    });

    test('getCategoryStats returns null for unknown category', () {
      expect(withAttempts().getCategoryStats('Jobs'), isNull);
    });

    test('getCategoryStats returns stats for known category', () {
      final s = withAttempts().getCategoryStats('Delivery');
      expect(s, isNotNull);
      expect(s!.attemptCount, 1);
    });

    test('getAllAttempts returns all attempts sorted newest first', () {
      final all = withAttempts().getAllAttempts();
      expect(all.length, 3);
      expect(all[0].completedAt, t2);
      expect(all[1].completedAt, t1);
      expect(all[2].completedAt, t0);
    });

    test('toJson / fromJson round-trip', () {
      final d = withAttempts();
      final rt = ProgressData.fromJson(d.toJson());
      expect(rt.totalQuizzes, d.totalQuizzes);
      expect(rt.categories.keys.toSet(), d.categories.keys.toSet());
    });

    test('fromJson throws FormatException on invalid JSON string', () {
      expect(
        () => ProgressData.fromJson('not-json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on missing categories key', () {
      expect(
        () => ProgressData.fromJson('{"wrong": {}}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
