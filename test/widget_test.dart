import 'package:firebase_admob/firebase_admob.dart';
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

  testWidgets('about getAdSize and getBannerHeight static methods',
      (WidgetTester tester) async {
    AdSize _adSize;
    double _bannerHeight;
    Widget myWidget(Size size, double maxHeight) {
      return MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            _adSize = AdMobBannerWidget.getAdSize(
                context: context, maxHeight: maxHeight);
            _bannerHeight = AdMobBannerWidget.getBannerHeight(
                context: context, maxHeight: maxHeight);
            return Container();
          },
        ),
      ));
    }

    await tester.pumpWidget(myWidget(Size(25, 1000), null));
    expect(_bannerHeight, equals(50));
    expect(_adSize, equals(AdSize.banner));
    await tester.pumpWidget(myWidget(Size(728, 720), null));
    expect(_bannerHeight, equals(90));
    expect(_adSize, equals(AdSize.leaderboard));
    await tester.pumpWidget(myWidget(Size(468, 480), null));
    expect(_bannerHeight, equals(60));
    expect(_adSize, equals(AdSize.fullBanner));
    await tester.pumpWidget(myWidget(Size(320, 800), null));
    expect(_bannerHeight, equals(100));
    expect(_adSize, equals(AdSize.largeBanner));
    await tester.pumpWidget(myWidget(Size(1000, 1000), 50));
    expect(_bannerHeight, equals(50));
    expect(_adSize, equals(AdSize.banner));
    await tester.pumpWidget(myWidget(Size(1000, 1000), 49));
    expect(tester.takeException(), isInstanceOf<StateError>());
  });
}
