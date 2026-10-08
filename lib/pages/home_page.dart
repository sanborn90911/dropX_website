import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/platforms.dart';
import '../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/device_link_animation.dart';
import '../widgets/hover_outline.dart';
import '../widgets/screenshot_viewer.dart';
import '../widgets/site_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// The one clock for everything on this page that changes by itself (the
  /// screenshot windows and the feature boxes). It hands out one turn at a
  /// time, so no two things ever change at the same moment.
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
    _turn.value = (seq: seq, slot: _schedule[_step]);
    _step = (_step + 1) % _schedule.length;
    _timer = Timer(_stride, _nextTurn);
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
          _Screenshots(turn: _turn),
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
            child: _FeatureShowcase(turn: _turn),
          ),
          SizedBox(height: wide ? 64 : 40),
        ],
      ),
    );
  }
}

/// The gallery images. The "flawless delivery" slide (5) leads, so it is what
/// loads first. Each image carries its own title and subtitle.
const List<String> _desktopScreenshots = [
  'assets/screenshots/desktop/5.png',
  'assets/screenshots/desktop/1.png',
  'assets/screenshots/desktop/2.png',
  'assets/screenshots/desktop/3.png',
  'assets/screenshots/desktop/4.png',
];

/// The looping device animation's width and height, as a share of the desktop
/// window's. It is centred on the window's bottom-right corner, so half of it
/// (in each direction) hangs outside the window, clear of the screenshot text.
const double _animationShare = 0.21;

/// Pacing for everything on the page that changes by itself.
///
/// Slot numbers: the screenshot window is 0 and the four feature boxes are
/// 1–4 (top-left, bottom-left, top-right, bottom-right, see [_featureBoxes]).
/// The device animation in the window's corner just loops on its own and takes
/// no turn.
///
/// One shared clock hands out a single turn every [_stride]: a change takes
/// [_fadeMs] and the next one starts [_gapMs] after it ends, so only one
/// thing is ever changing and no two changes ever coincide. The order keeps
/// the diagonal pairing for the feature boxes:
///
///   screenshot → box top-left → box bottom-right →
///   box bottom-left → box top-right → (repeat)
///
/// A full round is 5 turns × 2.4s = 12s, so the screenshot changes every 12s
/// while something on the page changes every 2.4s.
const int _fadeMs = 1400;
const int _gapMs = 1000; // between one change ending and the next starting
const Duration _fadeDuration = Duration(milliseconds: _fadeMs);
const Duration _stride = Duration(milliseconds: _fadeMs + _gapMs);
const Curve _fadeCurve = Curves.easeInOutSine;
const Duration _firstChangeDelay = Duration(milliseconds: 2500); // first screenshot stays up this long after the page opens

const int _featureSlotBase = 1;
const List<int> _schedule = [0, 1, 4, 2, 3];

/// The window whose turn it is; `seq` makes repeated turns still notify.
typedef _SlideTurn = ({int seq, int slot});

class _Screenshots extends StatelessWidget {
  final ValueListenable<_SlideTurn?> turn;

  const _Screenshots({required this.turn});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The window plus the half of the animation that hangs past its
        // bottom-right corner fit in the available width (and in the layout
        // height, so nothing below is overlapped).
        final unitWidth = constraints.maxWidth.clamp(0.0, 1100.0);
        final width = unitWidth / (1 + _animationShare / 2);
        final height = width / (16 / 9);
        final animationWidth = width * _animationShare;
        final animationHeight = height * _animationShare;
        return Center(
          child: SizedBox(
            width: width + animationWidth / 2,
            height: height + animationHeight / 2,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: _SlideshowFrame(
                    assets: _desktopScreenshots,
                    label: l.t('home.screenshot_desktop'),
                    width: width,
                    aspect: 16 / 9,
                    turn: turn,
                    slot: 0,
                  ),
                ),
                // Lets clicks through, so the screenshot underneath still opens.
                Positioned(
                  left: width - animationWidth / 2,
                  top: height - animationHeight / 2,
                  child: IgnorePointer(
                    child: DeviceLinkAnimation(width: animationWidth, height: animationHeight),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  /// Swiping the window (a finger on a phone, or a mouse drag) steps to the
  /// neighbouring image: left → next, right → previous, wrapping around. A
  /// short quick flick counts too, not only a long slow drag.
  double _dragDx = 0;

  void _onDragEnd(DragEndDetails details) {
    final dx = _dragDx;
    _dragDx = 0;
    final count = widget.assets.length;
    if (count < 2) return;
    final flick = details.primaryVelocity ?? 0;
    final direction = dx.abs() > 40 ? dx : (flick.abs() > 400 ? flick : 0.0);
    if (direction == 0) return;
    _show((_index + (direction < 0 ? 1 : -1) + count) % count);
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
        onHorizontalDragStart: (_) => _dragDx = 0,
        onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
        onHorizontalDragCancel: () => _dragDx = 0,
        onHorizontalDragEnd: _onDragEnd,
        child: Semantics(
          button: true,
          label: '${widget.label} (${_index + 1}/$count)',
          child: AnimatedContainer(
            key: ValueKey('slideshow-${widget.slot}'),
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
                        compact: widget.width < 140,
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
  final bool compact; // very narrow window (phone on a small screen): smaller dots so five still fit
  final String label;
  final VoidCallback onTap;

  const _SlideDot({super.key, required this.active, required this.compact, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverOutline(
      onTap: onTap,
      radius: 8,
      semanticLabel: label,
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: compact ? 3 : 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: active ? (compact ? 11 : 18) : (compact ? 5 : 7),
        height: compact ? 5 : 7,
        decoration: BoxDecoration(
          color: active ? AppColors.accentGreen : AppColors.textSecondary.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String key; // translation key prefix: `<key>.title` / `<key>.body`

  const _Feature(this.icon, this.key);
}

/// Four boxes with two features each, in layout order: top-left, bottom-left,
/// top-right, bottom-right. Each box flips between its two features.
const List<List<_Feature>> _featureBoxes = [
  [_Feature(Icons.devices, 'feature.cross_platform'), _Feature(Icons.folder_open, 'feature.any_file')],
  [_Feature(Icons.wifi_off, 'feature.no_internet'), _Feature(Icons.wifi_tethering, 'feature.hotspot')],
  [_Feature(Icons.lock_outline, 'feature.private'), _Feature(Icons.handshake_outlined, 'feature.auth')],
  [_Feature(Icons.verified_outlined, 'feature.verified'), _Feature(Icons.extension_outlined, 'feature.chunks')],
];

/// Two columns of two boxes each (a single column on narrow screens). Row
/// mates share a height so the grid stays tidy while the text inside changes.
class _FeatureShowcase extends StatelessWidget {
  final ValueListenable<_SlideTurn?> turn;

  const _FeatureShowcase({required this.turn});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        Widget box(int i) => _FeatureBox(index: i, features: _featureBoxes[i], turn: turn, slot: _featureSlotBase + i);

        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              for (var i = 0; i < _featureBoxes.length; i++) ...[if (i > 0) const SizedBox(height: gap), box(i)],
            ],
          );
        }
        Widget row(int left, int right) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: box(left)),
              const SizedBox(width: gap),
              Expanded(child: box(right)),
            ],
          ),
        );
        // Left column = boxes 0 and 1, right column = boxes 2 and 3.
        return Column(
          children: [
            row(0, 2),
            const SizedBox(height: gap),
            row(1, 3),
          ],
        );
      },
    );
  }
}

