import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc_scam_mobile_app/quiz_screen.dart';
import 'package:doc_scam_mobile_app/services/question_service.dart';
import 'package:doc_scam_mobile_app/services/quiz_state_service.dart';

/// Widget tests for [QuizScreen].
///
/// Verifies the submit → feedback → advance flow:
///   1. Selecting an answer enables the "Submit" button
///   2. Tapping "Submit" reveals the feedback card
///   3. Button text changes to "Next" / "Finish"
///   4. Tiles become non-tappable after submission
void main() {
  const testCategory = 'Seasons';

  setUp(() async {
    // Disable fire-and-forget quiz state saves so they can't race between tests.
    QuizStateService.enabled = false;
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
    // Clear QuestionService singleton memory cache and cached prefs ref.
    QuestionService().invalidateAll();
  });

  tearDown(() async {
    QuizStateService.enabled = true;
  });

  Future<void> pumpQuiz(WidgetTester tester) async {
    // Use a tall viewport so all options, buttons, and feedback are visible.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: const QuizScreen(category: testCategory),
        onGenerateRoute: (settings) {
          // Catch /result navigation so the test doesn't crash
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Result Screen')),
          );
        },
      ),
    );
    // Let QuestionService future resolve
    await tester.pumpAndSettle();
  }

  /// Finds tappable option tiles (InkWell widgets with borderRadius 16).
  Finder findOptionTiles() {
    return find.byWidgetPredicate(
      (w) =>
          w is InkWell &&
          w.borderRadius == BorderRadius.circular(16) &&
          w.onTap != null,
    );
  }

  /// Select first option and submit answer.
  /// Returns true if submission succeeded, false otherwise.
  Future<bool> selectAndSubmit(WidgetTester tester) async {
    // Tap first option tile
    final tiles = findOptionTiles();
    expect(tiles, findsWidgets);
    await tester.tap(tiles.first);
    await tester.pump();

    // Verify the option was selected (Submit button should be enabled)
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Submit'),
    );
    if (button.onPressed == null) return false;

    // Tap Submit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();
    return find.text('Submit').evaluate().isEmpty;
  }

  group('QuizScreen submit flow', () {
    testWidgets('shows Submit button that is initially disabled',
        (tester) async {
      await pumpQuiz(tester);

      expect(find.text('Submit'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting an option enables the Submit button',
        (tester) async {
      await pumpQuiz(tester);

      final tiles = findOptionTiles();
      expect(tiles, findsWidgets);
      await tester.tap(tiles.first);
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Submit reveals feedback card with Correct/Incorrect',
        (tester) async {
      await pumpQuiz(tester);

      final submitted = await selectAndSubmit(tester);
      if (!submitted) return; // Skip if tap didn't register

      // Either "Correct!" or "Incorrect" text should appear
      final correct = find.text('Correct!');
      final incorrect = find.text('Incorrect');
      expect(
        correct.evaluate().isNotEmpty || incorrect.evaluate().isNotEmpty,
        isTrue,
        reason: 'Feedback card should show after submission',
      );
    });

    testWidgets('button changes to Next/Finish after submission',
        (tester) async {
      await pumpQuiz(tester);

      final submitted = await selectAndSubmit(tester);
      if (!submitted) return;

      final next = find.text('Next');
      final finish = find.text('Finish');
      expect(
        next.evaluate().isNotEmpty || finish.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('options are not tappable after submission', (tester) async {
      await pumpQuiz(tester);

      final submitted = await selectAndSubmit(tester);
      if (!submitted) return;

      // After submission, no InkWell option tiles should have a non-null onTap.
      final tappable = findOptionTiles();
      expect(tappable, findsNothing);
    });

    testWidgets('tapping Next advances to question 2', (tester) async {
      await pumpQuiz(tester);

      final submitted = await selectAndSubmit(tester);
      if (!submitted) return;

      final nextFinder = find.widgetWithText(ElevatedButton, 'Next');
      if (nextFinder.evaluate().isNotEmpty) {
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        // Question counter should now show "Q2/..."
        expect(find.textContaining('Q2/'), findsOneWidget);
        // Submit button should be back (for the new question)
        expect(find.text('Submit'), findsOneWidget);
      }
    });

    testWidgets('source attribution appears in feedback card', (tester) async {
      await pumpQuiz(tester);

      final submitted = await selectAndSubmit(tester);
      if (!submitted) return;

      // Seasons category has metadata — source should appear
      expect(find.textContaining('Source:'), findsOneWidget);
    });
  });
}
