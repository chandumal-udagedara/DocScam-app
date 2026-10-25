import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
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
                colors: [AppColors.bgDark, AppColors.headerBottom],
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

                          /// Score Trend Chart (only shown once there are 2+ attempts)
                          if (progress.totalQuizzes >= 2) ...[
                            _buildTrendChart(progress),
                            const SizedBox(height: 20),
                          ],

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
                              backgroundColor: AppColors.incorrectRed,
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
              backgroundColor: AppColors.ctaRed,
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
        ? AppColors.correctGreen
        : accuracy >= 50
            ? AppColors.warningAmber
            : AppColors.incorrectRed;

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

  /// Score trend bar chart — shows the last 8 quiz attempts oldest-to-newest.
  /// Each bar represents one attempt; height is proportional to score percentage.
  /// Coloured by category so the user can see which area they are improving in.
  Widget _buildTrendChart(ProgressData progress) {
    // getAllAttempts() returns newest-first; reverse to get oldest-first.
    final allAttempts = progress.getAllAttempts().reversed.toList();
    final recent =
        allAttempts.length > 8 ? allAttempts.sublist(allAttempts.length - 8) : allAttempts;

    const double maxBarH = 72.0;
    const Map<String, Color> catColors = {
      'Seasons':              Color(0xFF4FC3F7), // light blue
      'Delivery':             Color(0xFFFFB74D), // orange
      'Job Offers':           Color(0xFF81C784), // light green
      'Investment & Crypto':  Color(0xFFFFD54F), // amber
      'Romance Scams':        Color(0xFFF48FB1), // pink
      'Tech Support':         Color(0xFF80CBC4), // teal
    };

    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Trend',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Chart bars
            SizedBox(
              height: maxBarH + 28, // bars + score label above + category initial below
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: recent.map((attempt) {
                  final frac =
                      attempt.total > 0 ? attempt.score / attempt.total : 0.0;
                  final barH = (frac * maxBarH).clamp(4.0, maxBarH);
                  final color =
                      catColors[attempt.category] ?? AppColors.headerTop;

                  final pct = (frac * 100).round();
                  return Expanded(
                    child: Semantics(
                      label:
                          '${attempt.category}: ${attempt.score} out of ${attempt.total}, $pct percent',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ExcludeSemantics(
                              child: Text(
                                '${attempt.score}',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: barH,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.85),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ExcludeSemantics(
                              child: Text(
                                attempt.category[0],
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: catColors.entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      e.key,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList(),
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
        ? AppColors.correctGreen
        : attempt.score >= attempt.total * 0.6
            ? AppColors.warningAmber
            : AppColors.historyRed;

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
        backgroundColor: AppColors.bgDark,
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
              backgroundColor: AppColors.incorrectRed,
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
