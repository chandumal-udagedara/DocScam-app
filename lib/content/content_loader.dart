import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads versioned JSON content packs from assets at runtime.
///
/// Replaces the hardcoded `questionBank` map in question_bank.dart.
/// Adding a category is now: drop a pack JSON in assets/content/,
/// add it to index.json, add its images. No Dart changes, no rebuild
/// of application logic.

/// Schema major version this build implements. A pack declaring a
/// different major version is rejected rather than partially parsed —
/// failing loudly beats rendering a half-understood question.
const int kSupportedSchemaMajor = 1;

@immutable
class Question {
  final String id;
  final String prompt;
  final List<String> options;
  final List<int> correctIndices;
  final String? explanation;
  final String? assetImage;

  /// Kept for drop-in compatibility with the old `Q` class. No migrated
  /// question uses it (all 147 use local assets), but quiz_screen reads it.
  final String? imageUrl;

  /// Rule ids from the checker's scam-patterns pack that this question
  /// teaches. Empty for migrated content; populate to wire up the
  /// practice loop.
  final List<String> redFlagRules;

  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndices,
    this.explanation,
    this.assetImage,
    this.imageUrl,
    this.redFlagRules = const [],
  });

  bool get isMultiSelect => correctIndices.length > 1;

  factory Question.fromJson(Map<String, dynamic> j) {
    final options = (j['options'] as List).cast<String>();
    final correct = (j['correct_indices'] as List).cast<int>();

    // Defensive: a pack that passed CI can still be corrupted on device.
    for (final i in correct) {
      if (i < 0 || i >= options.length) {
        throw ContentFormatException(
          'Question ${j['id']}: correct_indices $i out of range '
          '(${options.length} options)',
        );
      }
    }

    return Question(
      id: j['id'] as String,
      prompt: j['prompt'] as String,
      options: options,
      correctIndices: correct,
      explanation: j['explanation'] as String?,
      assetImage: j['asset_image'] as String?,
      imageUrl: j['image_url'] as String?,
      redFlagRules:
          ((j['red_flag_rules'] ?? const []) as List).cast<String>(),
    );
  }
}

@immutable
class ContentPack {
  final String packId;
  final String title;
  final String contentVersion;
  final List<Question> questions;

  const ContentPack({
    required this.packId,
    required this.title,
    required this.contentVersion,
    required this.questions,
  });

  factory ContentPack.fromJson(Map<String, dynamic> j) {
    final schemaVersion = j['schema_version'] as String? ?? '0.0.0';
    final major = int.tryParse(schemaVersion.split('.').first) ?? 0;
    if (major != kSupportedSchemaMajor) {
      throw ContentFormatException(
        'Pack ${j['pack_id']} declares schema_version $schemaVersion; '
        'this build supports $kSupportedSchemaMajor.x.x',
      );
    }
    return ContentPack(
      packId: j['pack_id'] as String,
      title: j['title'] as String,
      contentVersion: j['content_version'] as String? ?? 'unknown',
      questions: (j['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class ContentFormatException implements Exception {
  final String message;
  const ContentFormatException(this.message);
  @override
  String toString() => 'ContentFormatException: $message';
}

class ContentRepository {
  static const String _indexPath = 'assets/content/index.json';

  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  final Map<String, ContentPack> _cache = {};
  List<({String packId, String title, String file, int questionCount})>?
      _index;

  /// Packs available to show on the home screen. Reads index.json only —
  /// question bodies are loaded lazily when a pack is opened, so startup
  /// cost does not grow with the content library.
  Future<List<({String packId, String title, String file, int questionCount})>>
      listPacks() async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString(_indexPath);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    _index = (j['packs'] as List)
        .map((p) => (
              packId: p['pack_id'] as String,
              title: p['title'] as String,
              file: p['file'] as String,
              questionCount: p['question_count'] as int,
            ))
        .toList(growable: false);
    return _index!;
  }

  /// Load one pack, cached after first read.
  Future<ContentPack> loadPack(String packId) async {
    final cached = _cache[packId];
    if (cached != null) return cached;

    final index = await listPacks();
    final entry = index.where((e) => e.packId == packId).firstOrNull;
    if (entry == null) {
      throw ContentFormatException('No pack with id "$packId" in index.json');
    }

    final raw = await rootBundle.loadString('assets/content/${entry.file}');
    final pack =
        ContentPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    if (pack.questions.length != entry.questionCount) {
      debugPrint(
        'Content warning: ${pack.packId} index says ${entry.questionCount} '
        'questions, pack contains ${pack.questions.length}',
      );
    }

    _cache[packId] = pack;
    return pack;
  }

  /// Look up a pack by its display title ("Seasons", "Job Offers").
  ///
  /// home_screen.dart passes the human-readable category name, exactly as
  /// it did to the old `questionBank` map. This keeps that call site
  /// unchanged so the migration touches one screen instead of two.
  Future<ContentPack> loadPackByTitle(String title) async {
    final index = await listPacks();
    final entry = index
        .where((e) => e.title.toLowerCase() == title.toLowerCase())
        .firstOrNull;
    if (entry == null) {
      throw ContentFormatException(
        'No pack titled "$title". Available: '
        '${index.map((e) => e.title).join(', ')}',
      );
    }
    return loadPack(entry.packId);
  }

  @visibleForTesting
  void clearCache() {
    _cache.clear();
    _index = null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
