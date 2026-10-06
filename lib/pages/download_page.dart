import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/platforms.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_outline.dart';
import '../widgets/site_scaffold.dart';

class DownloadPage extends StatefulWidget {
  final DeviceOs initialOs;

  const DownloadPage({super.key, required this.initialOs});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  late DeviceOs _os = widget.initialOs;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final wide = isWideLayout(context);

    final installers = _Panel(
      icon: Icons.inventory_2_outlined,
      title: l.t('download.installers'),
      children: [for (final f in kInstallers[_os] ?? const <InstallerFile>[]) _InstallerTile(file: f)],
    );
    final commands = _Panel(
      icon: Icons.terminal,
      title: l.t(_os == DeviceOs.windows ? 'download.commands_powershell' : 'download.commands_terminal'),
      children: [
        Text(
          l.t('common.coming_soon'),
          style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );

    // Right-hand side: the selected platform's contents.
    final Widget content;
    if (_os.showsComingSoon) {
      content = _ComingSoon(os: _os);
    } else if (wide) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: installers),
            const SizedBox(width: 20),
            Expanded(child: commands),
          ],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [installers, const SizedBox(height: 16), commands],
      );
    }

    // Left-hand side: the platform list (a wrapping row on narrow screens).
    final platforms = [
      for (final os in DeviceOs.values)
        _PlatformItem(os: os, selected: os == _os, expand: wide, onTap: () => setState(() => _os = os)),
    ];

    return SiteScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: wide ? 48 : 28),
          Text(
            l.t('download.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontFamily,
              color: AppColors.textPrimary,
              fontSize: wide ? 36 : 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: wide ? 36 : 20),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 220,
                  child: _Panel(icon: Icons.devices, title: l.t('download.choose_platform'), children: platforms),
                ),
                const SizedBox(width: 20),
                Expanded(child: content),
              ],
            )
          else ...[
            Text(
              l.t('download.choose_platform'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: platforms),
            const SizedBox(height: 20),
            content,
          ],
          SizedBox(height: wide ? 56 : 36),
        ],
      ),
    );
  }
}

class _PlatformItem extends StatelessWidget {
  final DeviceOs os;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  const _PlatformItem({required this.os, required this.selected, required this.expand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentGreen : AppColors.textPrimary;
    return HoverOutline(
      onTap: onTap,
      selected: selected,
      color: AppColors.background,
      idleBorderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(os.icon, size: 18, color: selected ? AppColors.accentGreen : AppColors.accentCyan),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              os.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kFontFamily, color: color, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (expand) ...[
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: selected ? AppColors.accentGreen : AppColors.textSecondary),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Panel({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
        ],
      ),
    );
  }
}

class _InstallerTile extends StatelessWidget {
  final InstallerFile file;

  const _InstallerTile({required this.file});

  Future<void> _download(BuildContext context) async {
    if (!file.published) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).t('download.not_available'))));
      return;
    }
    await launchUrl(file.uri);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return HoverOutline(
      onTap: () => _download(context),
      color: AppColors.background,
      idleBorderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l.t(file.descriptionKey),
                  style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: AppColors.accentGreen),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final DeviceOs os;

  const _ComingSoon({required this.os});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(os.icon, size: 40, color: AppColors.warning),
          const SizedBox(height: 14),
          Text(
            L10n.of(context).t('download.coming_soon'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kFontFamily,
              color: AppColors.warning,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
