import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'services/analytics_service.dart';

/// Lets users report a scam they have encountered.
/// Provides links to real Australian reporting bodies and a simple
/// description form that copies to clipboard for easy pasting into
/// an official report.
class ReportScamScreen extends StatefulWidget {
  const ReportScamScreen({super.key});

  @override
  State<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends State<ReportScamScreen> {
  String? _selectedType;
  final TextEditingController _descController = TextEditingController();

  static const List<String> _scamTypes = [
    'Tax / Government refund',
    'Delivery / Parcel',
    'Job offer',
    'Investment / Cryptocurrency',
    'Romance / Relationship',
    'Tech support / Device',
    'Phishing email or SMS',
    'Other',
  ];

  static const List<_ReportBody> _bodies = [
    _ReportBody(
      name: 'ACCC ScamWatch',
      description:
          'Australia\'s primary scam reporting service. Reports help warn others and inform law enforcement.',
      url: 'https://www.scamwatch.gov.au/report-a-scam',
      icon: Icons.shield_outlined,
      color: Color(0xFF1565C0),
    ),
    _ReportBody(
      name: 'Australian Cyber Security Centre',
      description:
          'For cyber-enabled scams — phishing, hacking, malware, or data breaches.',
      url: 'https://www.cyber.gov.au/report-and-recover/report',
      icon: Icons.computer_outlined,
      color: Color(0xFF2E7D32),
    ),
    _ReportBody(
      name: 'Australian Federal Police',
      description:
          'For serious financial fraud or if you have already lost money.',
      url: 'https://www.afp.gov.au/report-cybercrime',
      icon: Icons.local_police_outlined,
      color: Color(0xFF6A1B9A),
    ),
    _ReportBody(
      name: 'IDCARE',
      description:
          'Free support if your personal information has been stolen or misused.',
      url: 'https://www.idcare.org/contact/report-to-idcare',
      icon: Icons.person_outlined,
      color: Color(0xFFBF360C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.reportScamOpened();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _copyAndLaunch(_ReportBody body) {
    final parts = <String>[
      if (_selectedType != null) 'Type: $_selectedType',
      if (_descController.text.trim().isNotEmpty) _descController.text.trim(),
    ];
    final clipText = parts.join('\n');
    if (clipText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: clipText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Description copied to clipboard — paste it into the report form'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    AnalyticsService.reportBodyTapped(body.name);
    _launch(body.url);
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    children: [
                      // Why reporting matters
                      _buildInfoBanner(),
                      const SizedBox(height: 20),

                      // Scam type picker
                      Text(
                        'What type of scam was it?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTypePicker(),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Briefly describe what happened',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap a reporting button below — your description will be copied to clipboard automatically.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDescriptionField(),
                      const SizedBox(height: 24),

                      // Reporting bodies
                      Text(
                        'Report to an official body',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._bodies.map((body) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ReportBodyTile(
                              body: body,
                              onTap: () => _copyAndLaunch(body),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'Report a Scam',
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
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.correctGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.correctGreen.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.correctGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Every report matters. Reporting scams helps authorities warn the public, '
              'disrupt criminal networks, and prevent others from losing money.',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _scamTypes.map((type) {
        final selected = _selectedType == type;
        return Semantics(
          label: type,
          button: true,
          selected: selected,
          child: GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.headerTop
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.headerTop
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              type,
              style: GoogleFonts.inter(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ));
      }).toList(),
    );
  }

  Widget _buildDescriptionField() {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: _descController,
        maxLines: 4,
        maxLength: 500,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          counterStyle: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
          ),
          hintText:
              'e.g. "Received a WhatsApp message from +61 4XX... offering a job for \$500/day…"',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.headerTop, width: 1.5),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ReportBody {
  final String name;
  final String description;
  final String url;
  final IconData icon;
  final Color color;

  const _ReportBody({
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
  });
}

class _ReportBodyTile extends StatelessWidget {
  const _ReportBodyTile({required this.body, required this.onTap});
  final _ReportBody body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: body.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(body.icon, color: body.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body.description,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new,
                  color: Colors.white.withValues(alpha: 0.4), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
