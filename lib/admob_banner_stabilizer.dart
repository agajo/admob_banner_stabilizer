/// A package to use banner ads in firebase_admob package easily.
library admob_banner_stabilizer;

import 'dart:async';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';

// BannerAdを2回以上disposeしないためのクラス。
// Singletonにすることで、間接的にBannerAd自体のインスタンスも一度に一つしか存在しないことを保証する。
// BannerAdをdisposeしたら、必ず、次をセットするかnullにする。
class _SingleBanner {
  factory _SingleBanner() {
    _instance ??= _SingleBanner._internal();
    return _instance;
  }
  _SingleBanner._internal();
  static _SingleBanner _instance;

  BannerAd _bannerAd;
  int _ownerHashCode; // 現在の所有者インスタンスは誰かを表す

  void show({
    @required int callerHashCode,
    @required String adUnitId,
    @required AdSize size,
    @required double anchorOffset,
    @required bool isMounted,
  }) {
    _bannerAd?.dispose(); // disposeしたら、必ず、次をセットするかnullにする。
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      listener: (MobileAdEvent event) {
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

// Navigatorを使わない場合はこちらを使ってください
class AdMobBannerWidget extends StatefulWidget {
  // Stateを外から挿入できるようにしておきます。挿入されなければ、普通にここで新しく作る。
  // Route使うバージョンの方で、外からこのStateにアクセスできるようにするため。
  const AdMobBannerWidget({_AdMobBannerWidgetState admobBannerWidgetState})
      : _admobBannerWidgetState = admobBannerWidgetState;
  final _AdMobBannerWidgetState _admobBannerWidgetState;

  @override
  _AdMobBannerWidgetState createState() =>
      _admobBannerWidgetState ?? _AdMobBannerWidgetState();
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
    _timer = Timer.periodic(Duration(seconds: 1), (Timer _thisTimer) async {
      final RenderBox _renderBox = context.findRenderObject();
      final bool _isRendered = _renderBox.hasSize;
      if (_isRendered) {
        _SingleBanner().show(
          isMounted: mounted,
          anchorOffset: _anchorOffset(),
          // TODO: 各自の広告IDに変更する必要があります。
          adUnitId: BannerAd.testAdUnitId,
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
    final double _viewPaddingTop =
        WidgetsBinding.instance.window.viewPadding.top /
            MediaQuery.of(context).devicePixelRatio;
    final double _viewPaddingBottom =
        WidgetsBinding.instance.window.viewPadding.bottom /
            MediaQuery.of(context).devicePixelRatio;
    final double _screenWidth = MediaQuery.of(context).size.width;
    final double _availableScreenHeight = MediaQuery.of(context).size.height -
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
    final double _y = _renderBox.localToGlobal(Offset.zero).dy;
    final double _h = _renderBox.size.height;
    // viewPaddingだけ何故かMediaQueryで取得すると0だったので、windowから直接取得
    // 物理ピクセルが返るのでdevicePicelRatioで割って論理ピクセルに直す
    final double _vpb = WidgetsBinding.instance.window.viewPadding.bottom /
        MediaQuery.of(context).devicePixelRatio;
    final double _screenHeight = MediaQuery.of(context).size.height;
    return _screenHeight - _y - _h - _vpb;
  }

  @override
  Widget build(BuildContext context) {
    // 広告のスペースを確保するためのContainer。
    // TODO: 背景色を変えるなりSizedBoxにするなり、アプリに合わせて変更してください。
    return Container(height: _bannerHeight, color: Colors.yellow);
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
    _SingleBanner().dispose(callerHashCode: hashCode);
    _timer?.cancel();
  }
}

// Navigatorを使用する場合はこちらを使用してください。
class AdMobBannerWidgetWithRoute extends StatefulWidget {
  const AdMobBannerWidgetWithRoute();
  @override
  _AdMobBannerWidgetWithRouteState createState() =>
      _AdMobBannerWidgetWithRouteState();
}

class _AdMobBannerWidgetWithRouteState extends State<AdMobBannerWidgetWithRoute>
    with RouteAware {
  final _AdMobBannerWidgetState _admobBannerWidgetState =
      _AdMobBannerWidgetState();
  AdMobBannerWidget _admobBannerWidget;
  RouteObserver<dynamic> _routeObserver;

  @override
  void initState() {
    super.initState();
    _admobBannerWidget =
        AdMobBannerWidget(admobBannerWidgetState: _admobBannerWidgetState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Observerが一つじゃない場合、firstでいいのかどうか判断・変更する必要アリ
    _routeObserver = Navigator.of(context).widget.observers.first;
    _routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    assert(_routeObserver != null);
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    // AdmobBannerWidgetState経由で呼ばないと、
    // callerHashCodeに入るのがAdmobBannerWidgetWithRouteStateのものになり不整合
    _admobBannerWidgetState.disposeBanner();
    _admobBannerWidgetState.isTop = false;
  }

  @override
  void didPopNext() {
    _admobBannerWidgetState.isTop = true;
    _admobBannerWidgetState._determineBannerSize();
    _admobBannerWidgetState._loadAndShowBanner();
  }

  @override
  void didPop() {
    _admobBannerWidgetState.disposeBanner();
  }

  @override
  Widget build(BuildContext context) {
    return _admobBannerWidget;
  }
}
