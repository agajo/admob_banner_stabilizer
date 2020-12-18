import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/foundation.dart';

/// A wrapper for BannerAd.
/// It could be called AdMobBannerRepository.
/// BannerAd triggers an error if you dispose it more than once, but there is no way to check if it has already been disposed.
/// This is a class to ensure that BannerAd is not disposed more than once.
/// Being a Singleton, it also ensures that there is only one instance of BannerAd at a time.
/// The instance that generated the ad is recorded, and no other instance can dispose the ad.
/// When a BannerAd is disposed of, it is immediately discarded and the next instance is set or nulled. This prevents BannerAd from being disposed of more than once.
class SingleBanner {
  /// Factory constructor
  factory SingleBanner({BannerAdConstructor bannerAdConstructor}) {
    _instance ??=
        SingleBanner._internal(bannerAdConstructor: bannerAdConstructor);
    return _instance;
  }

  /// Internal constructor
  SingleBanner._internal({BannerAdConstructor bannerAdConstructor})
      : _bannerAdConstructor =
            bannerAdConstructor ?? _bannerAdConstructorWrapper;

  /// The singleton instance
  static SingleBanner _instance;

  /// BannerAd constructor. it's overridden when testing.
  BannerAdConstructor _bannerAdConstructor;

  /// The BannerAd instance
  BannerAd _bannerAd;
  BannerAd get bannerAd => _bannerAd;

  /// This indicates which SingleBanner instance has the ownership of the BannerAd instance.
  int _ownerHashCode;
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
