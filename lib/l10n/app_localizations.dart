import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DocScam'**
  String get appTitle;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'@powered  by ScamSlayers'**
  String get poweredBy;

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @homeButton.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeButton;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Level Up Your Scam sense!\nLet\'s play.'**
  String get tagline;

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'DocScam app logo'**
  String get logoLabel;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Game time, Outsmart the scamsters.'**
  String get welcomeSubtitle;

  /// No description provided for @selectBattlezone.
  ///
  /// In en, this message translates to:
  /// **'Select Your Battlezone'**
  String get selectBattlezone;

  /// No description provided for @viewProgress.
  ///
  /// In en, this message translates to:
  /// **'View progress'**
  String get viewProgress;

  /// No description provided for @viewProgressTooltip.
  ///
  /// In en, this message translates to:
  /// **'View Progress'**
  String get viewProgressTooltip;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details →'**
  String get viewDetails;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'📊 Your Progress'**
  String get yourProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @lastQuiz.
  ///
  /// In en, this message translates to:
  /// **'Last Quiz'**
  String get lastQuiz;

  /// No description provided for @reportAScam.
  ///
  /// In en, this message translates to:
  /// **'Report a Scam'**
  String get reportAScam;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Links to official Australian reporting bodies'**
  String get reportSubtitle;

  /// No description provided for @allCategoriesCompleted.
  ///
  /// In en, this message translates to:
  /// **'All categories completed! 🎉'**
  String get allCategoriesCompleted;

  /// No description provided for @tapToViewCertificate.
  ///
  /// In en, this message translates to:
  /// **'Tap to view and share your certificate'**
  String get tapToViewCertificate;

  /// No description provided for @reviewedDate.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {date}'**
  String reviewedDate(String date);

  /// No description provided for @couldNotLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress data.'**
  String get couldNotLoadProgress;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @selectCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please select correct answer'**
  String get selectCorrectAnswer;

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// No description provided for @correctLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correctLabel;

  /// No description provided for @incorrectLabel.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrectLabel;

  /// No description provided for @sourceAttribution.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String sourceAttribution(String source);

  /// No description provided for @questionCounter.
  ///
  /// In en, this message translates to:
  /// **'Q{current}/{total}'**
  String questionCounter(int current, int total);

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get progressTitle;

  /// No description provided for @overallStatistics.
  ///
  /// In en, this message translates to:
  /// **'Overall Statistics'**
  String get overallStatistics;

  /// No description provided for @quizzesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quizzes\nCompleted'**
  String get quizzesCompleted;

  /// No description provided for @overallAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Overall\nAccuracy'**
  String get overallAccuracy;

  /// No description provided for @scoreTrend.
  ///
  /// In en, this message translates to:
  /// **'Score Trend'**
  String get scoreTrend;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @quizHistory.
  ///
  /// In en, this message translates to:
  /// **'Quiz History'**
  String get quizHistory;

  /// No description provided for @clearAllProgress.
  ///
  /// In en, this message translates to:
  /// **'Clear All Progress'**
  String get clearAllProgress;

  /// No description provided for @clearAllProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Progress?'**
  String get clearAllProgressTitle;

  /// No description provided for @clearAllProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your progress data will be permanently deleted.'**
  String get clearAllProgressMessage;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @allProgressCleared.
  ///
  /// In en, this message translates to:
  /// **'All progress cleared'**
  String get allProgressCleared;

  /// No description provided for @noProgressYet.
  ///
  /// In en, this message translates to:
  /// **'No Progress Yet'**
  String get noProgressYet;

  /// No description provided for @completeQuizPrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete a quiz to see your progress!'**
  String get completeQuizPrompt;

  /// No description provided for @startAQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start a Quiz'**
  String get startAQuiz;

  /// No description provided for @errorLoadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Error loading progress'**
  String get errorLoadingProgress;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score'**
  String get bestScore;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @attemptCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String attemptCount(int count);

  /// No description provided for @lastDate.
  ///
  /// In en, this message translates to:
  /// **'Last: {date}'**
  String lastDate(String date);

  /// No description provided for @categoryChallenge.
  ///
  /// In en, this message translates to:
  /// **'{category} Challenge'**
  String categoryChallenge(String category);

  /// No description provided for @questionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number}: {result}'**
  String questionNumber(String number, String result);

  /// No description provided for @correctAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers:\n{answers}'**
  String correctAnswers(String answers);

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer:\n{answer}'**
  String correctAnswer(String answer);

  /// No description provided for @explanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Explanation: {text}'**
  String explanationLabel(String text);

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} out of {total}'**
  String scoreLabel(int score, int total);

  /// No description provided for @whatTypeOfScam.
  ///
  /// In en, this message translates to:
  /// **'What type of scam was it?'**
  String get whatTypeOfScam;

  /// No description provided for @describeScam.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe what happened'**
  String get describeScam;

  /// No description provided for @descriptionCopyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a reporting button below — your description will be copied to clipboard automatically.'**
  String get descriptionCopyHint;

  /// No description provided for @reportToOfficialBody.
  ///
  /// In en, this message translates to:
  /// **'Report to an official body'**
  String get reportToOfficialBody;

  /// No description provided for @reportInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Every report matters. Reporting scams helps authorities warn the public, disrupt criminal networks, and prevent others from losing money.'**
  String get reportInfoBanner;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Received a WhatsApp message from +61 4XX... offering a job for \$500/day…\"'**
  String get descriptionHint;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Description copied to clipboard — paste it into the report form'**
  String get copiedToClipboard;

  /// No description provided for @couldNotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpenUrl(String url);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
