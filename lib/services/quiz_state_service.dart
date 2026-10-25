import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../question_bank.dart';

/// Persists in-progress quiz state so it survives app kills and restarts.
///
/// Saved after every answer submission. Cleared when the quiz finishes.
class QuizStateService {
  static const String _key = 'docscam_quiz_state';

  /// Set to false in tests to prevent fire-and-forget saves from racing
  /// with test teardowns.
  @visibleForTesting
  static bool enabled = true;

  /// Save the current quiz state.
  static Future<void> save(QuizState state) async {
    if (!enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[QuizState] save failed: $e');
    }
  }

  /// Load a previously saved quiz state, or null if none exists.
  static Future<QuizState?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json == null) return null;
      return QuizState.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[QuizState] load failed: $e');
      return null;
    }
  }

  /// Clear saved state (call when quiz finishes).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[QuizState] clear failed: $e');
    }
  }
}

/// Snapshot of a quiz in progress.
@immutable
class QuizState {
  final String category;
  final List<Q> questions;
  final int currentIndex;
  final int score;
  final List<Map<String, dynamic>> reviews;

  const QuizState({
    required this.category,
    required this.questions,
    required this.currentIndex,
    required this.score,
    required this.reviews,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'currentIndex': currentIndex,
        'score': score,
        'reviews': reviews,
        'questions': questions
            .map((q) => {
                  'prompt': q.prompt,
                  'options': q.options,
                  'correctIndices': q.correctIndices,
                  if (q.explanation != null) 'explanation': q.explanation,
                  if (q.assetImage != null) 'assetImage': q.assetImage,
                  if (q.imageUrl != null) 'imageUrl': q.imageUrl,
                })
            .toList(),
      };

  factory QuizState.fromJson(Map<String, dynamic> json) {
    return QuizState(
      category: json['category'] as String,
      currentIndex: json['currentIndex'] as int,
      score: json['score'] as int,
      reviews: (json['reviews'] as List)
          .cast<Map<String, dynamic>>(),
      questions: (json['questions'] as List)
          .cast<Map<String, dynamic>>()
          .map((m) => Q(
                prompt: m['prompt'] as String,
                options: List<String>.from(m['options'] as List),
                correctIndices: List<int>.from(
                    (m['correctIndices'] as List).map((e) => (e as num).toInt())),
                explanation: m['explanation'] as String?,
                assetImage: m['assetImage'] as String?,
                imageUrl: m['imageUrl'] as String?,
              ))
          .toList(),
    );
  }
}
