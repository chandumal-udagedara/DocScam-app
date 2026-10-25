import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'services/leaderboard_service.dart';

/// Displays the global anonymised leaderboard (top 15 by total score).
/// The current user's row is highlighted in amber if they appear in the list,
/// or shown as a pinned footer card if they are outside the top 15.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<_LeaderboardData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      LeaderboardService.instance.fetchTop(),
      LeaderboardService.instance.fetchMyEntry(),
    ]).then((results) => _LeaderboardData(
          top: results[0] as List<LeaderboardEntry>,
          mine: results[1] as LeaderboardEntry?,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, AppColors.headerBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: FutureBuilder<_LeaderboardData>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (snap.hasError || !snap.hasData) {
                      return _buildError();
                    }
                    final data = snap.data!;
                    if (data.top.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildList(data);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerTop, AppColors.headerBottom],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Global Leaderboard',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => setState(_load),
          ),
        ],
      ),
    );
  }

  Widget _buildList(_LeaderboardData data) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myInTop = data.top.any((e) => e.uid == myUid);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            itemCount: data.top.length,
            itemBuilder: (context, i) {
              final entry = data.top[i];
              final isMe = entry.uid == myUid;
              return _LeaderboardRow(
                rank: i + 1,
                entry: entry,
                isMe: isMe,
              );
            },
          ),
        ),

        // Pinned footer — show the user's own entry if outside top 15
        if (!myInTop && data.mine != null)
          _buildMyFooter(data.mine!),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Scores are anonymised — only your alias is shown.',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMyFooter(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningAmber, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.warningAmber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your score (outside top 15)',
                  style: GoogleFonts.inter(
                    color: AppColors.warningAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entry.displayName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalScore} pts',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off,
              color: Colors.white.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text(
            'Could not load leaderboard.\nCheck your connection.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(_load),
            child: Text(
              'Retry',
              style:
                  GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              color: Colors.white.withValues(alpha: 0.4), size: 56),
          const SizedBox(height: 16),
          Text(
            'No scores yet — be the first!',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardData {
  final List<LeaderboardEntry> top;
  final LeaderboardEntry? mine;
  const _LeaderboardData({required this.top, required this.mine});
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final medalColor = rank == 1
        ? const Color(0xFFFFD700) // gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // silver
            : rank == 3
                ? const Color(0xFFCD7F32) // bronze
                : Colors.white54;

    return Semantics(
      label: 'Rank $rank, ${entry.displayName}, ${entry.totalScore} points',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.warningAmber.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? AppColors.warningAmber.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Rank badge
            SizedBox(
              width: 36,
              child: rank <= 3
                  ? Icon(Icons.emoji_events, color: medalColor, size: 22)
                  : Text(
                      '#$rank',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),

            // Name + best category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.displayName}${isMe ? ' (You)' : ''}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight:
                          isMe ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Best: ${entry.bestCategory} · ${entry.accuracyLabel}',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Score + quiz count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalScore} pts',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${entry.quizCount} quiz${entry.quizCount == 1 ? '' : 'zes'}',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
