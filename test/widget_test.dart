import 'package:dropx_website/l10n/l10n.dart';
import 'package:dropx_website/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSite(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final locale = LocaleController();
  await tester.runAsync(locale.init);
  await tester.pumpWidget(DropXWebsite(locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('help button pulses a border around Help & Support, even with nothing to scroll', (tester) async {
    await _pumpSite(tester, const Size(1600, 2400));
    expect(find.text('Cross-platform file sharing with ease'), findsOneWidget);
    expect(find.text('Run in Web Browser'), findsNothing);

    Color borderColor() {
      final box = tester.widget<Container>(
        find.ancestor(of: find.text('Coming soon'), matching: find.byType(Container)).first,
      );
      return ((box.decoration! as BoxDecoration).border! as Border).top.color;
    }

    expect(borderColor().a, 0);
    await tester.tap(find.text('?'));
    await tester.pump(); // scroll completes, pulse starts
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // into the pulse
    expect(borderColor().a, greaterThan(0.5));
    await tester.pumpAndSettle();
    expect(borderColor().a, 0);
  });

  testWidgets('homepage renders on mobile and body Download opens the download page', (tester) async {
    await _pumpSite(tester, const Size(390, 844));
    await tester.tap(find.textContaining('Download for'));
    await tester.pumpAndSettle();
    expect(find.text('Download dropX'), findsOneWidget);
    // flutter_test reports Android as the host platform, so it's auto-selected.
    expect(find.text('Under testing - Coming soon'), findsOneWidget);
  });

  testWidgets('download page lists platforms in order and labels commands per OS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await _pumpSite(tester, const Size(1600, 900));
    await tester.tap(find.textContaining('Download for Windows'));
    await tester.pumpAndSettle();
    expect(find.text('PowerShell Commands (Internet Required)'), findsOneWidget);
    // Install commands are placeholders for now: just "Coming soon" under the heading.
    expect(find.textContaining('winget'), findsNothing);
    expect(find.text('Coming soon'), findsNWidgets(2)); // commands panel + footer

    final order = [
      'Android',
      'iOS',
      'macOS',
      'Windows',
      'Linux',
    ].map((label) => tester.getTopLeft(find.text(label).last).dy).toList();
    expect(order, [...order]..sort());

    await tester.tap(find.text('Linux').last);
    await tester.pumpAndSettle();
    expect(find.text('Terminal Commands (Internet Required)'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('screenshots change one at a time in diagonal pairs, then the centre phone', (tester) async {
    await _pumpSite(tester, const Size(1920, 2400));

    bool showing(String asset) => find
        .byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == asset)
        .evaluate()
        .isNotEmpty;
    Future<void> at(int ms, int previousMs) => tester.pump(Duration(milliseconds: ms - previousMs));

    expect(find.byIcon(Icons.chevron_left), findsNothing); // dots are the only control

    // 3.0s: desktop left (1 → 2), fade ends at 4.4s.
    await at(3100, 0);
    await at(4700, 3100);
    expect(showing('assets/screenshots/desktop/1.jpg'), isFalse);
    expect(showing('assets/screenshots/mobile/6.png'), isFalse, reason: 'phone right waits 1s after the fade');

    // 5.4s: phone right, diagonal to desktop left (5 → 6).
    await at(5500, 4700);
    expect(showing('assets/screenshots/mobile/6.png'), isTrue);
    await at(7000, 5500);
    expect(showing('assets/screenshots/desktop/3.jpg'), isFalse, reason: 'desktop right waits until 8.8s');

    // 8.8s: desktop right (2 → 3); 11.2s: phone left, diagonal to it (1 → 2).
    await at(8900, 7000);
    expect(showing('assets/screenshots/desktop/3.jpg'), isTrue);
    expect(showing('assets/screenshots/mobile/2.png'), isFalse);
    await at(11300, 8900);
    expect(showing('assets/screenshots/mobile/2.png'), isTrue);
    expect(showing('assets/screenshots/mobile/4.png'), isFalse, reason: 'centre phone waits until 14.6s');

    // 14.6s: centre phone on its own (3 → 4).
    await at(14700, 11300);
    expect(showing('assets/screenshots/mobile/4.png'), isTrue);

    // First dot of desktop left brings screenshot 1 back.
    await tester.tap(find.byKey(const ValueKey('slide-dot-0')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(showing('assets/screenshots/desktop/1.jpg'), isTrue);
  });
}
