// Replaces test/question_bank_test.dart.
//
// The old test asserted against the hardcoded `questionBank` map. Content now
// lives in JSON, so these load the real packs and assert the same integrity
// properties plus a few the old test could not check.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doc_scam_mobile_app/content/content_loader.dart';

/// Reads packs from disk rather than rootBundle so the test runs without a
/// Flutter engine binding.
ContentPack _loadFromDisk(String file) => ContentPack.fromJson(
    jsonDecode(File('assets/content/$file').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  late Map<String, ContentPack> packs;

  setUpAll(() {
    final index = jsonDecode(
        File('assets/content/index.json').readAsStringSync()) as Map<String, dynamic>;
    packs = {
      for (final p in index['packs'] as List)
        p['title'] as String: _loadFromDisk(p['file'] as String)
    };
  });

  test('all three categories are present', () {
    expect(packs.keys, containsAll(['Seasons', 'Delivery', 'Job Offers']));
  });

  test('every pack has questions', () {
    for (final e in packs.entries) {
      expect(e.value.questions, isNotEmpty, reason: '${e.key} is empty');
    }
  });

  test('every question has at least two options and a valid answer', () {
    for (final pack in packs.values) {
      for (final q in pack.questions) {
        expect(q.options.length, greaterThanOrEqualTo(2),
            reason: '${q.id} has too few options');
        expect(q.correctIndices, isNotEmpty,
            reason: '${q.id} has no correct answer');
        for (final i in q.correctIndices) {
          expect(i, lessThan(q.options.length),
              reason: '${q.id} correct index $i is out of range');
        }
      }
    }
  });

  test('question ids are unique across all packs', () {
    final seen = <String>{};
    for (final pack in packs.values) {
      for (final q in pack.questions) {
        expect(seen.add(q.id), isTrue, reason: 'duplicate id ${q.id}');
      }
    }
  });

  test('every referenced image exists on disk', () {
    for (final pack in packs.values) {
      for (final q in pack.questions) {
        final path = q.assetImage;
        if (path == null) continue;
        expect(File(path).existsSync(), isTrue,
            reason: '${q.id} references missing asset $path');
      }
    }
  });

  test('a pack declaring an unsupported schema major is rejected', () {
    expect(
      () => ContentPack.fromJson({
        'schema_version': '99.0.0',
        'content_version': 'x',
        'pack_id': 'x',
        'title': 'X',
        'questions': <dynamic>[],
      }),
      throwsA(isA<ContentFormatException>()),
    );
  });
}
