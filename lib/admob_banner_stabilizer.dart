/// A package to use banner ads in firebase_admob package easily.
library admob_banner_stabilizer;

import 'dart:async';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';

// BannerAdを2回以上disposeしないためのクラス。
// Singletonにすることで、間接的にBannerAd自体のインスタンスも一度に一つしか存在しないことを保証する。
// BannerAdをdisposeしたら、必ず、次をセットするかnullにする。
class SingleBanner {
  factory SingleBanner() {
    return _instance ??= SingleBanner._internal();
  }
  SingleBanner._internal();
  static SingleBanner _instance;

  BannerAd _bannerAd;
  String bannerId;
  int _ownerHashCode; // 現在の所有者インスタンスは誰かを表す

  void show({
    @required int callerHashCode,
    @required AdSize size,
    @required double anchorOffset,
    @required bool isMounted,
  }) {
    assert(bannerId != null);
    _bannerAd?.dispose(); // disposeしたら、必ず、次をセットするかnullにする。
    _bannerAd = BannerAd(
      adUnitId: bannerId,
      size: size,
      listener: (event) {
        // loadが完了してからしかshowが呼ばれないようにリスナー登録
        // こうしないと、showを呼んでからロードが実際に完了するまでの間に画面が変化すると広告が消せなくなる
        if (event == MobileAdEvent.loaded) {
          if (isMounted) {
            _bannerAd.show(anchorOffset: anchorOffset);
          } else {
            _bannerAd = null;
          }
        }
      },
    );
    _ownerHashCode = callerHashCode;
    _bannerAd.load();
  }

  void dispose({@required int callerHashCode}) {
    // 最後に広告を生成したインスタンスが所有権を持ち、そこからしかdisposeできない。
    // 別のインスタンスが新たに広告生成を行った場合、所有権を失う。
    if (callerHashCode == _ownerHashCode) {
      _bannerAd?.dispose(); // disposeしたら、必ず、次をセットするかnullにする。
      _bannerAd = null;
    }
  }
}

// こちら単体では使わない
class AdMobBannerWidget extends StatefulWidget {
  // Stateを外から挿入できるようにしておきます。挿入されなければ、普通にここで新しく作る。
  // Route使うバージョンの方で、外からこのStateにアクセスできるようにするため。
  const AdMobBannerWidget(
      {_AdMobBannerWidgetState admobBannerWidgetState,
      @required SingleBanner singleBanner})
      : _adMobBannerWidgetState = admobBannerWidgetState,
        _singleBanner = singleBanner;
  final _AdMobBannerWidgetState _adMobBannerWidgetState;
  final SingleBanner _singleBanner;

  @override
  _AdMobBannerWidgetState createState() =>
      _adMobBannerWidgetState ?? _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  Timer _timer;
  double _bannerHeight;
  AdSize _adSize;
  // Navigatorスタックの最上位にいるのかどうかを示すフラグ
  bool isTop = true;

  void _loadAndShowBanner() {
    assert(_bannerHeight != null);
    assert(_adSize != null);
    _timer?.cancel();
    // Widgetのレンダリングが完了してなければ位置がわからないので、広告を表示しません。
    // レンダリングが完了するまでタイマーで繰り返します。
    _timer = Timer.periodic(const Duration(seconds: 1), (_thisTimer) async {
      final _renderBox = context.findRenderObject() as RenderBox;
      final _isRendered = _renderBox.hasSize;
      if (_isRendered) {
        widget._singleBanner.show(
          isMounted: mounted,
          anchorOffset: _anchorOffset(),
          callerHashCode: hashCode,
          size: _adSize,
        );
        _thisTimer.cancel();
      }
    });
  }

  // ノッチとかを除いた範囲(SafeArea)の縦幅の1/8以内で最大の広告を表示します。
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
    final _renderBox = context.findRenderObject() as RenderBox;
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
    // 広告のスペースを確保するためのContainer。
    return SizedBox(height: _bannerHeight);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQueryの変化を受けて呼ばれる。pushやpop、本体の回転でも呼ばれる。
    // 変更を検知したらまず即座に広告を消す。
    disposeBanner();
    if (isTop) {
      _determineBannerSize();
      _loadAndShowBanner();
    }
  }

  @override
  void dispose() {
    disposeBanner();
    super.dispose();
  }

  void disposeBanner() {
    widget._singleBanner.dispose(callerHashCode: hashCode);
    _timer?.cancel();
  }
}

// Navigatorを使用する場合はこちらを使用してください。
class AdMobBannerWidgetWithRoute extends StatefulWidget {
  // SingleBannerのモックを受け取ればそれを使い、受け取らなければ勝手にSingleBannerを生成します。
  // 本番では何も渡さなくてよい。
  AdMobBannerWidgetWithRoute({SingleBanner singleBanner, String bannerId})
      : _singleBanner = singleBanner ?? SingleBanner() {
    _singleBanner.bannerId = bannerId;
  }
  final SingleBanner _singleBanner;
  @override
  _AdMobBannerWidgetWithRouteState createState() =>
      _AdMobBannerWidgetWithRouteState();
}

class _AdMobBannerWidgetWithRouteState extends State<AdMobBannerWidgetWithRoute>
    with RouteAware {
  final _AdMobBannerWidgetState _adMobBannerWidgetState =
      _AdMobBannerWidgetState();
  AdMobBannerWidget _adMobBannerWidget;
  RouteObserver<dynamic> _routeObserver;

  @override
  void initState() {
    super.initState();
    _adMobBannerWidget = AdMobBannerWidget(
      admobBannerWidgetState: _adMobBannerWidgetState,
      singleBanner: widget._singleBanner,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Observerが一つじゃない場合、firstでいいのかどうか判断・変更する必要アリ
    _routeObserver = Navigator.of(context).widget.observers.first
        as RouteObserver
      ..subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    assert(_routeObserver != null);
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    // AdMobBannerWidgetState経由で呼ばないと、
    // callerHashCodeに入るのがAdMobBannerWidgetWithRouteStateのものになり不整合
    _adMobBannerWidgetState
      ..disposeBanner()
      ..isTop = false;
  }

  @override
  void didPopNext() {
    _adMobBannerWidgetState
      ..isTop = true
      .._determineBannerSize()
      .._loadAndShowBanner();
  }

  @override
  void didPop() {
    _adMobBannerWidgetState.disposeBanner();
  }

  @override
  Widget build(BuildContext context) {
    return _adMobBannerWidget;
  }
}

class EmptyAdMobBannerWidget extends StatelessWidget {
  const EmptyAdMobBannerWidget();
  @override
  Widget build(BuildContext context) {
    double _bannerHeight;
    // ノッチとかを除いた範囲(SafeArea)の縦幅の1/8以内で最大の広告を表示します。
    // 広告の縦幅を明確にしたいのでSmartBannerは使いません。
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
      _bannerHeight = 90;
    } else if (_screenWidth >= 468 && _availableScreenHeight >= 480) {
      _bannerHeight = 60;
    } else if (_screenWidth >= 320 && _availableScreenHeight >= 800) {
      _bannerHeight = 100;
    } else {
      _bannerHeight = 50;
    }

    return SizedBox(height: _bannerHeight);
  }
}
