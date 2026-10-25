import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

/// In-app Privacy Policy screen.
/// Required by Google Play and Apple App Store for apps that collect
/// any user data (Firebase Auth UID, anonymous analytics, FCM tokens).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    _section(
                      'Last updated: April 2025',
                      '',
                      isSubtitle: true,
                    ),
                    _section(
                      '1. Overview',
                      'DocScam ("the App") is operated by ScamSlayers. This policy explains what '
                      'data we collect, why we collect it, and how it is used. We are committed to '
                      'protecting your privacy and complying with the Australian Privacy Act 1988.',
                    ),
                    _section(
                      '2. Data We Collect',
                      '• Anonymous user ID — generated automatically by Firebase Authentication. '
                      'No name, email, or phone number is required to use the App.\n\n'
                      '• Quiz scores — stored locally on your device and, if you opt in to the '
                      'leaderboard, uploaded anonymously to our database with a randomly generated '
                      'alias (e.g. "Alert Sentinel #4821").\n\n'
                      '• FCM device token — used only to deliver push notifications you have '
                      'permitted. Tokens are not sold or shared with third parties.\n\n'
                      '• Crash reports — anonymised stack traces sent to Firebase Crashlytics in '
                      'production builds to help us fix bugs.\n\n'
                      '• Analytics events — anonymised usage events (e.g. quiz started, category '
                      'selected) sent to Firebase Analytics to improve the App.',
                    ),
                    _section(
                      '3. Data We Do NOT Collect',
                      '• Real name, email address, or phone number (unless you voluntarily register)\n'
                      '• Location data\n'
                      '• Contacts or media\n'
                      '• Precise device identifiers (IMEI, MAC address)',
                    ),
                    _section(
                      '4. How We Use Your Data',
                      '• To provide and improve the quiz experience\n'
                      '• To display an anonymised global leaderboard\n'
                      '• To send quiz reminder notifications (only if you grant permission)\n'
                      '• To diagnose crashes and performance issues',
                    ),
                    _section(
                      '5. Data Sharing',
                      'We do not sell, trade, or rent your personal information. Data is processed '
                      'by Google Firebase services under Google\'s Privacy Policy. Firebase servers '
                      'are located in the United States and Australia (us-central1 / '
                      'australia-southeast1 regions).',
                    ),
                    _section(
                      '6. Data Retention',
                      'Anonymous leaderboard entries are retained indefinitely while the App is '
                      'active. You may request deletion of your entry by contacting us at the '
                      'address below. Local device data (quiz progress) can be cleared from the '
                      'Settings screen at any time.',
                    ),
                    _section(
                      '7. Children\'s Privacy',
                      'The App is intended for users aged 13 and over. We do not knowingly collect '
                      'data from children under 13. If you believe a child has provided data, '
                      'contact us and we will delete it promptly.',
                    ),
                    _section(
                      '8. Your Rights',
                      'Under Australian Privacy Law you have the right to:\n'
                      '• Access the personal information we hold about you\n'
                      '• Request correction of inaccurate data\n'
                      '• Request deletion of your data\n\n'
                      'To exercise these rights, email us at privacy@scamslayers.com.au',
                    ),
                    _section(
                      '9. Changes to This Policy',
                      'We may update this policy from time to time. Changes will be posted in the '
                      'App and on our website. Continued use after changes constitutes acceptance.',
                    ),
                    _section(
                      '10. Contact Us',
                      'ScamSlayers\nEmail: privacy@scamslayers.com.au\n'
                      'Website: www.scamslayers.com.au',
                    ),
                  ],
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
          Text(
            'Privacy Policy',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body, {bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: isSubtitle ? Colors.white54 : Colors.white,
              fontSize: isSubtitle ? 12 : 15,
              fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              body,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
