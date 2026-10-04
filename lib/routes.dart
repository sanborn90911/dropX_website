import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/platforms.dart';
import 'pages/download_page.dart';
import 'pages/home_page.dart';
import 'pages/legal_page.dart';

class Routes {
  Routes._();

  static const String home = '/';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static String download(DeviceOs os) => '/download/${os.slug}';

  /// Same address as the app's `DistributionLinks.supportEmail` and the
  /// contact section of `web/legal.html`.
  static const String supportEmail = 'support@dropx.dev';

  static void goHome(BuildContext context) => Navigator.of(context).pushNamedAndRemoveUntil(home, (_) => false);

  static void go(BuildContext context, String route) => Navigator.of(context).pushNamed(route);

  /// The policy text lives in the static `web/legal.html` (readable without
  /// JavaScript, linkable from the app stores) rather than in Flutter widgets.
  /// Resolved against the document's `<base href>` so it also works when the
  /// site is hosted under a sub-path.
  static Uri legalUri(String section) => Uri.base.resolve('legal.html#$section');

  static Future<void> openLegal(String section) =>
      launchUrl(legalUri(section), webOnlyWindowName: '_self');

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final segments = Uri.parse(settings.name ?? home).pathSegments;
    final Widget page;
    switch (segments.isEmpty ? '' : segments.first) {
      case 'download':
        final os = DeviceOs.fromSlug(segments.length > 1 ? segments[1] : null) ?? DeviceOs.detect();
        page = DownloadPage(key: ValueKey(os), initialOs: os);
      case 'privacy':
        page = const LegalPage(titleKey: 'footer.privacy', section: 'privacy');
      case 'terms':
        page = const LegalPage(titleKey: 'footer.terms', section: 'terms');
      default:
        page = const HomePage();
    }
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
