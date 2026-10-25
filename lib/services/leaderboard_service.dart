import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Manages anonymous leaderboard data in Firestore.
///
/// Firestore path: `leaderboard/{uid}`
/// Fields:
///   - displayName  : String  — anonymised alias e.g. "Scam Stopper #4821"
///   - totalScore   : int     — cumulative correct answers across all quizzes
///   - quizCount    : int     — total number of quizzes completed
///   - bestCategory : String  — category with the highest single-quiz score %
///   - updatedAt    : Timestamp
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _collection = 'leaderboard';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Call after every quiz completion to update the leaderboard entry.
  Future<void> submitScore({
    required String category,
    required int score,
    required int total,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final ref = _db.collection(_collection).doc(uid);
      final snap = await ref.get();

      if (!snap.exists) {
        // First submission — create a fresh entry with an anonymous alias.
        await ref.set({
          'displayName': _generateAlias(),
          'totalScore': score,
          'quizCount': 1,
          'bestCategory': category,
          'bestAccuracy': total > 0 ? score / total : 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snap.data()!;
        final prevTotal = (data['totalScore'] as int? ?? 0);
        final prevCount = (data['quizCount'] as int? ?? 0);
        final prevBestAcc = (data['bestAccuracy'] as num? ?? 0).toDouble();
        final thisAcc = total > 0 ? score / total : 0.0;

        await ref.update({
          'totalScore': prevTotal + score,
          'quizCount': prevCount + 1,
          if (thisAcc >= prevBestAcc) 'bestCategory': category,
          if (thisAcc >= prevBestAcc) 'bestAccuracy': thisAcc,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[LeaderboardService] submitScore failed: $e');
    }
  }

  /// Returns up to [limit] top entries ordered by totalScore descending.
  Future<List<LeaderboardEntry>> fetchTop({int limit = 15}) async {
    try {
      final snap = await _db
          .collection(_collection)
          .orderBy('totalScore', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        return LeaderboardEntry(
          uid: doc.id,
          displayName: d['displayName'] as String? ?? 'Anonymous',
          totalScore: d['totalScore'] as int? ?? 0,
          quizCount: d['quizCount'] as int? ?? 0,
          bestCategory: d['bestCategory'] as String? ?? '—',
          bestAccuracy: (d['bestAccuracy'] as num? ?? 0).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[LeaderboardService] fetchTop failed: $e');
      return [];
    }
  }

  /// Returns the current user's entry, or null if not on the board yet.
  Future<LeaderboardEntry?> fetchMyEntry() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final snap = await _db.collection(_collection).doc(uid).get();
      if (!snap.exists) return null;
      final d = snap.data()!;
      return LeaderboardEntry(
        uid: uid,
        displayName: d['displayName'] as String? ?? 'You',
        totalScore: d['totalScore'] as int? ?? 0,
        quizCount: d['quizCount'] as int? ?? 0,
        bestCategory: d['bestCategory'] as String? ?? '—',
        bestAccuracy: (d['bestAccuracy'] as num? ?? 0).toDouble(),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _adjectives = [
    'Savvy', 'Sharp', 'Alert', 'Bold', 'Keen', 'Quick', 'Wise',
    'Brave', 'Smart', 'Cool',
  ];
  static const _nouns = [
    'Defender', 'Guardian', 'Watcher', 'Stopper', 'Hunter',
    'Shield', 'Ranger', 'Sentinel', 'Agent', 'Hawk',
  ];

  String _generateAlias() {
    final rng = Random();
    final adj = _adjectives[rng.nextInt(_adjectives.length)];
    final noun = _nouns[rng.nextInt(_nouns.length)];
    final num = 1000 + rng.nextInt(9000);
    return '$adj $noun #$num';
  }
}

/// Immutable snapshot of a leaderboard entry.
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int totalScore;
  final int quizCount;
  final String bestCategory;
  final double bestAccuracy;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.totalScore,
    required this.quizCount,
    required this.bestCategory,
    required this.bestAccuracy,
  });

  String get accuracyLabel => '${(bestAccuracy * 100).round()}%';
}
