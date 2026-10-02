import 'package:flutter/material.dart';

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

  static void goHome(BuildContext context) => Navigator.of(context).pushNamedAndRemoveUntil(home, (_) => false);

  static void go(BuildContext context, String route) => Navigator.of(context).pushNamed(route);

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final segments = Uri.parse(settings.name ?? home).pathSegments;
    final Widget page;
    switch (segments.isEmpty ? '' : segments.first) {
      case 'download':
        final os = DeviceOs.fromSlug(segments.length > 1 ? segments[1] : null) ?? DeviceOs.detect();
        page = DownloadPage(key: ValueKey(os), initialOs: os);
      case 'privacy':
        page = const LegalPage(titleKey: 'footer.privacy');
      case 'terms':
        page = const LegalPage(titleKey: 'footer.terms');
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
