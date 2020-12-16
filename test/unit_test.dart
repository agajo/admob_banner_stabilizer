import 'package:flutter_test/flutter_test.dart';

import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

void main() {
  group('SingleBanner', () {
    SingleBanner singleBanner;
    setUp(() {
      singleBanner = SingleBanner();
    });
    test('adBanner is null after SingleBanner is disposed', () {});
    test('new adBanner is set after calling show method', () {});
    test('The last instance that generated the ad has ownership of it', () {});
    test('Non-ownership instances cannot dispose of ads', () {});
    test(
        'If another instance generates the ad, the previous owner loses ownership',
        () {});
  });
}
