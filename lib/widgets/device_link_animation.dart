import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A tiny looping logo animation: three devices (laptop, phone, tablet) wired
/// together like the dropX share mark, with a file passing from one to the
/// next, around and around.
///
/// Purely decorative, so it's hidden from screen readers. With the system's
/// "reduce motion" setting on, it holds still on a single frame instead.
class DeviceLinkAnimation extends StatefulWidget {
  final double width;
  final double height;

  const DeviceLinkAnimation({super.key, required this.width, required this.height});

  @override
  State<DeviceLinkAnimation> createState() => _DeviceLinkAnimationState();
}

class _DeviceLinkAnimationState extends State<DeviceLinkAnimation> with SingleTickerProviderStateMixin {
  // One hop (send, arrive, ripple) per device: three hops make a loop.
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0.18; // mid-hop, so a still frame still shows a file in flight
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(math.max(6, widget.width * 0.07)),
            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.55)),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(painter: _LinkPainter(_controller.value)),
          ),
        ),
      ),
    );
  }
}

enum _Device { laptop, phone, tablet }

class _LinkPainter extends CustomPainter {
  final double t; // 0..1 over the whole loop

  _LinkPainter(this.t);

  static const _devices = [_Device.laptop, _Device.phone, _Device.tablet];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h);
    // Triangle: laptop top-left, phone top-right, tablet bottom-centre.
    final nodes = [Offset(w * 0.24, h * 0.30), Offset(w * 0.76, h * 0.30), Offset(w * 0.50, h * 0.74)];

    final leg = (t * 3).floor() % 3;
    final p = t * 3 - (t * 3).floor(); // progress within this hop
    final from = nodes[leg];
    final toIndex = (leg + 1) % 3;
    final to = nodes[toIndex];

    // Wires between the devices, the active one brighter.
    final wire = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, unit * 0.02)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final active = i == leg;
      wire.color = AppColors.accentCyan.withValues(alpha: active ? 0.7 : 0.22);
      canvas.drawLine(nodes[i], nodes[(i + 1) % 3], wire);
    }

    // The file: leaves in the first 70% of the hop with a short fading trail.
    const travel = 0.7;
    final q = Curves.easeInOut.transform((p / travel).clamp(0.0, 1.0));
    if (p < travel) {
      for (var i = 3; i >= 0; i--) {
        final back = (q - i * 0.07).clamp(0.0, 1.0);
        final pos = Offset.lerp(from, to, back)!;
        final fade = i == 0 ? 1.0 : 0.45 / i;
        canvas.drawCircle(
          pos,
          unit * (i == 0 ? 0.045 : 0.035),
          Paint()..color = AppColors.accentGreen.withValues(alpha: fade),
        );
      }
    }

    // Arrival: the receiving device lights up green and a ripple fades out.
    final arrive = p < travel ? 0.0 : (p - travel) / (1 - travel);
    for (var i = 0; i < 3; i++) {
      final receiving = i == toIndex;
      final glow = receiving ? (p < travel ? 0.0 : 1 - arrive * 0.6) : 0.0;
      final color = Color.lerp(AppColors.accentCyan, AppColors.accentGreen, glow)!;
      _drawDevice(canvas, _devices[i], nodes[i], unit * 0.34, color);
    }
    if (arrive > 0) {
      canvas.drawCircle(
        to,
        unit * (0.12 + 0.2 * arrive),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, unit * 0.02)
          ..color = AppColors.accentGreen.withValues(alpha: 0.8 * (1 - arrive)),
      );
    }
  }

  void _drawDevice(Canvas canvas, _Device device, Offset c, double s, Color color) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, s * 0.07)
      ..strokeCap = StrokeCap.round
      ..color = color;
    final fill = Paint()..color = AppColors.background;
    RRect box(double w, double h, Offset centre, double r) =>
        RRect.fromRectAndRadius(Rect.fromCenter(center: centre, width: w, height: h), Radius.circular(r));

    switch (device) {
      case _Device.laptop:
        final screen = box(s * 0.78, s * 0.5, c.translate(0, -s * 0.06), s * 0.06);
        canvas.drawRRect(screen, fill);
        canvas.drawRRect(screen, line);
        canvas.drawLine(c.translate(-s * 0.5, s * 0.27), c.translate(s * 0.5, s * 0.27), line);
      case _Device.phone:
        final body = box(s * 0.36, s * 0.7, c, s * 0.08);
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, line);
        canvas.drawCircle(c.translate(0, s * 0.26), s * 0.025, Paint()..color = color);
      case _Device.tablet:
        final body = box(s * 0.7, s * 0.52, c, s * 0.08);
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, line);
        canvas.drawCircle(c.translate(s * 0.29, 0), s * 0.025, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) => old.t != t;
}
