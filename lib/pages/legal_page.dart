import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_outline.dart';
import '../widgets/site_scaffold.dart';

/// Placeholder for Privacy Policy / Terms & Conditions until their text exists.
class LegalPage extends StatelessWidget {
  final String titleKey;

  const LegalPage({super.key, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SiteScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Text(
              l.t(titleKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kFontFamily,
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.t('legal.coming_soon'),
              style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 28),
            SiteButton(label: l.t('common.back_home'), icon: Icons.arrow_back, onTap: () => Routes.goHome(context)),
          ],
        ),
      ),
    );
  }
}
