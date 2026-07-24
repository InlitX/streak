import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

const _kGitHubUrl = 'https://github.com/InlitX/streak';
const _kCoffeeUrl = 'https://ko-fi.com/inlitx';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'v${info.version}');
      }
    });
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Streak',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 46,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.about_subtitle,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                height: 1.3,
                color: muted,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              context.l10n.about_story,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _LinkButton(
                    icon: LucideIcons.star,
                    label: 'GitHub',
                    onTap: () => _open(_kGitHubUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LinkButton(
                    icon: LucideIcons.coffee,
                    label: context.l10n.buy_coffee,
                    onTap: () => _open(_kCoffeeUrl),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                context.l10n.made_by,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _version,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: muted.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: scheme.onSurface),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
