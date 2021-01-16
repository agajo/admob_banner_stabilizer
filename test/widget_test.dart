import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

void main() {
  testWidgets('works without Navigator', (WidgetTester tester) async {
    final adMobBannerWidget = AdMobBannerWidget(adUnitId: null);
    await tester.pumpWidget(MaterialApp(home: adMobBannerWidget));
    expect(find.byWidget(adMobBannerWidget), findsOneWidget);
  });

  testWidgets('works with Navigator', (WidgetTester tester) async {
    final adMobBannerWidget = AdMobBannerWidget(adUnitId: null);
    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        observers: [RouteObserver()],
        pages: [MaterialPage(child: adMobBannerWidget)],
        onPopPage: (route, result) => route.didPop(result),
      ),
    ));
    expect(find.byWidget(adMobBannerWidget), findsOneWidget);
  });

  // This test case does not work. Please tell me how to make it work.
  testWidgets('throws if using with Navigator without RouteObserver',
      (WidgetTester tester) async {
    final adMobBannerWidget = AdMobBannerWidget(adUnitId: null);
    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        // no observers here
        pages: [MaterialPage(child: adMobBannerWidget)],
        onPopPage: (route, result) => route.didPop(result),
      ),
    ));
    // await tester.pumpAndSettle();
    expect(tester.takeException(), isInstanceOf<StateError>());
  }, skip: true);

  // This test case does not work because there is no easy way to get its size from the Widget.
  // Please tell me how to make it work.
  testWidgets('specify maxHeight', (WidgetTester tester) async {
    final adMobBannerWidget = AdMobBannerWidget(
      adUnitId: null,
      maxHeight: 80,
    );
    await tester.pumpWidget(MaterialApp(home: adMobBannerWidget));
    expect(find.byWidget(adMobBannerWidget), findsOneWidget);
  }, skip: true);
}
