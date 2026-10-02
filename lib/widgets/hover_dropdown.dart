import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'hover_outline.dart';

class DropdownEntry {
  final String label;
  final IconData? icon;
  final String? trailing;
  final bool selected;
  final VoidCallback? onSelected;
  final bool isHeader;

  const DropdownEntry({
    required this.label,
    required VoidCallback this.onSelected,
    this.icon,
    this.trailing,
    this.selected = false,
  }) : isHeader = false;

  const DropdownEntry.header(this.label)
    : icon = null,
      trailing = null,
      selected = false,
      onSelected = null,
      isHeader = true;
}

/// A header button that opens a menu below it. Opens on click, and also on
/// hover when [openOnHover] is set (a hover-opened menu closes again once
/// the pointer leaves both the button and the menu; clicking pins it open).
class HoverDropdown extends StatefulWidget {
  final Widget child;
  final List<DropdownEntry> entries;
  final bool openOnHover;
  final bool alignEnd;
  final double menuWidth;
  final String? tooltip;

  const HoverDropdown({
    super.key,
    required this.child,
    required this.entries,
    this.openOnHover = false,
    this.alignEnd = false,
    this.menuWidth = 220,
    this.tooltip,
  });

  @override
  State<HoverDropdown> createState() => _HoverDropdownState();
}

class _HoverDropdownState extends State<HoverDropdown> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _tapGroup = Object();
  Timer? _closeTimer;
  bool _openedByHover = false;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _open({required bool byHover}) {
    _closeTimer?.cancel();
    if (_portal.isShowing) return;
    _openedByHover = byHover;
    setState(_portal.show);
  }

  void _close() {
    _closeTimer?.cancel();
    if (!_portal.isShowing || !mounted) return;
    setState(_portal.hide);
  }

  void _scheduleClose() {
    if (!_openedByHover) return;
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 220), _close);
  }

  void _toggle() {
    if (!_portal.isShowing) {
      _open(byHover: false);
    } else if (_openedByHover) {
      _closeTimer?.cancel();
      _openedByHover = false;
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final atRight = widget.alignEnd != rtl;
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (_) => Positioned(
            width: widget.menuWidth,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: atRight ? Alignment.bottomRight : Alignment.bottomLeft,
              followerAnchor: atRight ? Alignment.topRight : Alignment.topLeft,
              offset: const Offset(0, 6),
              child: TapRegion(
                groupId: _tapGroup,
                child: MouseRegion(
                  onEnter: (_) => _closeTimer?.cancel(),
                  onExit: (_) => _scheduleClose(),
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: _Menu(entries: widget.entries, onPicked: _close),
                  ),
                ),
              ),
            ),
          ),
          child: MouseRegion(
            onEnter: widget.openOnHover ? (_) => _open(byHover: true) : null,
            onExit: (_) => _scheduleClose(),
            child: HoverOutline(
              onTap: _toggle,
              selected: _portal.isShowing,
              tooltip: widget.tooltip,
              color: AppColors.surface,
              idleBorderColor: AppColors.border,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final List<DropdownEntry> entries;
  final VoidCallback onPicked;

  const _Menu({required this.entries, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(6),
          children: [for (final e in entries) e.isHeader ? _header(e) : _item(e)],
        ),
      ),
    );
  }

  Widget _header(DropdownEntry e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Text(
        e.label.toUpperCase(),
        style: const TextStyle(
          fontFamily: kFontFamily,
          color: AppColors.textDisabled,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _item(DropdownEntry e) {
    final color = e.selected ? AppColors.accentGreen : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: HoverOutline(
        onTap: () {
          onPicked();
          e.onSelected!();
        },
        selected: e.selected,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            if (e.icon != null) ...[
              Icon(e.icon, size: 18, color: e.selected ? AppColors.accentGreen : AppColors.accentCyan),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                e.label,
                style: TextStyle(fontFamily: kFontFamily, color: color, fontSize: 14),
              ),
            ),
            if (e.trailing != null)
              Text(
                e.trailing!,
                style: const TextStyle(fontFamily: kFontFamily, color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
