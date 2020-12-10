import 'package:flutter_test/flutter_test.dart';

import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}

// テストする項目
// _SingleBanner
// // BannerAdをdisposeしたら、必ず、次をセットするかnullにする。
// 最後に広告を生成したインスタンスが所有権を持ち、そこからしかdisposeできない。
// 別のインスタンスが新たに広告生成を行った場合、所有権を失う。
// Navigator(またはRouteObserver)があっても正常に動く
// 同なくても正常に動く
// RouteObserverを与えずにNavigatorと一緒に使った場合に、わかりやすいエラーメッセージを出す
