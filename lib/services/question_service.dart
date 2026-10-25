import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../question_bank.dart';

/// Fetches quiz questions with a three-tier strategy:
///
///   1. **In-memory cache** — instant, survives only the current session.
///   2. **SharedPreferences disk cache** — persists across app restarts so
///      the app works fully offline after the first successful Firestore fetch.
///   3. **Firestore** — authoritative remote source.
///   4. **Local question bank** — bundled fallback if nothing else is available.
///
/// Firestore schema:
///   categories/{categoryId}/questions/{questionId}
///     prompt:         String
///     options:        `List<String>`
///     correctIndices: `List<int>`
///     explanation:    String?
///     assetImage:     String?
///     imageUrl:       String?
class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  /// Test-only constructor that accepts injected dependencies.
  @visibleForTesting
  QuestionService.forTesting({
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _firestore = firestore,
        _initialized = firestore != null,
        _prefs = prefs;

  static const String _cacheKeyPrefix = 'docscam_questions_';

  FirebaseFirestore? _firestore;
  bool _initialized = false;
  SharedPreferences? _prefs;

  // In-memory cache: category → questions.
  final Map<String, List<Q>> _cache = {};

  /// Call once after Firebase.initializeApp() succeeds.
  void init() {
    try {
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
    } catch (e) {
      debugPrint('[QuestionService] init failed: $e');
    }
  }

  /// Returns questions for [category].
  ///
  /// Resolution order:
  ///   1. In-memory cache (if populated this session)
  ///   2. Firestore (with 5 s timeout)
  ///   3. SharedPreferences disk cache (offline fallback)
  ///   4. Bundled local [questionBank]
  Future<List<Q>> getQuestions(String category) async {
    // 1. In-memory cache
    if (_cache.containsKey(category)) return _cache[category]!;

    // 2. Try Firestore
    if (_initialized && _firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('categories')
            .doc(_categoryId(category))
            .collection('questions')
            .get()
            .timeout(const Duration(seconds: 5));

        if (snapshot.docs.isNotEmpty) {
          final questions =
              snapshot.docs.map((doc) => _docToQ(doc)).toList();
          _cache[category] = questions;
          await _persistToPrefs(category, questions);
          return questions;
        }
      } catch (e) {
        debugPrint('[QuestionService] Firestore fetch failed for '
            '$category, trying disk cache: $e');
      }
    }

    // 3. Disk cache (SharedPreferences)
    final diskQuestions = await _loadFromPrefs(category);
    if (diskQuestions != null && diskQuestions.isNotEmpty) {
      _cache[category] = diskQuestions;
      return diskQuestions;
    }

    // 4. Bundled local fallback
    final local = questionBank[category] ?? [];
    _cache[category] = local;
    return local;
  }

  /// Invalidates the in-memory cache for [category].
  void invalidate(String category) => _cache.remove(category);

  /// Invalidates the entire in-memory cache.
  void invalidateAll() {
    _cache.clear();
    _prefs = null; // Force re-fetch of SharedPreferences on next access.
  }

  /// Clears both in-memory and disk cache for [category].
  Future<void> clearCache(String category) async {
    _cache.remove(category);
    final prefs = await _getPrefs();
    await prefs.remove('$_cacheKeyPrefix$category');
  }

  /// Clears all cached questions (memory + disk).
  Future<void> clearAllCaches() async {
    _cache.clear();
    final prefs = await _getPrefs();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // ── Persistence helpers ──────────────────────────────────────────────────

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Serialise questions to JSON and write to SharedPreferences.
  Future<void> _persistToPrefs(String category, List<Q> questions) async {
    try {
      final prefs = await _getPrefs();
      final json = jsonEncode(questions.map(_qToMap).toList());
      await prefs.setString('$_cacheKeyPrefix$category', json);
    } catch (e) {
      debugPrint('[QuestionService] Failed to persist cache for $category: $e');
    }
  }

  /// Load questions from SharedPreferences disk cache.
  Future<List<Q>?> _loadFromPrefs(String category) async {
    try {
      final prefs = await _getPrefs();
      final json = prefs.getString('$_cacheKeyPrefix$category');
      if (json == null) return null;
      final list = jsonDecode(json) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map((m) => _mapToQ(m))
          .toList();
    } catch (e) {
      debugPrint('[QuestionService] Failed to load cache for $category: $e');
      return null;
    }
  }

  // ── Conversion helpers ────────────────────────────────────────────────────

  /// Converts a category display name to a Firestore document ID.
  /// e.g. "Job Offers" → "job_offers"
  String _categoryId(String category) =>
      category.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and');

  Q _docToQ(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _mapToQ(doc.data());
  }

  Q _mapToQ(Map<String, dynamic> data) {
    return Q(
      prompt: data['prompt'] as String,
      options: List<String>.from(data['options'] as List),
      correctIndices: List<int>.from(
          (data['correctIndices'] as List).map((e) => (e as num).toInt())),
      explanation: data['explanation'] as String?,
      assetImage: data['assetImage'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> _qToMap(Q q) => {
        'prompt': q.prompt,
        'options': q.options,
        'correctIndices': q.correctIndices,
        if (q.explanation != null) 'explanation': q.explanation,
        if (q.assetImage != null) 'assetImage': q.assetImage,
        if (q.imageUrl != null) 'imageUrl': q.imageUrl,
      };
}
