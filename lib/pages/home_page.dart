import 'dart:async';

import 'package:flutter/material.dart';

import '../data/platforms.dart';
import '../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_outline.dart';
import '../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final wide = isWideLayout(context);
    final detected = DeviceOs.detect();

    return SiteScaffold(
      isHome: true,
      // Screenshots use the extra width; text and feature tiles stay in the
      // standard column.
      maxContentWidth: 1640,
      child: Column(
        children: [
          SizedBox(height: wide ? 64 : 36),
          Text(
            l.t('home.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontFamily,
              color: AppColors.textPrimary,
              fontSize: wide ? 46 : 30,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              l.t('home.subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                color: AppColors.textSecondary,
                fontSize: wide ? 17 : 14,
                height: 1.45,
              ),
            ),
          ),
          SizedBox(height: wide ? 36 : 28),
          SiteButton(
            large: true,
            icon: Icons.download_rounded,
            label: l.t('home.download_for', {'os': detected.label}),
            foreground: AppColors.accentGreen,
            onTap: () => Routes.go(context, Routes.download(detected)),
          ),
          SizedBox(height: wide ? 48 : 32),
          const _Screenshots(),
          SizedBox(height: wide ? 64 : 44),
          Text(
            l.t('home.features_title'),
            style: const TextStyle(
              fontFamily: kFontFamily,
              color: AppColors.accentGreen,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentWidth),
            child: const _FeatureGrid(),
          ),
          SizedBox(height: wide ? 64 : 40),
        ],
      ),
    );
  }
}

/// Screenshot galleries: one entry per window, each a slideshow of the
/// listed images (copied from the project's `Screenshots/` folder).
const List<List<String>> _desktopScreenshots = [
  ['assets/screenshots/desktop/1.jpg', 'assets/screenshots/desktop/2.jpg'],
  ['assets/screenshots/desktop/2.jpg', 'assets/screenshots/desktop/3.jpg'],
];
const List<List<String>> _mobileScreenshots = [
  ['assets/screenshots/mobile/1.png', 'assets/screenshots/mobile/2.png'],
  ['assets/screenshots/mobile/3.png', 'assets/screenshots/mobile/4.png'],
  ['assets/screenshots/mobile/5.png', 'assets/screenshots/mobile/6.png'],
];

/// How long each screenshot stays up, and how long the crossfade takes.
const Duration _slideInterval = Duration(seconds: 4);
const Duration _fadeDuration = Duration(milliseconds: 1100);

/// Windows are staggered evenly across one interval so they never change
/// together: window n first changes at `interval + n * interval / count`.
Duration _staggerFor(int window, int windowCount) => _slideInterval * window ~/ windowCount;

class _Screenshots extends StatelessWidget {
  const _Screenshots();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final wide = isWideLayout(context);
    final windowCount = _desktopScreenshots.length + _mobileScreenshots.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = wide ? 24.0 : 20.0;
        final maxWidth = constraints.maxWidth;
        final desktopCount = _desktopScreenshots.length;
        // Desktop: side by side on wide screens; one per swipe on phones.
        final desktopWidth = wide ? ((maxWidth - gap * (desktopCount - 1)) / desktopCount) : maxWidth * 0.85;
        final mobileWidth = wide ? (maxWidth * 0.2).clamp(220.0, 300.0) : (maxWidth * 0.55).clamp(0.0, 240.0);
        return Column(
          children: [
            _Gallery(
              maxWidth: maxWidth,
              gap: gap,
              children: [
                for (var i = 0; i < desktopCount; i++)
                  _SlideshowFrame(
                    assets: _desktopScreenshots[i],
                    label: '${l.t('home.screenshot_desktop')} ${i + 1}',
                    width: desktopWidth,
                    aspect: 16 / 9,
                    startDelay: _staggerFor(i, windowCount),
                  ),
              ],
            ),
            SizedBox(height: gap),
            _Gallery(
              maxWidth: maxWidth,
              gap: gap,
              children: [
                for (var i = 0; i < _mobileScreenshots.length; i++)
                  _SlideshowFrame(
                    assets: _mobileScreenshots[i],
                    label: '${l.t('home.screenshot_mobile')} ${i + 1}',
                    width: mobileWidth,
                    aspect: 9 / 16,
                    startDelay: _staggerFor(desktopCount + i, windowCount),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A centered row of frames that scrolls sideways when it doesn't fit.
class _Gallery extends StatelessWidget {
  final double maxWidth;
  final double gap;
  final List<Widget> children;

  const _Gallery({required this.maxWidth, required this.gap, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: maxWidth),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(width: gap), children[i]],
          ],
        ),
      ),
    );
  }
}

/// One screenshot window with its own timer: it crossfades to the next image
/// every [_slideInterval], starting after [startDelay] so neighbouring
/// windows change at different moments. Autoplay pauses while hovered, and
/// the dots underneath jump straight to an image (restarting the countdown).
class _SlideshowFrame extends StatefulWidget {
  final List<String> assets;
  final String label;
  final double width;
  final double aspect;
  final Duration startDelay;

