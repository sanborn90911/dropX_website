import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The single interaction style used by every clickable item on the site:
/// a light border on hover/focus, which turns into a solid accent border
/// while pressed or when [selected].
///
/// [glow] swaps the solid "selected" border for a soft, low-gleam one (used
/// on the header logo while on the homepage).
class HoverOutline extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final bool glow;
  final bool circle;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color accent;
  final Color idleBorderColor;
  final String? tooltip;
  final String? semanticLabel;

  const HoverOutline({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.glow = false,
    this.circle = false,
    this.radius = 8,
    this.padding = EdgeInsets.zero,
    this.color,
    this.accent = AppColors.accentGreen,
    this.idleBorderColor = Colors.transparent,
    this.tooltip,
    this.semanticLabel,
  });

  @override
  State<HoverOutline> createState() => _HoverOutlineState();
}

class _HoverOutlineState extends State<HoverOutline> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _hovered || _focused;
    final Color borderColor;
    List<BoxShadow>? shadow;
    if (_pressed || (widget.selected && !widget.glow)) {
      borderColor = widget.accent;
    } else if (widget.selected && widget.glow) {
      borderColor = widget.accent.withValues(alpha: highlighted ? 0.55 : 0.35);
      shadow = [BoxShadow(color: widget.accent.withValues(alpha: 0.14), blurRadius: 14, spreadRadius: 1)];
    } else if (highlighted) {
      borderColor = AppColors.hoverBorder;
    } else {
      borderColor = widget.idleBorderColor;
    }

    Widget box = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: shadow,
      ),
      child: widget.child,
    );

    final onTap = widget.onTap;
    if (onTap == null) return box;

    box = Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => _set(() => _focused = v),
        onShowHoverHighlight: (v) => _set(() => _hovered = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(() => _pressed = true),
          onTapUp: (_) => _set(() => _pressed = false),
          onTapCancel: () => _set(() => _pressed = false),
          onTap: onTap,
          child: box,
        ),
      ),
    );

    final tooltip = widget.tooltip;
    return tooltip == null ? box : Tooltip(message: tooltip, child: box);
  }
}

/// Standard labelled button built on [HoverOutline].
class SiteButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool selected;
  final bool large;
  final Color foreground;
  final Color accent;

  const SiteButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.large = false,
    this.foreground = AppColors.textPrimary,
    this.accent = AppColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : foreground;
    return HoverOutline(
      onTap: onTap,
      selected: selected,
      accent: accent,
      radius: large ? 12 : 8,
      color: AppColors.surface,
      idleBorderColor: AppColors.border,
      padding: EdgeInsets.symmetric(horizontal: large ? 22 : 14, vertical: large ? 16 : 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: large ? 22 : 18, color: color), SizedBox(width: large ? 10 : 8)],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamily,
                color: color,
                fontSize: large ? 17 : 14,
                fontWeight: large ? FontWeight.bold : FontWeight.w600,
                letterSpacing: large ? 1 : 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain text link with the same hover/press border.
class SiteLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SiteLink({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverOutline(
      onTap: onTap,
      radius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
