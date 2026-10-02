import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'site_footer.dart';
import 'site_header.dart';

/// Shared page shell: fixed header + divider, then scrollable page content,
/// divider and the Help & Support footer.
class SiteScaffold extends StatefulWidget {
  final bool isHome;
  final Widget child;

  /// Widest the page content may grow. Pages default to a 1180px column;
  /// the homepage widens it so its screenshots can be larger on desktop.
  final double maxContentWidth;

  const SiteScaffold({super.key, this.isHome = false, this.maxContentWidth = kContentWidth, required this.child});

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _footerKey = GlobalKey();
  final _highlightFooter = ValueNotifier<int>(0);

  @override
  void dispose() {
    _highlightFooter.dispose();
    super.dispose();
  }

  /// Scrolls to Help & Support, then pulses its border. The pulse also
  /// covers pages with nothing to scroll, where the click would otherwise
  /// look like it did nothing.
  Future<void> _scrollToFooter() async {
    final target = _footerKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    if (!mounted) return;
    _highlightFooter.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SiteHeader(isHome: widget.isHome, onHelp: _scrollToFooter),
            const SiteDivider(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    // Keeps the footer pinned to the bottom on short pages.
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: widget.child),
                          ),
                        ),
                        Column(
                          key: _footerKey,
                          children: [
                            const SiteDivider(),
                            SiteFooter(highlightTrigger: _highlightFooter),
                          ],
                        ),
                      ],
                    ),
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

/// Default max width of page content.
const double kContentWidth = 1180;

/// Low-strength horizontal rule used under the header and above the footer.
class SiteDivider extends StatelessWidget {
  const SiteDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider);
  }
}
