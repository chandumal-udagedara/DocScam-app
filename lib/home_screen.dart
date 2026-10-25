import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';
import 'constants.dart';
import 'models/progress_model.dart';
import 'question_bank.dart';
import 'services/analytics_service.dart';
import 'services/progress_service.dart';
import 'utils/date_formatter.dart';

/// Ordered list of quiz categories with their icons.
/// Add a new entry here when a new category is added to the question bank.
const List<(String, IconData)> _categoryConfig = [
  ('Seasons', Icons.card_giftcard),
  ('Delivery', Icons.inventory_2_outlined),
  ('Job Offers', Icons.work_outline),
  ('Investment & Crypto', Icons.trending_up),
  ('Romance Scams', Icons.favorite_border),
  ('Tech Support', Icons.computer_outlined),
  ('Banking & Finance', Icons.account_balance_outlined),
  ('Social Media', Icons.people_outline),
];

/// Home landing page that lists all quiz categories with a decorative
/// background and header. Shows a progress summary card, a certificate
/// banner when all categories are completed, and a "Report a Scam" button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<ProgressData> _progressFuture;

  static const double _outerPadding = 14;
  static const double _tileMinHeight = 88;
  static const double _tileRadius = 18;

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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.screenGradStart, AppColors.headerTop],
              ),
            ),
          ),
          const _Blob(top: 110, left: -18, size: 90),
          const _Blob(bottom: 100, right: 36, size: 72),
          const _Blob(bottom: 20, left: 90, size: 56),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _outerPadding),
                    child: FutureBuilder<ProgressData>(
                      future: _progressFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      size: 36),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Could not load progress data.',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      _loadProgress();
                                      setState(() {});
                                    },
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final progress = snapshot.hasData ? snapshot.data! : null;
                        final allCompleted = progress != null &&
                            _categoryConfig.every((cfg) =>
                                progress.categories.containsKey(cfg.$1) &&
                                progress.categories[cfg.$1]!.attemptCount > 0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress summary card
                            if (progress != null && progress.hasAttempts)
                              _buildProgressCard(progress),
                            if (progress != null && progress.hasAttempts)
                              const SizedBox(height: 14),

                            // Certificate banner — shown once all categories done
                            if (allCompleted)
                              _buildCertificateBanner(progress),
                            if (allCompleted) const SizedBox(height: 14),

                            // Section title
                            Text(
                              'Select Your Battlezone',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Category tiles — generated from _categoryConfig
                            ..._categoryConfig.map((cfg) {
                              final label = cfg.$1;
                              final icon = cfg.$2;
                              final meta = categoryMeta[label];
                              final subtitle = meta != null
                                  ? 'Reviewed ${meta['lastReviewed']}'
                                  : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _ChallengeTile(
                                  icon: icon,
                                  label: label,
                                  subtitle: subtitle,
                                  minHeight: _tileMinHeight,
                                  radius: _tileRadius,
                                  onTap: () =>
                                      _openQuiz(context, label),
                                ),
                              );
                            }),

                            const SizedBox(height: 4),

                            // Report a Scam button
                            _buildReportButton(context),

                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
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

  Widget _buildHeader() {
    return GestureDetector(
      child: Container(
        height: 110,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgDark, AppColors.headerBottom],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome!',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Game time, Outsmart the scamsters.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Settings',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Settings',
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
            Semantics(
              label: 'View leaderboard',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.emoji_events_outlined, color: Colors.white),
                tooltip: 'Leaderboard',
                onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
              ),
            ),
            Semantics(
              label: 'View progress',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                tooltip: 'View Progress',
                onPressed: () => Navigator.pushNamed(context, '/progress'),
              ),
            ),
            const SizedBox(width: 4),
            const ProfileButton(),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ProgressData progress) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
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
                  '📊 Your Progress',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/progress'),
                  child: Text(
                    'View Details →',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _progressStat('${progress.totalQuizzes}', 'Completed'),
                _progressStat(
                    '${progress.overallAccuracy.toStringAsFixed(0)}%',
                    'Accuracy'),
                _progressStat(
                    DateFormatter.formatShort(progress.lastQuizDate),
                    'Last Quiz'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateBanner(ProgressData progress) {
    return Material(
      color: AppColors.warningAmber.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/certificate',
            arguments: progress),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined,
                  color: AppColors.warningAmber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All categories completed! 🎉',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tap to view and share your certificate',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(_tileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_tileRadius),
        onTap: () => Navigator.pushNamed(context, '/report-scam'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 28, color: AppColors.ctaRed),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report a Scam',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Links to official Australian reporting bodies',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context, String category) {
    AnalyticsService.categorySelected(category);
    Navigator.pushNamed(context, '/quiz', arguments: category);
  }
}

class _ChallengeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final double minHeight;
  final double radius;

  const _ChallengeTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.minHeight = 88,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.black87),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double? top, left, right, bottom;
  final double size;

  const _Blob(
      {this.top, this.left, this.right, this.bottom, required this.size});

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
              AppColors.blobPurple.withValues(alpha: 0.95),
              AppColors.bgMid.withValues(alpha: 0.6),
              const Color(0x00000000),
            ],
            stops: const [0.2, 0.65, 1],
            center: const Alignment(-0.2, -0.2),
            radius: 0.9,
          ),
        ),
      ),
    );
  }
}
