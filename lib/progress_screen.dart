import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/progress_model.dart';
import 'services/progress_service.dart';
import 'utils/date_formatter.dart';

/// Displays detailed progress tracking and quiz history
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<ProgressData> _progressFuture;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    _progressFuture = ProgressService.getInstance()
        .then((service) => service.getProgressData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C0038), Color(0xFF4B0F67)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// Header
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFB46BF2), Color(0xFF4B0F67)],
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
                        child: Center(
                          child: Text(
                            'Your Progress',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                /// Content
                Expanded(
                  child: FutureBuilder<ProgressData>(
                    future: _progressFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading progress',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        );
                      }

                      if (!snapshot.hasData || !snapshot.data!.hasAttempts) {
                        return _buildEmptyState();
                      }

                      final progress = snapshot.data!;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        children: [
                          /// Overall Stats Card
                          _buildOverallStatsCard(progress),
                          const SizedBox(height: 20),

                          /// Category Breakdown Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Category Breakdown',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          /// Category Cards
                          ...progress.categories.entries.map((entry) =>
                              _buildCategoryCard(context, entry.value)),

                          const SizedBox(height: 20),

                          /// Quiz History Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Quiz History',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          /// History List
                          ...progress.getAllAttempts().map((attempt) =>
                              _buildHistoryItem(attempt)),

                          const SizedBox(height: 20),

                          /// Clear Progress Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear All Progress'),
                            onPressed: () =>
                                _showClearConfirmationDialog(context),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
                /// Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Opacity(
                      opacity: 0.7,
                      child: Text(
                        '@powered  by ScamSlayers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no quizzes completed
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            color: Colors.white.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Progress Yet',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a quiz to see your progress!',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
            child: const Text('Start a Quiz'),
          ),
        ],
      ),
    );
  }

  /// Overall stats card showing total quizzes, accuracy, and last attempt
  Widget _buildOverallStatsCard(ProgressData progress) {
    final accuracy = progress.overallAccuracy;
    final accuracyColor = accuracy >= 70
        ? const Color(0xFF1B5E20)
        : accuracy >= 50
            ? const Color(0xFFFFB300)
            : const Color(0xFFB71C1C);

    final lastDate = progress.lastQuizDate;
    final lastDateText = lastDate != null
        ? DateFormatter.formatFull(lastDate)
        : 'Never';

    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Statistics',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${progress.totalQuizzes}',
                  'Quizzes\nCompleted',
                  Colors.blue,
                ),
                _buildStatItem(
                  '${accuracy.toStringAsFixed(1)}%',
                  'Overall\nAccuracy',
                  accuracyColor,
                ),
                _buildStatItem(
                  lastDateText,
                  'Last Quiz',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Category breakdown card
  Widget _buildCategoryCard(BuildContext context, CategoryStats stats) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stats.category,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${stats.attemptCount} ${stats.attemptCount == 1 ? 'attempt' : 'attempts'}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryStatColumn('Best Score', '${stats.bestScore}/5'),
                _buildCategoryStatColumn('Average', '${stats.averageScore}/5'),
                _buildCategoryStatColumn('Accuracy', '${stats.averageAccuracy.toStringAsFixed(0)}%'),
              ],
            ),
            if (stats.lastAttemptDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last: ${DateFormatter.formatFull(stats.lastAttemptDate!)}',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Category stats column
  Widget _buildCategoryStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// History item in timeline
  Widget _buildHistoryItem(QuizAttempt attempt) {
    final icon = attempt.score == attempt.total
        ? Icons.check_circle
        : attempt.score >= attempt.total * 0.6
            ? Icons.radio_button_checked
            : Icons.cancel;

    final iconColor = attempt.score == attempt.total
        ? const Color(0xFF1B5E20)
        : attempt.score >= attempt.total * 0.6
            ? const Color(0xFFFFB300)
            : const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.category,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormatter.formatFull(attempt.completedAt),
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${attempt.score}/${attempt.total}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${attempt.accuracy.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog for clearing progress
  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C0038),
        title: Text(
          'Clear All Progress?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'This action cannot be undone. All your progress data will be permanently deleted.',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) {
                Navigator.pop(context);
              }
              final service = await ProgressService.getInstance();
              await service.clearAllProgress();
              if (mounted) {
                setState(() => _loadProgress());
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All progress cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
