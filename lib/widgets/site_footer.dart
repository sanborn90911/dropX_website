import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'hover_outline.dart';

/// Help & Support footer — the target of the header's "?" button.
///
/// Every time [highlightTrigger] changes, the Help & Support block pulses a
/// bordered highlight, so clicking "?" gives visible feedback even when the
/// page is too short to scroll.
class SiteFooter extends StatefulWidget {
  final Listenable highlightTrigger;

  const SiteFooter({super.key, required this.highlightTrigger});

  @override
  State<SiteFooter> createState() => _SiteFooterState();
}

class _SiteFooterState extends State<SiteFooter> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  // Two quick pulses, then a slow fade back to no border.
  late final Animation<double> _strength = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 16),
    TweenSequenceItem(tween: Tween(begin: 0.35, end: 1.0), weight: 16),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 36),
  ]).animate(_pulse);

  @override
  void initState() {
    super.initState();
    widget.highlightTrigger.addListener(_play);
  }

  @override
  void didUpdateWidget(SiteFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightTrigger != widget.highlightTrigger) {
      oldWidget.highlightTrigger.removeListener(_play);
      widget.highlightTrigger.addListener(_play);
    }
  }

  @override
  void dispose() {
    widget.highlightTrigger.removeListener(_play);
    _pulse.dispose();
    super.dispose();
  }

  void _play() => _pulse.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _strength,
            builder: (context, child) {
              final s = _strength.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: s), width: 1.5),
                  boxShadow: s == 0
                      ? null
                      : [BoxShadow(color: AppColors.accentCyan.withValues(alpha: 0.18 * s), blurRadius: 16)],
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                Text(
                  l.t('footer.help_title'),
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    color: AppColors.accentCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                SiteLink(
                  label: Routes.supportEmail,
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: Routes.supportEmail));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(l.t('common.copied'))));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              SiteLink(label: l.t('footer.privacy'), onTap: () => Routes.openLegal('privacy')),
              SiteLink(label: l.t('footer.terms'), onTap: () => Routes.openLegal('terms')),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l.t('footer.copyright'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textDisabled, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
