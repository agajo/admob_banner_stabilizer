/// A package to use banner ads in firebase_admob package easily.
library admob_banner_stabilizer;

import 'dart:async';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/widgets.dart';

import 'single_banner.dart';

// Navigatorを使わない場合はこちらを使ってください
class AdMobBannerWidget extends StatefulWidget {
  // UniqueKeyをもたせることで強制的にリビルドさせて、Widgetの状態の変化に広告を追従させます。
  // keyを持たせてリビルドを防いだ場合、広告がWidgetに追従しないことがあるので注意してください。
  AdMobBannerWidget({@required this.adUnitId, this.backgroundColor, Key key})
      : super(key: key ?? UniqueKey());

  final String adUnitId;
  final Color backgroundColor;

  @override
  _AdMobBannerWidgetState createState() =>
      //_admobBannerWidgetState ?? _AdMobBannerWidgetState();
      _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> with RouteAware {
  double _bannerHeight;
  AdSize _adSize;
  bool _doShowAd = false;
  Timer _timer;

  // 広告のロードと表示を実行します。実行してよいかの判断はここではしません。
  void _loadAndShowBanner() {
    assert(_bannerHeight != null);
    assert(_adSize != null);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // 画面遷移アニメーションがある場合に備え、物理的に1秒待ちます。
      _timer = Timer(Duration(seconds: 1), () {
        final RenderBox _renderBox = context.findRenderObject();
        final _isRendered = _renderBox.hasSize;
        if (_isRendered) {
          SingleBanner().show(
            isMounted: mounted,
            anchorOffset: _anchorOffset(),
            adUnitId: widget.adUnitId,
            callerHashCode: hashCode,
            size: _adSize,
          );
        }
      });
    });
  }

  void _refreshState() {
    _disposeBanner();
    _determineBannerSize();
    if (ModalRoute.of(context) == null || ModalRoute.of(context).isCurrent) {
      _doShowAd = true;
    } else {
      _doShowAd = false;
    }
  }

  // ノッチとかを除いた範囲(SafeArea)の縦幅の1/8以内で最大の広告を選びます。
  // 広告の縦幅を明確にしたいのでSmartBannerは使いません。
  void _determineBannerSize() {
    final _viewPaddingTop = WidgetsBinding.instance.window.viewPadding.top /
        MediaQuery.of(context).devicePixelRatio;
    final _viewPaddingBottom =
        WidgetsBinding.instance.window.viewPadding.bottom /
            MediaQuery.of(context).devicePixelRatio;
    final _screenWidth = MediaQuery.of(context).size.width;
    final _availableScreenHeight = MediaQuery.of(context).size.height -
        _viewPaddingTop -
        _viewPaddingBottom;
    if (_screenWidth >= 728 && _availableScreenHeight >= 720) {
      _adSize = AdSize.leaderboard;
      _bannerHeight = 90;
    } else if (_screenWidth >= 468 && _availableScreenHeight >= 480) {
      _adSize = AdSize.fullBanner;
      _bannerHeight = 60;
    } else if (_screenWidth >= 320 && _availableScreenHeight >= 800) {
      _adSize = AdSize.largeBanner;
      _bannerHeight = 100;
    } else {
      _adSize = AdSize.banner;
      _bannerHeight = 50;
    }
  }

  // ノッチとかを除いた範囲(SafeArea)の下端を基準に、
  // このWidgetが論理ピクセルいくつ分だけ上に表示されているか計算します
  double _anchorOffset() {
    final RenderBox _renderBox = context.findRenderObject();
    assert(_renderBox.hasSize);
    final _y = _renderBox.localToGlobal(Offset.zero).dy;
    final _h = _renderBox.size.height;
    // viewPaddingだけ何故かMediaQueryで取得すると0だったので、windowから直接取得
    // 物理ピクセルが返るのでdevicePixelRatioで割って論理ピクセルに直す
    final _vpb = WidgetsBinding.instance.window.viewPadding.bottom /
        MediaQuery.of(context).devicePixelRatio;
    final _screenHeight = MediaQuery.of(context).size.height;
    return _screenHeight - _y - _h - _vpb;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: refreshっていうメソッドを作り、そいつが状況取得・広告サイズや出すかどうかの判断・実際に出すまですべてやる。…?
    // エレメント再生成のリビルドとの二重になっちゃうな。一本化してシンプルにしたい。とにかく理解をシンプルにしたい。
    // 状況取得・サイズ・出すかどうかの判断 まではrefreshState() でやる。
    // 実際に出すのをここでやる。
    // 広告のスペースを確保するためのContainer。
    if (_doShowAd) {
      _loadAndShowBanner();
    }
    return Container(height: _bannerHeight, color: widget.backgroundColor);
  }

  @override
  void didChangeDependencies() {
    // MediaQueryの変化を受けて呼ばれる。pushやpop、本体の回転でも呼ばれる。
    // 変更を検知したらまず即座に広告を消す。
    // _disposeBanner();
    final _route = ModalRoute.of(context);
    if (_route != null &&
        // If _route is MaterialApp's default route, it doesn't throw.
        !(_route.settings.name == '/' && _route.settings.arguments == null) &&
        Navigator.of(context).widget.observers.isEmpty) {
      throw StateError(
          'Give an RouteObserver when using AdMobBannerWidget with Navigator.');
      // assert(false,
      //     'Give an RouteObserver when using AdMobBannerWidget with Navigator.');
    }
    // Observerが一つじゃない場合、firstでいいのかどうか判断・変更する必要アリ
    if (_route != null && Navigator.of(context).widget.observers.isNotEmpty) {
      _routeObserver = Navigator.of(context).widget.observers.first;
      _routeObserver.subscribe(this, _route);
    }
    _refreshState();
    // if (isTop) {
    // _determineBannerSize();
    // _loadAndShowBanner();
    // }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _disposeBanner();
    _routeObserver?.unsubscribe(this);
    _timer.cancel();
    super.dispose();
  }

  void _disposeBanner() {
    _timer?.cancel();
    SingleBanner().dispose(callerHashCode: hashCode);
  }

// }
//
// // Navigatorを使用する場合はこちらを使用してください。
// class AdMobBannerWidgetWithRoute extends StatefulWidget {
//   const AdMobBannerWidgetWithRoute();
//   @override
//   _AdMobBannerWidgetWithRouteState createState() =>
//       _AdMobBannerWidgetWithRouteState();
// }
//
// class _AdMobBannerWidgetWithRouteState extends State<AdMobBannerWidgetWithRoute>
//     with RouteAware {
//   final _AdMobBannerWidgetState _admobBannerWidgetState =
//       _AdMobBannerWidgetState();
//   AdMobBannerWidget _admobBannerWidget;
  RouteObserver<dynamic> _routeObserver;

  // @override
  // void initState() {
  //   super.initState();
  //   // _admobBannerWidget =
  //   //     AdMobBannerWidget(admobBannerWidgetState: _admobBannerWidgetState);
  // }

  @override
  void didPushNext() {
    // AdmobBannerWidgetState経由で呼ばないと、
    // callerHashCodeに入るのがAdmobBannerWidgetWithRouteStateのものになり不整合
    // disposeBanner();
    // isTop = false;
    setState(() {
      _refreshState();
    });
  }

  @override
  void didPopNext() {
    // isTop = true;
    // _determineBannerSize();
    // _loadAndShowBanner();
    setState(() {
      _refreshState();
    });
  }

  @override
  void didPop() {
    // disposeBanner();
    setState(() {
      _refreshState();
    });
  }
}
