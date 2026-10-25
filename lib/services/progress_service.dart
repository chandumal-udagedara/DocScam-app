import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';

/// Service to manage quiz progress tracking and persistence
/// Uses SharedPreferences to store data locally
class ProgressService {
  static const String _storageKey = 'docscam_progress_data';

  static ProgressService? _instance;
  late final SharedPreferences _prefs;
  bool _initialized = false;
  ProgressData? _cachedData;

  ProgressService._private();

  /// Get singleton instance of ProgressService
  static Future<ProgressService> getInstance() async {
    _instance ??= ProgressService._private();
    if (!_instance!._initialized) {
      _instance!._prefs = await SharedPreferences.getInstance();
      _instance!._initialized = true;
    }
    return _instance!;
  }

  /// Save a quiz result to local storage
  /// Called immediately after user completes a quiz
  Future<void> saveQuizResult({
    required String category,
    required int score,
    required int total,
  }) async {
    try {
      // Load existing progress
      final data = await getProgressData();

      // Create new attempt record
      final newAttempt = QuizAttempt(
        category: category,
        score: score,
        total: total,
        completedAt: DateTime.now(),
      );

      // Get or create category stats (using immutable list pattern)
      final existingStats = data.categories[category];
      final attempts = <QuizAttempt>[...(existingStats?.attempts ?? []), newAttempt];

      final updatedStats = CategoryStats(
        category: category,
        attempts: attempts,
      );

      // Update categories map
      final updatedCategories = {...data.categories};
      updatedCategories[category] = updatedStats;

      // Create new ProgressData and save
      final updatedData = ProgressData(categories: updatedCategories);
      await _prefs.setString(_storageKey, updatedData.toJson());

      // Invalidate cache
      _cachedData = updatedData;
    } catch (e) {
      // Silently fail but could log to analytics
      // User will still see results, just progress won't be saved
      rethrow;
    }
  }

  /// Retrieve all progress data
  /// Returns empty ProgressData if no data exists yet
  /// Results are cached to avoid unnecessary JSON parsing
  Future<ProgressData> getProgressData() async {
    // Return cached data if available
    if (_cachedData != null) {
      return _cachedData!;
    }

    final jsonString = _prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      _cachedData = ProgressData(categories: {});
      return _cachedData!;
    }

    try {
      _cachedData = ProgressData.fromJson(jsonString);
      return _cachedData!;
    } catch (e) {
      // If JSON is corrupted, return empty data
      _cachedData = ProgressData(categories: {});
      return _cachedData!;
    }
  }

  /// Get statistics for a specific category
  Future<CategoryStats?> getCategoryStats(String category) async {
    final data = await getProgressData();
    return data.getCategoryStats(category);
  }

  /// Clear all progress data
  /// Called when user taps "Clear Progress" and confirms
  Future<void> clearAllProgress() async {
    await _prefs.remove(_storageKey);
    _cachedData = null; // Invalidate cache
  }

  /// Delete progress for specific category
  Future<void> clearCategoryProgress(String category) async {
    final data = await getProgressData();
    final updatedCategories = {...data.categories};
    updatedCategories.remove(category);

    final updatedData = ProgressData(categories: updatedCategories);
    await _prefs.setString(_storageKey, updatedData.toJson());
    _cachedData = updatedData; // Update cache
  }
}
