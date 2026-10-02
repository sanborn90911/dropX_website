import 'package:flutter/material.dart';

import '../data/platforms.dart';
import '../l10n/l10n.dart';
import '../l10n/languages.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'hover_dropdown.dart';
import 'hover_outline.dart';

class SiteHeader extends StatelessWidget {
  final bool isHome;
  final VoidCallback onHelp;

  const SiteHeader({super.key, required this.isHome, required this.onHelp});

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _LanguageDropdown(compact: !wide),
            ),
          ),
          _Logo(isHome: isHome, compact: !wide),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DownloadDropdown(compact: !wide),
                  SizedBox(width: wide ? 12 : 8),
                  _HelpButton(onTap: onHelp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool isHome;
  final bool compact;

  const _Logo({required this.isHome, required this.compact});

  @override
  Widget build(BuildContext context) {
    return HoverOutline(
      onTap: () => Routes.goHome(context),
      selected: isHome,
      glow: true,
      color: AppColors.background,
      radius: 12,
      tooltip: L10n.of(context).t('header.home_tooltip'),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', width: compact ? 26 : 32, height: compact ? 26 : 32),
          SizedBox(width: compact ? 6 : 10),
          Text(
            'dropX',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: AppColors.accentGreen,
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final bool compact;

  const _LanguageDropdown({required this.compact});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    DropdownEntry entry(String code) {
      final lang = kLanguages[code]!;
      return DropdownEntry(
        label: lang.nativeName,
        trailing: lang.nativeName == lang.englishName ? null : lang.englishName,
        selected: l.code == code,
        onSelected: () => l.setLanguage(code),
      );
    }

    return HoverDropdown(
      menuWidth: 260,
      tooltip: l.t('header.language'),
      entries: [
        DropdownEntry.header(l.t('header.language_global')),
        for (final code in kGlobalTop20) entry(code),
        DropdownEntry.header(l.t('header.language_india')),
        for (final code in kIndiaTop10) entry(code),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            compact ? l.code.toUpperCase() : l.language.nativeName,
            style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textPrimary, fontSize: 14),
          ),
          const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _DownloadDropdown extends StatelessWidget {
  final bool compact;

  const _DownloadDropdown({required this.compact});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return HoverDropdown(
      openOnHover: true,
      alignEnd: true,
      menuWidth: 200,
      tooltip: compact ? l.t('header.download') : null,
      entries: [
        for (final os in DeviceOs.values)
          DropdownEntry(label: os.label, icon: os.icon, onSelected: () => Routes.go(context, Routes.download(os))),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.download_rounded, size: 18, color: AppColors.accentGreen),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              l.t('header.download'),
              style: const TextStyle(
                fontFamily: kFontFamily,
                color: AppColors.accentGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
          if (!compact) const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HelpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverOutline(
      onTap: onTap,
      circle: true,
      color: AppColors.surface,
      idleBorderColor: AppColors.border,
      tooltip: L10n.of(context).t('header.help_tooltip'),
      child: const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: AppColors.accentCyan,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
