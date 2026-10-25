import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'services/analytics_service.dart';
import 'services/leaderboard_service.dart';
import 'services/notification_service.dart';
import 'services/progress_service.dart';

// All category names used in the app — kept in sync with home_screen.
const _allCategories = [
  'Seasons', 'Delivery', 'Job Offers',
  'Investment & Crypto', 'Romance Scams', 'Tech Support',
  'Banking & Finance', 'Social Media',
];

/// Displays the quiz results: overall score and a breakdown of each question.
/// Works with both single-answer and multiple-answer questions.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.category,
    required this.reviews,
  });

  final int score;
  final int total;
  final String category;

  /// Each review entry contains:
  /// - 'explanation': String? (can be null)
  /// - 'isCorrect': bool
  final List<Map<String, dynamic>> reviews;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _submitToLeaderboard();
    _maybeShowReminder();
  }

  Future<void> _submitToLeaderboard() async {
    await LeaderboardService.instance.submitScore(
      category: widget.category,
      score: widget.score,
      total: widget.total,
    );
  }

  Future<void> _maybeShowReminder() async {
    try {
      final svc = await ProgressService.getInstance();
      final progress = await svc.getProgressData();
      final completed = _allCategories
          .where((c) => progress.categories.containsKey(c))
          .length;
      final remaining = _allCategories.length - completed;
      await NotificationService.instance.showQuizReminderNotification(
        completedCategory: widget.category,
        remaining: remaining,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
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
                _buildHeader(context),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    itemCount: widget.reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final r = widget.reviews[i];
                      final List<String> options =
                          List<String>.from(r['options'] as List);
                      final List<int> pickedIndices =
                          List<int>.from(r['pickedIndices'] as List);
                      final List<int> correctIndices =
                          List<int>.from(r['correctIndices'] as List);

                      final String chosen =
                          pickedIndices.map((j) => options[j]).join(', ');
                      final String correct =
                          correctIndices.map((j) => options[j]).join(', ');

                      final bool isCorrect = r['isCorrect'] as bool;
                      final String? explanation = r['explanation'] as String?;

                      return _AnswerCard(
                        number: i + 1,
                        isCorrect: isCorrect,
                        chosen: chosen,
                        correct: correct,
                        explanation: explanation,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.bgDark,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      AnalyticsService.screenView('home');
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Home'),
                  ),
                ),
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

  /// Builds the header with back button, title, and score circle.
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              '${widget.category} Challenge',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Semantics(
            label: 'Score: ${widget.score} out of ${widget.total}',
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 6,
                ),
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Text(
                  '${widget.score}/${widget.total}',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing the result for a single question.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.number,
    required this.isCorrect,
    required this.chosen,
    required this.correct,
    this.explanation,
  });

  final int number;
  final bool isCorrect;
  final String chosen;
  final String correct;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final Color markColor =
        isCorrect ? AppColors.correctGreen : AppColors.incorrectRed;
    final IconData markIcon = isCorrect ? Icons.check_circle : Icons.cancel;

    return Material(
      /// Provide a translucent background.
      color: Colors.white.withValues(alpha: 0.10),
      elevation: 0,

      /// Use shape to add a border: green for correct, red for incorrect.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: markColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                /// Bigger icon for the tick or cross.
                Icon(markIcon, color: markColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Question ${number.toString().padLeft(2, '0')}: '
                  '${isCorrect ? 'Correct' : 'Incorrect'}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            /// Display correct answers on separate lines when there are multiple.
            Builder(
              builder: (context) {
                /// Split the comma-separated correct string into individual answers.
                final List<String> parts = correct.split(', ');
                final bool multiple = parts.length > 1;

                /// If multiple answers, prefix each with a bullet and join with newlines.
                final String display =
                    multiple ? parts.map((p) => '• $p').join('\n') : correct;
                return Text(
                  'Correct Answer${multiple ? 's' : ''}:\n$display',
                  style: GoogleFonts.inter(color: Colors.white),
                );
              },
            ),
            if (explanation != null && explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Explanation: $explanation',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
