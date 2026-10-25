import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc_scam_mobile_app/services/progress_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final service = await ProgressService.getInstance();
    await service.clearAllProgress();
  });

  group('ProgressService', () {
    test('getProgressData returns empty data when nothing stored', () async {
      final service = await ProgressService.getInstance();
      final data = await service.getProgressData();
      expect(data.hasAttempts, isFalse);
      expect(data.totalQuizzes, 0);
    });

    test('saveQuizResult persists a new attempt', () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Seasons', score: 4, total: 5);
      final data = await service.getProgressData();
      expect(data.totalQuizzes, 1);
      final stats = data.getCategoryStats('Seasons')!;
      expect(stats.attemptCount, 1);
      expect(stats.attempts.first.score, 4);
      expect(stats.attempts.first.total, 5);
    });

    test('saveQuizResult accumulates multiple attempts in the same category',
        () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Seasons', score: 3, total: 5);
      await service.saveQuizResult(category: 'Seasons', score: 5, total: 5);
      final stats = await service.getCategoryStats('Seasons');
      expect(stats!.attemptCount, 2);
      expect(stats.bestScore, 5);
    });

    test('saveQuizResult handles multiple categories independently', () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Seasons', score: 4, total: 5);
      await service.saveQuizResult(category: 'Delivery', score: 2, total: 5);
      final data = await service.getProgressData();
      expect(data.totalQuizzes, 2);
      expect(data.getCategoryStats('Seasons')!.attemptCount, 1);
      expect(data.getCategoryStats('Delivery')!.attemptCount, 1);
    });

    test('getCategoryStats returns null for a never-attempted category',
        () async {
      final service = await ProgressService.getInstance();
      final stats = await service.getCategoryStats('Job Offers');
      expect(stats, isNull);
    });

    test('getCategoryStats returns correct stats after saving', () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Delivery', score: 5, total: 5);
      final stats = await service.getCategoryStats('Delivery');
      expect(stats, isNotNull);
      expect(stats!.bestScore, 5);
    });

    test('clearAllProgress removes all data and invalidates cache', () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Seasons', score: 3, total: 5);
      await service.clearAllProgress();
      final data = await service.getProgressData();
      expect(data.hasAttempts, isFalse);
    });

    test('clearCategoryProgress removes only the specified category', () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Seasons', score: 4, total: 5);
      await service.saveQuizResult(category: 'Delivery', score: 3, total: 5);
      await service.clearCategoryProgress('Seasons');
      final data = await service.getProgressData();
      expect(data.getCategoryStats('Seasons'), isNull);
      expect(data.getCategoryStats('Delivery'), isNotNull);
      expect(data.totalQuizzes, 1);
    });

    test('getProgressData returns cached result without re-parsing', () async {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(category: 'Seasons', score: 4, total: 5);
      final first = await service.getProgressData();
      final second = await service.getProgressData();
      expect(first.totalQuizzes, second.totalQuizzes);
    });

    test('getProgressData handles corrupted JSON gracefully', () async {
      final service = await ProgressService.getInstance();
      await service.clearAllProgress();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('docscam_progress_data', 'corrupted json {{{{');
      final data = await service.getProgressData();
      expect(data.hasAttempts, isFalse);
    });
  });
}
