// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DocScam';

  @override
  String get poweredBy => '@powered  by ScamSlayers';

  @override
  String get playButton => 'Play';

  @override
  String get homeButton => 'Home';

  @override
  String get tagline => 'Level Up Your Scam sense!\nLet\'s play.';

  @override
  String get logoLabel => 'DocScam app logo';

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeSubtitle => 'Game time, Outsmart the scamsters.';

  @override
  String get selectBattlezone => 'Select Your Battlezone';

  @override
  String get viewProgress => 'View progress';

  @override
  String get viewProgressTooltip => 'View Progress';

  @override
  String get viewDetails => 'View Details →';

  @override
  String get yourProgress => '📊 Your Progress';

  @override
  String get completed => 'Completed';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get lastQuiz => 'Last Quiz';

  @override
  String get reportAScam => 'Report a Scam';

  @override
  String get reportSubtitle => 'Links to official Australian reporting bodies';

  @override
  String get allCategoriesCompleted => 'All categories completed! 🎉';

  @override
  String get tapToViewCertificate => 'Tap to view and share your certificate';

  @override
  String reviewedDate(String date) {
    return 'Reviewed $date';
  }

  @override
  String get couldNotLoadProgress => 'Could not load progress data.';

  @override
  String get retry => 'Retry';

  @override
  String get selectCorrectAnswer => 'Please select correct answer';

  @override
  String get submitButton => 'Submit';

  @override
  String get nextButton => 'Next';

  @override
  String get finishButton => 'Finish';

  @override
  String get correctLabel => 'Correct!';

  @override
  String get incorrectLabel => 'Incorrect';

  @override
  String sourceAttribution(String source) {
    return 'Source: $source';
  }

  @override
  String questionCounter(int current, int total) {
    return 'Q$current/$total';
  }

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get progressTitle => 'Your Progress';

  @override
  String get overallStatistics => 'Overall Statistics';

  @override
  String get quizzesCompleted => 'Quizzes\nCompleted';

  @override
  String get overallAccuracy => 'Overall\nAccuracy';

  @override
  String get scoreTrend => 'Score Trend';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get quizHistory => 'Quiz History';

  @override
  String get clearAllProgress => 'Clear All Progress';

  @override
  String get clearAllProgressTitle => 'Clear All Progress?';

  @override
  String get clearAllProgressMessage =>
      'This action cannot be undone. All your progress data will be permanently deleted.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get clearButton => 'Clear';

  @override
  String get allProgressCleared => 'All progress cleared';

  @override
  String get noProgressYet => 'No Progress Yet';

  @override
  String get completeQuizPrompt => 'Complete a quiz to see your progress!';

  @override
  String get startAQuiz => 'Start a Quiz';

  @override
  String get errorLoadingProgress => 'Error loading progress';

  @override
  String get bestScore => 'Best Score';

  @override
  String get average => 'Average';

  @override
  String get never => 'Never';

  @override
  String attemptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String lastDate(String date) {
    return 'Last: $date';
  }

  @override
  String categoryChallenge(String category) {
    return '$category Challenge';
  }

  @override
  String questionNumber(String number, String result) {
    return 'Question $number: $result';
  }

  @override
  String correctAnswers(String answers) {
    return 'Correct Answers:\n$answers';
  }

  @override
  String correctAnswer(String answer) {
    return 'Correct Answer:\n$answer';
  }

  @override
  String explanationLabel(String text) {
    return 'Explanation: $text';
  }

  @override
  String scoreLabel(int score, int total) {
    return 'Score: $score out of $total';
  }

  @override
  String get whatTypeOfScam => 'What type of scam was it?';

  @override
  String get describeScam => 'Briefly describe what happened';

  @override
  String get descriptionCopyHint =>
      'Tap a reporting button below — your description will be copied to clipboard automatically.';

  @override
  String get reportToOfficialBody => 'Report to an official body';

  @override
  String get reportInfoBanner =>
      'Every report matters. Reporting scams helps authorities warn the public, disrupt criminal networks, and prevent others from losing money.';

  @override
  String get descriptionHint =>
      'e.g. \"Received a WhatsApp message from +61 4XX... offering a job for \$500/day…\"';

  @override
  String get copiedToClipboard =>
      'Description copied to clipboard — paste it into the report form';

  @override
  String couldNotOpenUrl(String url) {
    return 'Could not open $url';
  }
}
