import 'package:flutter_test/flutter_test.dart';

import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

void main() {
  testWidgets('works without Navigator', (WidgetTester tester) async {});
  testWidgets('works with Navigator', (WidgetTester tester) async {});
  testWidgets('throws if using with Navigator without RouteObserver',
      (WidgetTester tester) async {});
}

// テストする項目
// Navigator(またはRouteObserver)があっても正常に動く
// 同なくても正常に動く
// RouteObserverを与えずにNavigatorと一緒に使った場合に、わかりやすいエラーメッセージを出す
