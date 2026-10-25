// App entry and shell for DocScam.
// - Initialises Firebase (gracefully degrades if not configured)
// - Configures theme, routes, and the landing screen

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'certificate_screen.dart';
import 'constants.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'models/progress_model.dart';
import 'privacy_policy_screen.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';
import 'quiz_screen.dart';
import 'report_scam_screen.dart';
import 'result_screen.dart';
import 'progress_screen.dart';
import 'services/analytics_service.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/question_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  final onboardingDone = await OnboardingScreen.isComplete();
  runApp(DocScamApp(showOnboarding: !onboardingDone));
}

/// Initialises Firebase and all dependent services.
/// All errors are caught so the app launches even without Firebase config.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Wire up Crashlytics as the Flutter + platform error handler.
    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Initialise dependent services.
    AnalyticsService.init();
    await AuthService().init();
    QuestionService().init();
    await NotificationService.init();
  } catch (e) {
    // Firebase not configured yet — app runs in offline/local mode.
    debugPrint('[Firebase] Skipping — not configured: $e');
    debugPrint('[Firebase] Run "flutterfire configure" to enable cloud features.');
  }
}

class DocScamApp extends StatelessWidget {
  final bool showOnboarding;
  const DocScamApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    final analyticsObserver = AnalyticsService.observer;

    final textTheme = GoogleFonts.playfairDisplayTextTheme();

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: AppColors.seedPurple,
      textTheme: textTheme,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.seedPurple,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.bgDark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [
        if (analyticsObserver != null) analyticsObserver,
      ],
      home: showOnboarding ? const OnboardingScreen() : const MainScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return _slideRoute(const OnboardingScreen());
          case '/leaderboard':
            return _slideRoute(const LeaderboardScreen());
          case '/settings':
            return _slideRoute(const SettingsScreen());
          case '/privacy':
            return _slideRoute(const PrivacyPolicyScreen());
          case '/main':
            return _slideRoute(const MainScreen());
          case '/home':
            return _slideRoute(const HomeScreen());
          case '/progress':
            return _slideRoute(const ProgressScreen());
          case '/report-scam':
            return _slideRoute(const ReportScamScreen());
          case '/quiz':
            final category = settings.arguments as String;
            return _slideRoute(QuizScreen(category: category));
          case '/result':
            final args = settings.arguments as Map<String, dynamic>;
            return _fadeRoute(ResultScreen(
              score: args['score'] as int,
              total: args['total'] as int,
              category: args['category'] as String,
              reviews: args['reviews'] as List<Map<String, dynamic>>,
            ));
          case '/certificate':
            final progress = settings.arguments as ProgressData;
            return _slideRoute(CertificateScreen(progress: progress));
          default:
            return null;
        }
      },
    );
  }

  /// Slide-in from right transition.
  static Route<T> _slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  /// Fade-in transition (used for result screen).
  static Route<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgDeepPurple,
                  AppColors.bgMid,
                  AppColors.bgLightPurple,
                ],
              ),
            ),
          ),
          // Decorative blobs — excluded from accessibility tree
          const ExcludeSemantics(
            child: Stack(children: [
              PositionedBlob(top: 24, left: -20, size: 120),
              PositionedBlob(top: 32, right: 18, size: 70, intensity: 0.8),
              PositionedBlob(bottom: 120, left: 26, size: 64, intensity: 0.7),
              PositionedBlob(bottom: 48, right: 32, size: 80),
              PositionedBlob(bottom: 220, right: 18, size: 56, intensity: 0.85),
            ]),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      label: l10n.logoLabel,
                      child: Container(
                        width: size.width * 0.60,
                        height: size.width * 0.60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            size.width * 0.55 * 0.06,
                            size.width * 0.55 * 0.10,
                            size.width * 0.55 * 0.06,
                            size.width * 0.55 * 0.06,
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Column(
                      children: [
                        Text(
                          l10n.tagline,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const ExcludeSemantics(
                          child: Opacity(
                            opacity: 0.55,
                            child: SizedBox(
                              height: 1,
                              width: 220,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 140,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ctaRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          shadowColor:
                              Colors.black.withValues(alpha: 0.25),
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/home'),
                        child: Text(
                          l10n.playButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: 0.7,
                        child: Text(
                          l10n.poweredBy,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A decorative blob positioned in the background.
class PositionedBlob extends StatelessWidget {
  final double? top, left, right, bottom;
  final double size;
  final double intensity;

  const PositionedBlob({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.blobPurple.withValues(alpha: 0.95 * intensity),
              AppColors.bgMid.withValues(alpha: 0.60 * intensity),
              const Color(0x00000000),
            ],
            stops: const [0.2, 0.65, 1.0],
            center: const Alignment(-0.2, -0.2),
            radius: 0.9,
          ),
        ),
      ),
    );
  }
}
