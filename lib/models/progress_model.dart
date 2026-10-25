import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Represents a single quiz attempt record
@immutable
class QuizAttempt {
  final String category;
  final int score;
  final int total;
  final DateTime completedAt;

  const QuizAttempt({
    required this.category,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'category': category,
    'score': score,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
  };

  /// Create from JSON
  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    try {
      return QuizAttempt(
        category: json['category'] as String,
        score: json['score'] as int,
        total: json['total'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
    } catch (e) {
      throw FormatException('Invalid QuizAttempt JSON: $e');
    }
  }

  /// Accuracy for this quiz (0-100)
  double get accuracy => (score / total * 100).roundToDouble();
}

/// Aggregated statistics for a single category
@immutable
class CategoryStats {
  final String category;
  final List<QuizAttempt> attempts;

  const CategoryStats({
    required this.category,
    required this.attempts,
  });

  /// Best score achieved in this category
  int get bestScore {
    if (attempts.isEmpty) return 0;
    int best = 0;
    for (final attempt in attempts) {
      if (attempt.score > best) best = attempt.score;
    }
    return best;
  }

  /// Average score across all attempts
  double get averageScore {
    if (attempts.isEmpty) return 0.0;
    final sum = attempts.fold<double>(0.0, (sum, a) => sum + a.score);
    return (sum / attempts.length * 10).roundToDouble() / 10; // Round to 1 decimal
  }

  /// Number of times this category was attempted
  int get attemptCount => attempts.length;

  /// Most recent quiz attempt in this category
  DateTime? get lastAttemptDate => attempts.isEmpty ? null : attempts.last.completedAt;

  /// Average accuracy percentage
  double get averageAccuracy {
    if (attempts.isEmpty) return 0.0;
    final sum = attempts.fold<double>(0.0, (sum, a) => sum + a.accuracy);
    return (sum / attempts.length * 10).roundToDouble() / 10;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'category': category,
    'attempts': attempts.map((a) => a.toJson()).toList(),
  };

  /// Create from JSON
  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    try {
      return CategoryStats(
        category: json['category'] as String,
        attempts: (json['attempts'] as List)
            .cast<Map<String, dynamic>>()
            .map((a) => QuizAttempt.fromJson(a))
            .toList(),
      );
    } catch (e) {
      throw FormatException('Invalid CategoryStats JSON: $e');
    }
  }
}

/// Overall progress data across all categories
@immutable
class ProgressData {
  final Map<String, CategoryStats> categories;

  const ProgressData({
    required this.categories,
  });

  /// Total number of quizzes completed across all categories
  int get totalQuizzes {
    return categories.values.fold<int>(0, (sum, stats) => sum + stats.attemptCount);
  }

  /// Overall accuracy percentage across all quizzes
  double get overallAccuracy {
    if (totalQuizzes == 0) return 0.0;

    int totalCorrect = 0;
    int totalQuestions = 0;

    for (final stats in categories.values) {
      for (final attempt in stats.attempts) {
        totalCorrect += attempt.score;
        totalQuestions += attempt.total;
      }
    }

    if (totalQuestions == 0) return 0.0;
    return (totalCorrect / totalQuestions * 100 * 10).roundToDouble() / 10;
  }

  /// Most recent quiz across all categories
  DateTime? get lastQuizDate {
    DateTime? latest;
    for (final stats in categories.values) {
      if (stats.lastAttemptDate != null) {
        if (latest == null || stats.lastAttemptDate!.isAfter(latest)) {
          latest = stats.lastAttemptDate;
        }
      }
    }
    return latest;
  }

  /// Get stats for a specific category, or null if not attempted
  CategoryStats? getCategoryStats(String category) => categories[category];

  /// Check if user has attempted any quizzes
  bool get hasAttempts => totalQuizzes > 0;

  /// Convert to JSON
  String toJson() {
    final data = {
      'categories': {
        for (final entry in categories.entries)
          entry.key: entry.value.toJson(),
      },
    };
    return jsonEncode(data);
  }

  /// Create from JSON
  factory ProgressData.fromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final categoriesData = data['categories'] as Map<String, dynamic>;

      final categories = <String, CategoryStats>{};
      categoriesData.forEach((key, value) {
        categories[key] = CategoryStats.fromJson(value as Map<String, dynamic>);
      });

      return ProgressData(categories: categories);
    } catch (e) {
      throw FormatException('Invalid ProgressData JSON: $e');
    }
  }

  /// Get all quiz attempts across categories, sorted by date (newest first)
  List<QuizAttempt> getAllAttempts() {
    final all = <QuizAttempt>[];
    for (final stats in categories.values) {
      all.addAll(stats.attempts);
    }
    all.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return all;
  }
}
