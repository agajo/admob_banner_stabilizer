import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/foundation.dart';

// BannerAdのwrapper。
// It could be called AdMobBannerRepository.
// BannerAdを2回以上disposeしないためのクラス。
// Singletonにすることで、間接的にBannerAd自体のインスタンスも一度に一つしか存在しないことを保証する。
// BannerAdをdisposeしたら、必ず、次をセットするかnullにする。
class SingleBanner {
  factory SingleBanner({BannerAdConstructor bannerAdConstructor}) {
    _instance ??=
        SingleBanner._internal(bannerAdConstructor: bannerAdConstructor);
    return _instance;
  }
  SingleBanner._internal({BannerAdConstructor bannerAdConstructor})
      : _bannerAdConstructor =
            bannerAdConstructor ?? _bannerAdConstructorWrapper;
  static SingleBanner _instance;
  BannerAdConstructor _bannerAdConstructor;

  BannerAd _bannerAd;
  BannerAd get bannerAd => _bannerAd;
  // 現在の所有者インスタンスは誰かを表す
  int _ownerHashCode;
  int get ownerHashCode => _ownerHashCode;

  void show({
    @required int callerHashCode,
    @required String adUnitId,
    @required AdSize size,
    @required double anchorOffset,
    @required bool isMounted,
  }) {
    _bannerAd?.dispose(); // disposeしたら、必ず、次をセットするかnullにする。
    _bannerAd = _bannerAdConstructor(
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

typedef BannerAdConstructor = BannerAd Function({
  @required String adUnitId,
  @required AdSize size,
  MobileAdTargetingInfo targetingInfo,
  MobileAdListener listener,
});