/// One feature box. Like a screenshot window it changes only when [turn]
/// names its [slot], pauses while hovered, and has a selector underneath that
/// jumps straight to a feature (skipping the box's next turn so it doesn't
/// change right after a click).
class _FeatureBox extends StatefulWidget {
  final int index;
  final List<_Feature> features;
  final ValueListenable<_SlideTurn?> turn;
  final int slot;

  const _FeatureBox({required this.index, required this.features, required this.turn, required this.slot});

  @override
  State<_FeatureBox> createState() => _FeatureBoxState();
}

class _FeatureBoxState extends State<_FeatureBox> with SingleTickerProviderStateMixin {
  int _index = 0;
  int? _previous; // feature fading out while the current one fades in
  bool _hovered = false;
  bool _skipNextTurn = false;

  late final AnimationController _fade = AnimationController(vsync: this, duration: _fadeDuration, value: 1)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && _previous != null) setState(() => _previous = null);
    });

  // Two sentences laid over each other read as a smudge, so unlike the
  // screenshots the old text fades out over the first half of the change and
  // the new text fades in over the second, with only a sliver of overlap.
  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _fade,
    curve: const Interval(0.45, 1.0, curve: Curves.easeInOutSine),
  );
  late final Animation<double> _fadeOut = ReverseAnimation(
    CurvedAnimation(
      parent: _fade,
      curve: const Interval(0.0, 0.55, curve: Curves.easeInOutSine),
    ),
  );

  @override
  void initState() {
    super.initState();
    widget.turn.addListener(_onTurn);
  }

  @override
  void didUpdateWidget(_FeatureBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turn != widget.turn) {
      oldWidget.turn.removeListener(_onTurn);
      widget.turn.addListener(_onTurn);
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
    if (_hovered) return;
    _changeTo((_index + 1) % widget.features.length);
  }

  void _changeTo(int index) {
    if (index == _index) return;
    setState(() {
      _previous = _index;
      _index = index;
    });
    _fade.forward(from: 0);
  }

  void _show(int index) {
    _skipNextTurn = true;
    _changeTo(index);
  }

  Animation<double> _opacityOf(int i) => i == _index
      ? _fadeIn
      : i == _previous
      ? _fadeOut
      : kAlwaysDismissedAnimation;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final features = widget.features;
    return MouseRegion(
      onEnter: (_) => _hovered = true,
      onExit: (_) => _hovered = false,
      child: Container(
        key: ValueKey('feature-box-${widget.index}'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Every feature is laid out (only one is visible), so the box is
            // always as tall as its tallest text and never jumps.
            Stack(
              children: [
                for (var i = 0; i < features.length; i++)
                  ExcludeSemantics(
                    excluding: i != _index,
                    child: FadeTransition(
                      key: ValueKey('feature-${widget.index}-item-$i'),
                      opacity: _opacityOf(i),
                      child: _FeatureContent(feature: features[i]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < features.length; i++)
                  _FeatureDot(
                    key: ValueKey('feature-dot-${widget.index}-$i'),
                    active: i == _index,
                    label: l.t('${features[i].key}.title'),
                    onTap: () => _show(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureContent extends StatelessWidget {
  final _Feature feature;

  const _FeatureContent({required this.feature});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(feature.icon, color: AppColors.accentCyan, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('${feature.key}.title'),
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.t('${feature.key}.body'),
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
    );
  }
}

/// Selector for a feature box: deliberately a different, much smaller thing
/// than the screenshot dots (cyan like the feature icons, 4px, no backing),
/// but still the site-wide light-on-hover / solid-on-press border.
class _FeatureDot extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _FeatureDot({super.key, required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverOutline(
      onTap: onTap,
      radius: 6,
      accent: AppColors.accentCyan,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: active ? 10 : 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.accentCyan.withValues(alpha: active ? 1 : 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
