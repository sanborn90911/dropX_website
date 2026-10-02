import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final locale = LocaleController();
  await locale.init();
  runApp(DropXWebsite(locale: locale));
}

class DropXWebsite extends StatelessWidget {
  final LocaleController locale;

  const DropXWebsite({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dropX',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: Routes.home,
      onGenerateRoute: Routes.onGenerateRoute,
      // Open deep links (e.g. /download/linux) as a single page rather than
      // stacking every parent path underneath it.
      onGenerateInitialRoutes: (name) => [Routes.onGenerateRoute(RouteSettings(name: name))],
      builder: (context, child) => L10n(
        controller: locale,
        child: ListenableBuilder(
          listenable: locale,
          builder: (context, _) =>
              Directionality(textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
        ),
      ),
    );
  }
}
