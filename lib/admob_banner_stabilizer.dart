/// A package to use banner ads in firebase_admob package easily.
library admob_banner_stabilizer;

import 'dart:async';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/widgets.dart';

/// The main Widget for displaying banner ads. Place this Widget where you want to display the banner ad.
class AdMobBannerWidget extends StatefulWidget {
  // By forcing a rebuild with a UniqueKey, the ad will follow the changes in the widget state.
  // Note that if you prevent the rebuild by giving a different key, the ad may not follow the widget.
  AdMobBannerWidget({
    /// Your ID of banner ad unit from AdMob.
    @required this.adUnitId,

    /// Background color of banner area. Default is transparent.
    this.backgroundColor,
    Key key,
  }) : super(key: key ?? UniqueKey());

  /// Your ID of banner ad unit from AdMob.
  final String adUnitId;

  /// Background color of banner area. Default is transparent.
  final Color backgroundColor;

  @override
  _AdMobBannerWidgetState createState() =>
      //_admobBannerWidgetState ?? _AdMobBannerWidgetState();
      _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> with RouteAware {
  /// The height of the banner ad.
  double _bannerHeight;

  /// The size of the banner ad. AdSize is defined in the firebase_admob plugin.
  AdSize _adSize;

  /// If this is true, this Widget shows the banner ad.
  bool _doShowAd = false;

  /// The timer to show banner ad. This timer is used to delay the display of ads in case there is a screen transition animation.
  Timer _timer;

  /// Loads and shows the banner ad.
  void _loadAndShowBanner() {
    assert(_bannerHeight != null);
    assert(_adSize != null);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // This timer is used to delay the display of ads in case there is a screen transition animation.
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

  /// This method is used to recalculate the position and size of the widget when the widget environment changes.
  void _refreshState() {
    _disposeBanner();
    _determineBannerSize();
    if (ModalRoute.of(context) == null || ModalRoute.of(context).isCurrent) {
      _doShowAd = true;
    } else {
      _doShowAd = false;
    }
  }

  /// Chooses the largest ad within 1/8th of the height of the SafeArea, which is the area excluding notches and such.
  /// To clarify the height of the ad, SmartBanner is not used.
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

  /// Calculates how many logical pixels above the bottom of the SafeArea this Widget is displayed.
  double _anchorOffset() {
    final RenderBox _renderBox = context.findRenderObject();
    assert(_renderBox.hasSize);
    final _y = _renderBox.localToGlobal(Offset.zero).dy;
    final _h = _renderBox.size.height;
    // Only the viewPadding was 0 when I used MediaQuery to get it, so I got it directly from the window.
    // Since it returns physical pixels, divide it by the devicePixelRatio to convert it to logical pixels.
    final _vpb = WidgetsBinding.instance.window.viewPadding.bottom /
        MediaQuery.of(context).devicePixelRatio;
    final _screenHeight = MediaQuery.of(context).size.height;
    return _screenHeight - _y - _h - _vpb;
  }

  @override
  Widget build(BuildContext context) {
    if (_doShowAd) {
      _loadAndShowBanner();
    }
    return Container(height: _bannerHeight, color: widget.backgroundColor);
  }

  @override
  void didChangeDependencies() {
    final _route = ModalRoute.of(context);
    if (_route != null &&
        // If _route is MaterialApp's default route, it doesn't throw.
        !(_route.settings.name == '/' && _route.settings.arguments == null) &&
        Navigator.of(context).widget.observers.isEmpty) {
      throw StateError(
          'Give an RouteObserver when using AdMobBannerWidget with Navigator.');
    }
    if (_route != null && Navigator.of(context).widget.observers.isNotEmpty) {
      // If there is more than one Observer, we may need to determine if first is okay and change the code
      _routeObserver = Navigator.of(context).widget.observers.first;
      _routeObserver.subscribe(this, _route);
    }
    _refreshState();
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

  RouteObserver<dynamic> _routeObserver;

  @override
  void didPushNext() {
    setState(() {
      _refreshState();
    });
  }

  @override
  void didPopNext() {
    setState(() {
      _refreshState();
    });
  }

  @override
  void didPop() {
    setState(() {
      _refreshState();
    });
  }
}

/// A wrapper for BannerAd.
/// It could be called AdMobBannerRepository.
///
/// BannerAd triggers an error if you dispose it more than once, but there is no way to check if it has already been disposed.
///
/// This is a class to ensure that BannerAd is not disposed more than once.
/// Being a Singleton, it also ensures that there is only one instance of BannerAd at a time.
/// The instance that generated the ad is recorded, and no other instance can dispose the ad.
///
/// When a BannerAd is disposed of, it is immediately discarded and the next instance is set or nulled. This prevents BannerAd from being disposed of more than once.
class SingleBanner {
  /// Factory constructor
  factory SingleBanner({
    BannerAdConstructor bannerAdConstructor,
  }) {
    _instance ??=
        SingleBanner._internal(bannerAdConstructor: bannerAdConstructor);
    return _instance;
  }

  /// Internal constructor
  SingleBanner._internal({
    BannerAdConstructor bannerAdConstructor,
  }) : _bannerAdConstructor =
            bannerAdConstructor ?? _bannerAdConstructorWrapper;

  /// The singleton instance
  static SingleBanner _instance;

  /// BannerAd constructor. it's overridden when testing.
  BannerAdConstructor _bannerAdConstructor;

  BannerAd _bannerAd;

  /// The BannerAd instance
  BannerAd get bannerAd => _bannerAd;

  int _ownerHashCode;

  /// This indicates which SingleBanner instance has the ownership of the BannerAd instance.
  int get ownerHashCode => _ownerHashCode;

  /// Shows the banner ad
  /// The instance that calls this method will get the ownership.
  void show({
    @required int callerHashCode,
    @required String adUnitId,
    @required AdSize size,
    @required double anchorOffset,
    @required bool isMounted,
  }) {
    // after disposing, _bannerAd must be null or the next instance must be set.
    _bannerAd?.dispose();
    _bannerAd = _bannerAdConstructor(
      adUnitId: adUnitId,
      size: size,
      listener: (MobileAdEvent event) {
        // Register a listener so that the show is only called after the load is complete.
        // Otherwise, if the screen changes between the time you call show and the time the load actually completes, you won't be able to delete the ad.
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

  /// The last instance that generated the ad has the ownership, and the ad cannot be disposed of by other instances.
  void dispose({@required int callerHashCode}) {
    if (callerHashCode == _ownerHashCode) {
      // after disposing, _bannerAd must be null or the next instance must be set.
      _bannerAd?.dispose();
      _bannerAd = null;
    }
  }
}

/// This is the same as BannerAd constructor.
/// This function will be mocked during testing.
BannerAd _bannerAdConstructorWrapper({
  @required String adUnitId,
  @required AdSize size,
  MobileAdTargetingInfo targetingInfo,
  MobileAdListener listener,
}) {
  return BannerAd(
    adUnitId: adUnitId,
    size: size,
    targetingInfo: targetingInfo,
    listener: listener,
  );
}

/// Type representing the BannerAd constructor
typedef BannerAdConstructor = BannerAd Function({
  @required String adUnitId,
  @required AdSize size,
  MobileAdTargetingInfo targetingInfo,
  MobileAdListener listener,
});
