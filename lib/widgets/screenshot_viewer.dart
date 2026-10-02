import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'hover_outline.dart';

/// Opens a full-screen view of one screenshot window's images, starting at
/// [initialIndex]. Returns the index that was showing when it was closed.
Future<int?> showScreenshotViewer(
  BuildContext context, {
  required List<String> assets,
  required int initialIndex,
  required String label,
}) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: L10n.of(context).t('common.close'),
    barrierColor: Colors.black.withValues(alpha: 0.88),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    pageBuilder: (context, _, _) => _ScreenshotViewer(assets: assets, initialIndex: initialIndex, label: label),
  );
}

class _ScreenshotViewer extends StatefulWidget {
  final List<String> assets;
  final int initialIndex;
  final String label;

  const _ScreenshotViewer({required this.assets, required this.initialIndex, required this.label});

  @override
  State<_ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<_ScreenshotViewer> {
  late int _index = widget.initialIndex;

  void _close() => Navigator.of(context).pop(_index);

  void _step(int delta) {
    final count = widget.assets.length;
    setState(() => _index = (_index + delta + count) % count);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final count = widget.assets.length;
    final size = MediaQuery.sizeOf(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Tapping the backdrop (anywhere outside the image) closes.
              Positioned.fill(
                child: GestureDetector(onTap: _close, behavior: HitTestBehavior.opaque),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 64, 16, 72),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: size.width * 0.94, maxHeight: size.height),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // Pinch / scroll to zoom into details.
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Image.asset(
                            widget.assets[_index],
                            key: ValueKey(_index),
                            fit: BoxFit.contain,
                            semanticLabel: '${widget.label} (${_index + 1}/$count)',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: HoverOutline(
                  key: const ValueKey('viewer-close'),
                  onTap: _close,
                  circle: true,
                  color: AppColors.surface,
                  idleBorderColor: AppColors.border,
                  tooltip: l.t('common.close'),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, size: 20, color: AppColors.textPrimary),
                ),
              ),
              if (count > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < count; i++)
                            HoverOutline(
                              key: ValueKey('viewer-dot-$i'),
                              onTap: () => setState(() => _index = i),
                              radius: 8,
                              semanticLabel: '${widget.label} (${i + 1}/$count)',
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: i == _index ? 22 : 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? AppColors.accentGreen
                                      : AppColors.textSecondary.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(5),
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
        ),
      ),
    );
  }
}
