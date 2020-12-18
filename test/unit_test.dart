import 'package:admob_banner_stabilizer/single_banner.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  SingleBanner singleBanner;
  setUp(() {
    // Note that SingleBanner is a singleton, so the same instance will be used for all test cases.
    singleBanner = SingleBanner(bannerAdConstructor: _mockBannerAdConstructor);
    singleBanner.show(
        callerHashCode: 12345678,
        adUnitId: null,
        size: null,
        anchorOffset: null,
        isMounted: null);
  });
  test('The last instance that generated the ad has ownership of it', () {
    expect(singleBanner.ownerHashCode, 12345678);
  });
  test('new bannerAd is set after calling show method', () {
    final old = singleBanner.bannerAd;
    expect(singleBanner.bannerAd == old, isTrue);
    singleBanner.show(
        callerHashCode: null,
        adUnitId: null,
        size: null,
        anchorOffset: null,
        isMounted: null);
    expect(singleBanner.bannerAd == old, isFalse);
  });
  test('bannerAd is null after SingleBanner is disposed', () {
    expect(singleBanner.bannerAd, isNotNull);
    singleBanner.dispose(callerHashCode: 12345678);
    expect(singleBanner.bannerAd, isNull);
  });
  test('Non-ownership instances cannot dispose of ads', () {
    expect(singleBanner.bannerAd, isNotNull);
    singleBanner.dispose(callerHashCode: 9999);
    expect(singleBanner.bannerAd, isNotNull);
  });
  test(
      'If another instance generates the ad, the previous owner loses ownership',
      () {
    expect(singleBanner.ownerHashCode, 12345678);
    singleBanner.show(
        callerHashCode: 8888,
        adUnitId: null,
        size: null,
        anchorOffset: null,
        isMounted: null);
    expect(singleBanner.ownerHashCode, 8888);
  });
}

class MockBannerAd extends Mock implements BannerAd {}

MockBannerAd _mockBannerAdConstructor({
  @required String adUnitId,
  @required AdSize size,
  MobileAdTargetingInfo targetingInfo,
  MobileAdListener listener,
}) {
  return MockBannerAd();
}
