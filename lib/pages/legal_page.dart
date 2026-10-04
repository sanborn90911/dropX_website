import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_outline.dart';
import '../widgets/site_scaffold.dart';

/// Old `/privacy` and `/terms` routes, kept so existing links still land
/// somewhere useful: the real policy text is the static `legal.html`, so
/// this immediately hands off to the matching section there, with a plain
/// link as a fallback if the browser blocks the redirect.
class LegalPage extends StatefulWidget {
  final String titleKey;
  final String section;

  const LegalPage({super.key, required this.titleKey, required this.section});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Routes.openLegal(widget.section));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SiteScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Text(
              l.t(widget.titleKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kFontFamily,
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            SiteButton(
              label: l.t(widget.titleKey),
              icon: Icons.open_in_new,
              onTap: () => Routes.openLegal(widget.section),
            ),
            const SizedBox(height: 12),
            SiteButton(label: l.t('common.back_home'), icon: Icons.arrow_back, onTap: () => Routes.goHome(context)),
          ],
        ),
      ),
    );
  }
}