  const _SlideshowFrame({
    required this.assets,
    required this.label,
    required this.width,
    required this.aspect,
    this.startDelay = Duration.zero,
  });

  @override
  State<_SlideshowFrame> createState() => _SlideshowFrameState();
}

class _SlideshowFrameState extends State<_SlideshowFrame> {
  int _index = 0;
  bool _hovered = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext(_slideInterval + widget.startDelay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode every slide up front so a change never fades in a blank frame.
    for (final asset in widget.assets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext(Duration after) {
    _timer?.cancel();
    if (widget.assets.length < 2) return;
    _timer = Timer(after, () {
      if (!mounted) return;
      if (!_hovered) setState(() => _index = (_index + 1) % widget.assets.length);
      _scheduleNext(_slideInterval);
    });
  }

  void _show(int index) {
    if (index != _index) setState(() => _index = index);
    _scheduleNext(_slideInterval);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.assets.length;
    final small = widget.width < 300;
    return MouseRegion(
      onEnter: (_) => _hovered = true,
      onExit: (_) => _hovered = false,
      child: Container(
        width: widget.width,
        height: widget.width / widget.aspect,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: _fadeDuration,
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              // Both images fill the frame for the whole crossfade, so nothing
              // resizes or jumps mid-transition.
              layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
              child: Image.asset(
                widget.assets[_index],
                key: ValueKey(_index),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                semanticLabel: '${widget.label} (${_index + 1}/$count)',
              ),
            ),
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: small ? 6 : 10,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < count; i++)
                          _SlideDot(
                            key: ValueKey('slide-dot-$i'),
                            active: i == _index,
                            label: '${widget.label} (${i + 1}/$count)',
                            onTap: () => _show(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Position indicator that doubles as the way to pick a screenshot. Uses the
/// site-wide hover/press border, just scaled down to dot size.
class _SlideDot extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _SlideDot({super.key, required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverOutline(
      onTap: onTap,
      radius: 8,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: active ? 18 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: active ? AppColors.accentGreen : AppColors.textSecondary.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _features = [
    (Icons.devices, 'feature.cross_platform'),
    (Icons.wifi_off, 'feature.no_internet'),
    (Icons.lock_outline, 'feature.private'),
    (Icons.folder_open, 'feature.any_file'),
    (Icons.wifi_tethering, 'feature.hotspot'),
    (Icons.verified_outlined, 'feature.verified'),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 520 ? 2 : 1);
        final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (icon, key) in _features)
              Container(
                width: tileWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.accentCyan, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('$key.title'),
                            style: const TextStyle(
                              fontFamily: kFontFamily,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.t('$key.body'),
                            style: const TextStyle(
                              fontFamily: kFontFamily,
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
