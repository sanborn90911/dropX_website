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
        find.ancestor(of: find.text('Help & Support'), matching: find.byType(Container)).first,
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
    addTearDown(() => debugDefaultTargetPlatformOverride = null); // reset even if an expectation fails
    await _pumpSite(tester, const Size(1600, 900));
    await tester.tap(find.textContaining('Download for Windows'));
    await tester.pumpAndSettle();
    expect(find.text('PowerShell Commands (Internet Required)'), findsOneWidget);
    // Install commands are placeholders for now: just "Coming soon" under the heading.
    expect(find.textContaining('winget'), findsNothing);
    expect(find.text('Coming soon'), findsOneWidget); // the commands panel (the footer shows the support email now)

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

  testWidgets('screenshots and feature boxes change one at a time, in order, never together', (tester) async {
    await _pumpSite(tester, const Size(1920, 3000));

    bool showing(String asset) => find
        .byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == asset)
        .evaluate()
        .isNotEmpty;
    // Which of a feature box's two items is the visible one (opacity 1)?
    int? featureShown(int box) {
      for (var i = 0; i < 2; i++) {
        final fade = tester.widget<FadeTransition>(find.byKey(ValueKey('feature-$box-item-$i')));
        if (fade.opacity.value > 0.99) return i;
      }
      return null; // mid-change
    }

    // Page time in ms (the initial settle already took 100ms). Pump in 100ms
    // frames like a real browser does, so fades start and end on time.
    var now = 100;
    Future<void> at(int ms) async {
      while (now < ms) {
        await tester.pump(const Duration(milliseconds: 100));
        now += 100;
      }
      await tester.pump(); // a finished fade drops the old image one frame later
    }

    expect(find.byIcon(Icons.chevron_left), findsNothing); // dots are the only control
    expect([for (var b = 0; b < 4; b++) featureShown(b)], [0, 0, 0, 0]);

    // A turn every 2.4s from 1.0s: desktop left, phone right, box 0, box 3,
    // desktop right, phone left, box 1, box 2, phone centre. Each is checked
    // after its 1.4s fade, with the not-yet-started ones still untouched.
    await at(2500); // turn 1 (1.0s) finished: desktop left 1 → 2
    expect(showing('assets/screenshots/desktop/1.jpg'), isFalse);
    expect(showing('assets/screenshots/mobile/6.png'), isFalse, reason: 'phone right waits until 3.4s');

    await at(4900); // turn 2 (3.4s) finished: phone right 5 → 6
    expect(showing('assets/screenshots/mobile/6.png'), isTrue);
    expect(featureShown(0), 0, reason: 'box 0 waits until 5.8s');

    await at(7300); // turn 3 (5.8s) finished: box 0 flips, its diagonal box 3 hasn't
    expect(featureShown(0), 1);
    expect(featureShown(3), 0, reason: 'box 3 waits until 8.2s');

    await at(9700); // turn 4 (8.2s): box 3 flips
    expect(featureShown(3), 1);
    expect(showing('assets/screenshots/desktop/3.jpg'), isFalse, reason: 'desktop right waits until 10.6s');

    await at(12100); // turn 5 (10.6s): desktop right 2 → 3
    expect(showing('assets/screenshots/desktop/3.jpg'), isTrue);

    await at(14500); // turn 6 (13.0s): phone left 1 → 2
    expect(showing('assets/screenshots/mobile/2.png'), isTrue);
    expect(featureShown(1), 0, reason: 'box 1 waits until 15.4s');

    await at(16900); // turn 7 (15.4s): box 1 flips
    expect(featureShown(1), 1);
    expect(featureShown(2), 0, reason: 'box 2 waits until 17.8s');

    await at(19300); // turn 8 (17.8s): box 2 flips
    expect(featureShown(2), 1);
    expect(showing('assets/screenshots/mobile/4.png'), isFalse, reason: 'phone centre waits until 20.2s');

    await at(21700); // turn 9 (20.2s): phone centre 3 → 4
    expect(showing('assets/screenshots/mobile/4.png'), isTrue);
  });

  testWidgets('feature boxes: 2 columns × 2 boxes, each with its own smaller cyan selector', (tester) async {
    await _pumpSite(tester, const Size(1600, 3000));

    // Two columns of two boxes: left boxes share a x, right boxes share another,
    // and each box sits directly below its column mate.
    final topLeft = tester.getTopLeft(find.byKey(const ValueKey('feature-box-0')));
    final bottomLeft = tester.getTopLeft(find.byKey(const ValueKey('feature-box-1')));
    final topRight = tester.getTopLeft(find.byKey(const ValueKey('feature-box-2')));
    final bottomRight = tester.getTopLeft(find.byKey(const ValueKey('feature-box-3')));
    expect(bottomLeft.dx, topLeft.dx);
    expect(bottomRight.dx, topRight.dx);
    expect(topRight.dx, greaterThan(topLeft.dx));
    expect(bottomLeft.dy, greaterThan(topLeft.dy));
    expect(bottomRight.dy, bottomLeft.dy);

    // All eight features are present, two per box, with two selector dots each.
    for (final title in [
      'Cross-platform',
      'Any File Type',
      'No Internet Required',
      'Wi-Fi or Hotspot',
      'Private & Direct',
      'Peer Authentication',
      'Verified Transfers',
      'No Chunk Left Behind',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    for (var b = 0; b < 4; b++) {
      expect(find.byKey(ValueKey('feature-dot-$b-0')), findsOneWidget);
      expect(find.byKey(ValueKey('feature-dot-$b-1')), findsOneWidget);
    }

    // The feature selector is clearly smaller than the screenshot one.
    final featureDot = tester.getSize(find.byKey(const ValueKey('feature-dot-0-0')));
    final imageDot = tester.getSize(find.byKey(const ValueKey('slide-dot-0')).first);
    expect(featureDot.width, lessThan(imageDot.width * 0.75));
    expect(featureDot.height, lessThan(imageDot.height));

    // Clicking a dot shows that feature, and the box keeps its height.
    final before = tester.getSize(find.byKey(const ValueKey('feature-box-1')));
    await tester.tap(find.byKey(const ValueKey('feature-dot-1-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    final fade = tester.widget<FadeTransition>(find.byKey(const ValueKey('feature-1-item-1')));
    expect(fade.opacity.value, 1);
    expect(tester.getSize(find.byKey(const ValueKey('feature-box-1'))), before);
  });

  testWidgets('feature boxes stack in one column on a phone', (tester) async {
    await _pumpSite(tester, const Size(390, 2400));
    final xs = [for (var b = 0; b < 4; b++) tester.getTopLeft(find.byKey(ValueKey('feature-box-$b'))).dx];
    expect(xs.toSet().length, 1);
    final ys = [for (var b = 0; b < 4; b++) tester.getTopLeft(find.byKey(ValueKey('feature-box-$b'))).dy];
    expect(ys, [...ys]..sort());
  });

  testWidgets('clicking a screenshot opens it full-size; the viewer can switch images and close', (tester) async {
    await _pumpSite(tester, const Size(1920, 2400));
    Finder image(String asset) => find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == asset,
    );

    // Open desktop window 1 before its first scheduled change.
    await tester.tap(image('assets/screenshots/desktop/1.jpg').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('viewer-close')), findsOneWidget);

    // Its turn (1s) passes while the viewer is open: the window must not change underneath.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(image('assets/screenshots/desktop/1.jpg'), findsNWidgets(2)); // viewer + window

    // Switch to the second image inside the viewer, then close with the ✕.
    await tester.tap(find.byKey(const ValueKey('viewer-dot-1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('viewer-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('viewer-close')), findsNothing);

    // The window now shows the image the visitor ended on.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(image('assets/screenshots/desktop/1.jpg'), findsNothing);
    expect(image('assets/screenshots/desktop/2.jpg'), findsNWidgets(2)); // window 1 (now) + window 2
  });
}
