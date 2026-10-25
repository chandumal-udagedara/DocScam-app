import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'question_bank.dart';
import 'services/analytics_service.dart';
import 'services/progress_service.dart';
import 'services/question_service.dart';
import 'services/quiz_state_service.dart';

/// QuizScreen presents up to 5 random questions for a given category.
/// It lets the user select multiple answers but limits the selections
/// to exactly the number of correct options (`correctIndices.length`).
///
/// Flow per question:
///   1. User selects answer(s) → taps "Submit"
///   2. Tiles colour-code: green (correct), red (wrong pick), amber border (missed)
///   3. Feedback card shows correct/incorrect + explanation
///   4. User taps "Next" / "Finish" to advance
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.category});
  final String category;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Q> _selected = [];
  bool _loadingQuestions = true;
  int _index = 0;
  int _score = 0;
  Set<int> _pickedIndices = {};

  /// Whether the current question has been submitted.
  /// When true, tiles show answer colours and the feedback card is visible.
  bool _submitted = false;

  final List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Try to restore a saved in-progress quiz for this category.
    final saved = await QuizStateService.load();
    if (saved != null &&
        saved.category == widget.category &&
        saved.questions.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selected = saved.questions;
          _index = saved.currentIndex;
          _score = saved.score;
          _reviews.addAll(saved.reviews);
          _loadingQuestions = false;
        });
      }
      return;
    }

    final questions =
        await QuestionService().getQuestions(widget.category);
    final list = [...questions]..shuffle(Random());
    if (mounted) {
      setState(() {
        _selected = list.take(min(5, list.length)).toList();
        _loadingQuestions = false;
      });
      AnalyticsService.quizStarted(widget.category);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingQuestions) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.screenGradStart, AppColors.bgDark],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
            ),
          ),
        ),
      );
    }

    final q = _selected[_index];
    final int maxSelections = q.correctIndices.length;
    final bool isLastQuestion = _index == _selected.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.screenGradStart, AppColors.bgDark],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(q),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageIfAny(q),
                        _buildPrompt(q),
                        const SizedBox(height: 12),
                        Text(
                          'Please select correct answer',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (int i = 0; i < q.options.length; i++) ...[
                          _OptionTile(
                            label: q.options[i],
                            indexLabel: String.fromCharCode(97 + i),
                            state: _tileState(i, q),
                            onTap: () => _handleTap(i, maxSelections),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_submitted) _buildFeedback(q),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitted
                        ? _advance
                        : (_pickedIndices.length == maxSelections
                            ? _submitAnswer
                            : null),
                    child: Text(
                      _submitted
                          ? (isLastQuestion ? 'Finish' : 'Next')
                          : 'Submit',
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Inline feedback shown after the user submits an answer.
  /// Shows correct/incorrect status and the question explanation.
  Widget _buildFeedback(Q q) {
    final Set<int> correctSet =
        Set<int>.from((q.correctIndices as Iterable).cast<int>());
    final bool isCorrect = _pickedIndices.length == correctSet.length &&
        _pickedIndices.containsAll(correctSet);
    final Color accent =
        isCorrect ? AppColors.correctGreen : AppColors.incorrectRed;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (q.explanation != null &&
                    q.explanation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    q.explanation!,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
                // Source attribution
                Builder(builder: (_) {
                  final meta = categoryMeta[widget.category];
                  if (meta == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Source: ${meta['source']}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header with back button, title, and question progress.
  Widget _buildHeader(Q q) {
    return Container(
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
                'DocScam',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Text(
            'Q${_index + 1}/${_selected.length}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Display image if any (asset or network).
  /// Shows a loading spinner while network images fetch and an error
  /// placeholder if an asset is missing or the network request fails.
  Widget _buildImageIfAny(Q q) {
    if (q.assetImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          q.assetImage!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(),
        ),
      );
    } else if (q.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          q.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _buildImageLoading(),
          errorBuilder: (_, __, ___) => _buildImageError(),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildImageError() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                color: Colors.white.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 6),
            Text(
              'Image unavailable',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Question prompt text widget.
  Widget _buildPrompt(Q q) {
    return Text(
      q.prompt,
      style: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Returns the visual state for an option tile.
  /// Before submission: selected or idle.
  /// After submission: correct / incorrect / missedCorrect / idle.
  _TileState _tileState(int index, Q q) {
    if (_submitted) {
      final isCorrect = q.correctIndices.contains(index);
      final isPicked = _pickedIndices.contains(index);
      if (isPicked && isCorrect) return _TileState.correct;
      if (isPicked && !isCorrect) return _TileState.incorrect;
      if (!isPicked && isCorrect) return _TileState.missedCorrect;
      return _TileState.disabled;
    }
    return _pickedIndices.contains(index) ? _TileState.selected : _TileState.idle;
  }

  /// Handle tapping a tile. No-ops once the answer has been submitted.
  void _handleTap(int index, int maxSelections) {
    if (_submitted) return;
    setState(() {
      if (_pickedIndices.contains(index)) {
        _pickedIndices.remove(index);
      } else {
        if (maxSelections == 1) {
          _pickedIndices = {index};
        } else {
          if (_pickedIndices.length >= maxSelections) {
            final int toRemove = _pickedIndices.first;
            _pickedIndices.remove(toRemove);
          }
          _pickedIndices.add(index);
        }
      }
    });
  }

  /// Evaluate the current answer, record the review, and reveal feedback.
  void _submitAnswer() {
    final Q q = _selected[_index];
    final Set<int> correctSet =
        Set<int>.from((q.correctIndices as Iterable).cast<int>());
    final bool isCorrect = _pickedIndices.length == correctSet.length &&
        _pickedIndices.containsAll(correctSet);
    if (isCorrect) _score++;

    _reviews.add({
      'question': q.prompt,
      'options': q.options,
      'pickedIndices': _pickedIndices.toList(),
      'correctIndices': q.correctIndices,
      'explanation': q.explanation,
      'isCorrect': isCorrect,
    });

    AnalyticsService.questionAnswered(
      category: widget.category,
      questionIndex: _index,
      correct: isCorrect,
    );

    setState(() => _submitted = true);

    // Persist state so the quiz can be resumed if the app is killed.
    QuizStateService.save(QuizState(
      category: widget.category,
      questions: _selected,
      currentIndex: _index,
      score: _score,
      reviews: _reviews,
    ));
  }

  /// Advance to the next question, or finish the quiz.
  void _advance() {
    if (_index < _selected.length - 1) {
      setState(() {
        _index++;
        _pickedIndices = {};
        _submitted = false;
      });
    } else {
      QuizStateService.clear();
      _saveProgressAndNavigate();
    }
  }

  /// Save quiz result and navigate to results screen.
  Future<void> _saveProgressAndNavigate() async {
    try {
      final service = await ProgressService.getInstance();
      await service.saveQuizResult(
        category: widget.category,
        score: _score,
        total: _selected.length,
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to save progress: $e\n$stackTrace');
    }

    AnalyticsService.quizCompleted(
      widget.category,
      score: _score,
      total: _selected.length,
    );

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/result',
        arguments: {
          'score': _score,
          'total': _selected.length,
          'category': widget.category,
          'reviews': _reviews,
        },
      );
    }
  }

  /// Footer with attribution text.
  Widget _buildFooter() {
    return const Padding(
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
    );
  }
}

/// Visual states for an answer option tile.
enum _TileState {
  idle,
  selected,
  disabled,
  correct,       // user picked this AND it was right
  incorrect,     // user picked this AND it was wrong
  missedCorrect, // user did NOT pick this but it was right
}

/// A widget representing a single answer option.
/// Colour changes based on state (selection + post-submission feedback).
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.indexLabel,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String indexLabel;
  final _TileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (state == _TileState.correct) {
      bg = AppColors.correctGreen;
      fg = Colors.white;
    } else if (state == _TileState.incorrect) {
      bg = AppColors.incorrectRed;
      fg = Colors.white;
    } else if (state == _TileState.selected) {
      bg = AppColors.selectedOption;
      fg = Colors.white;
    } else {
      // idle, disabled, missedCorrect all use white bg
      bg = Colors.white;
      fg = Colors.black87;
    }

    // missedCorrect: white background with amber border so the user can see
    // which answer(s) they should have picked.
    final BorderSide tileBorder = state == _TileState.missedCorrect
        ? const BorderSide(color: AppColors.warningAmber, width: 2)
        : BorderSide.none;

    // Only idle and selected states allow further tapping.
    final bool tappable =
        state == _TileState.idle || state == _TileState.selected;

    final Color labelBorderColor = state == _TileState.disabled
        ? Colors.black26
        : fg.withValues(alpha: 0.2);

    String semanticLabel = '$indexLabel) $label';
    if (state == _TileState.correct) semanticLabel += ', correct';
    if (state == _TileState.incorrect) semanticLabel += ', incorrect';
    if (state == _TileState.missedCorrect) {
      semanticLabel += ', correct answer (not selected)';
    }

    return Semantics(
      label: semanticLabel,
      button: tappable,
      selected: state == _TileState.selected || state == _TileState.correct,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(tileBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: tappable ? onTap : null,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: fg.withValues(
                          alpha:
                              state == _TileState.selected ? 0.20 : 0.08),
                      border:
                          Border.all(color: labelBorderColor, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$indexLabel)',
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (state == _TileState.correct)
                    const Icon(Icons.check, color: Colors.white, size: 18),
                  if (state == _TileState.incorrect)
                    const Icon(Icons.close, color: Colors.white, size: 18),
                  if (state == _TileState.missedCorrect)
                    const Icon(Icons.check,
                        color: AppColors.warningAmber, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
