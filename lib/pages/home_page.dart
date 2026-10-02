import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/platforms.dart';
import '../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_outline.dart';
import '../widgets/screenshot_viewer.dart';
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

/// Slideshow pacing. Windows are numbered desktop left/right = 0/1, phone
/// left/centre/right = 2/3/4. One shared schedule plays them in diagonal
/// pairs so only one image is ever fading:
///
///   desktop left  → (1s after its fade ends) phone right
///   desktop right → (1s after its fade ends) phone left
///   phone centre on its own, then the round repeats.
///
/// Pairs and the centre turn are separated by a slightly longer rest. One
/// round takes 15s, so each window changes every 15s.
const int _fadeMs = 1400;
const int _pairGapMs = 1000; // between a desktop change ending and its diagonal phone change
const int _restMs = 2000; // between groups
const Duration _fadeDuration = Duration(milliseconds: _fadeMs);
const Curve _fadeCurve = Curves.easeInOutSine;
const Duration _firstChangeDelay = Duration(seconds: 1); // first pair starts right after the page opens

/// (window, wait since the previous change started).
const List<({int slot, Duration wait})> _schedule = [
  (slot: 0, wait: Duration(milliseconds: _fadeMs + _restMs)), // desktop left
  (slot: 4, wait: Duration(milliseconds: _fadeMs + _pairGapMs)), // phone right
  (slot: 1, wait: Duration(milliseconds: _fadeMs + _restMs)), // desktop right
  (slot: 2, wait: Duration(milliseconds: _fadeMs + _pairGapMs)), // phone left
  (slot: 3, wait: Duration(milliseconds: _fadeMs + _restMs)), // phone centre
];

/// The window whose turn it is; `seq` makes repeated turns still notify.
typedef _SlideTurn = ({int seq, int slot});

class _Screenshots extends StatefulWidget {
  const _Screenshots();

  @override
  State<_Screenshots> createState() => _ScreenshotsState();
}

class _ScreenshotsState extends State<_Screenshots> {
  final _turn = ValueNotifier<_SlideTurn?>(null);
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_firstChangeDelay, _nextTurn);
  }

  void _nextTurn() {
    final seq = (_turn.value?.seq ?? 0) + 1;
    _turn.value = (seq: seq, slot: _schedule[_step].slot);
    _step = (_step + 1) % _schedule.length;
    _timer = Timer(_schedule[_step].wait, _nextTurn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final wide = isWideLayout(context);
    final desktopCount = _desktopScreenshots.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = wide ? 24.0 : 20.0;
        final maxWidth = constraints.maxWidth;
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
                    turn: _turn,
                    slot: i,
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
                    turn: _turn,
                    slot: desktopCount + i,
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

/// One screenshot window. It advances only when [turn] names its [slot], and
/// the new image fades in over the old one, which stays fully visible
/// underneath, so there's no dip in brightness mid-transition. A hovered
/// window skips its turn, and picking an image with the dots skips the
/// window's next turn so it doesn't change straight after a click.
class _SlideshowFrame extends StatefulWidget {
  final List<String> assets;
  final String label;
  final double width;
  final double aspect;
  final ValueListenable<_SlideTurn?> turn;
  final int slot;

  const _SlideshowFrame({
    required this.assets,
    required this.label,
    required this.width,
    required this.aspect,
    required this.turn,
    required this.slot,
  });

  @override
  State<_SlideshowFrame> createState() => _SlideshowFrameState();
}

class _SlideshowFrameState extends State<_SlideshowFrame> with SingleTickerProviderStateMixin {
  int _index = 0;
  int? _previous; // image underneath while the current one fades in
  bool _hovered = false;
  bool _pressed = false;
  bool _viewerOpen = false;
  bool _skipNextTurn = false;

  late final AnimationController _fade = AnimationController(vsync: this, duration: _fadeDuration, value: 1)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && _previous != null) setState(() => _previous = null);
    });
  late final Animation<double> _opacity = CurvedAnimation(parent: _fade, curve: _fadeCurve);

  @override
  void initState() {
    super.initState();
    widget.turn.addListener(_onTurn);
  }

  @override
  void didUpdateWidget(_SlideshowFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turn != widget.turn) {
      oldWidget.turn.removeListener(_onTurn);
      widget.turn.addListener(_onTurn);
    }
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
    widget.turn.removeListener(_onTurn);
    _fade.dispose();
    super.dispose();
  }

  void _onTurn() {
    if (widget.turn.value?.slot != widget.slot) return;
    if (_skipNextTurn) {
      _skipNextTurn = false;
      return;
    }
    if (_hovered || _viewerOpen || widget.assets.length < 2) return;
    _crossfadeTo((_index + 1) % widget.assets.length);
  }

  Future<void> _openViewer() async {
    _viewerOpen = true;
    final shown = await showScreenshotViewer(context, assets: widget.assets, initialIndex: _index, label: widget.label);
    if (!mounted) return;
    _viewerOpen = false;
    // Keep showing whichever image the visitor ended on in the viewer.
    if (shown != null && shown != _index) _show(shown);
  }

  void _crossfadeTo(int index) {
    if (index == _index) return;
    setState(() {
      _previous = _index;
      _index = index;
    });
    _fade.forward(from: 0);
  }

  void _show(int index) {
    _skipNextTurn = true;
    _crossfadeTo(index);
  }

  Widget _image(int index) => Image.asset(
    widget.assets[index],
    key: ValueKey(index),
    fit: BoxFit.cover,
    gaplessPlayback: true,
    semanticLabel: '${widget.label} (${index + 1}/${widget.assets.length})',
  );

  @override
  Widget build(BuildContext context) {
    final count = widget.assets.length;
    final small = widget.width < 300;
    final previous = _previous;
    // Same interaction style as every other clickable item: light border on
    // hover, solid while pressed.
    final borderColor = _pressed
        ? AppColors.accentGreen
        : _hovered
        ? AppColors.hoverBorder
        : AppColors.border;
    return MouseRegion(
      cursor: SystemMouseCursors.zoomIn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _openViewer,
        child: Semantics(
          button: true,
          label: '${widget.label} (${_index + 1}/$count)',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.width,
            height: widget.width / widget.aspect,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: _frameContent(count, small, previous),
          ),
        ),
      ),
    );
  }

  Widget _frameContent(int count, bool small, int? previous) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ?(previous == null ? null : _image(previous)),
        FadeTransition(opacity: _opacity, child: _image(_index)),
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
