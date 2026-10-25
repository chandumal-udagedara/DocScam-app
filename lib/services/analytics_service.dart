import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Analytics.
///
/// All public methods are fire-and-forget: they swallow exceptions so a
/// Firebase misconfiguration never breaks the user experience.
///
/// Usage:
///   AnalyticsService.quizStarted('Seasons');
///   AnalyticsService.quizCompleted('Seasons', score: 4, total: 5);
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  /// Call once from main() after Firebase.initializeApp() succeeds.
  static void init() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('[Analytics] init failed: $e');
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  static FirebaseAnalyticsObserver? get observer {
    if (_analytics == null) return null;
    return FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  // ── Quiz events ──────────────────────────────────────────────────────────

  static void quizStarted(String category) => _log(
        'quiz_started',
        {'category': category},
      );

  static void quizCompleted(
    String category, {
    required int score,
    required int total,
  }) =>
      _log(
        'quiz_completed',
        {
          'category': category,
          'score': score,
          'total': total,
          'accuracy': total > 0 ? (score / total * 100).round() : 0,
        },
      );

  static void questionAnswered({
    required String category,
    required int questionIndex,
    required bool correct,
  }) =>
      _log(
        'question_answered',
        {
          'category': category,
          'question_index': questionIndex,
          'correct': correct,
        },
      );

  // ── Feature events ───────────────────────────────────────────────────────

  static void categorySelected(String category) => _log(
        'category_selected',
        {'category': category},
      );

  static void certificateViewed() => _log('certificate_viewed', {});

  static void certificateShared() => _log('certificate_shared', {});

  static void reportScamOpened() => _log('report_scam_opened', {});

  static void reportBodyTapped(String bodyName) => _log(
        'report_body_tapped',
        {'body': bodyName},
      );

  // ── Screen view ──────────────────────────────────────────────────────────

  static void screenView(String screenName) => _log(
        'screen_view',
        {'screen_name': screenName},
      );

  // ── Internal ─────────────────────────────────────────────────────────────

  static void _log(String name, Map<String, Object> params) {
    if (_analytics == null) return;
    _analytics!
        .logEvent(name: name, parameters: params)
        .catchError((e) => debugPrint('[Analytics] logEvent $name failed: $e'));
  }
}
