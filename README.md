# admob_banner_stabilizer

A package to use banner ads in firebase_admob package easily.

![admob_widget_record](https://user-images.githubusercontent.com/12369062/102615893-058eeb00-417a-11eb-8f39-121d3ba865e0.gif)

## Features

### Banner ads appear in the same position as the Widget

The build method of AdmobBannerWidget simply returns a Container, but an ad with the same height is placed exactly on the Container.


### Widget height and ad height match, so it's easy to layout

This ensures that the ad and the button do not overlap.


### When the widget is removed from the widget tree, the ad disappears

The ad itself can be treated as if it were in the widget. You don't have to write an additional process to remove the ad.


### Navigator is supported

When another page is pushed from above, the ad disappears.


### Supports changing the orientation of the device

If you change the orientation of the device, the ad will be erased first, and then reappear in the new position.


### No crashes after consecutive screen transitions

You can dispose this widget continuously.


## Getting Started

This package depends on the firebase_admob plugin.

Please read the linked pages carefully and complete the necessary preparations.

[Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup?hl=en)
[firebase_admob plugin](https://pub.dev/packages/firebase_admob)

If you just want to run examples, these preparations is not necessary.


## Usage

Initialize the firebase_admob plugin before use AdMobBannerWidget.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseAdMob.instance.initialize(
      appId: Platform.isAndroid
          // AdMob App ID for Firebase Demo Project (Flood-It!)
          ? 'ca-app-pub-8123415297019784~2664022459'
          // test GADApplicationIdentifier. see https://developers.google.com/admob/ios/quick-start?hl=en
          : 'ca-app-pub-3940256099942544~1458002511');
  runApp(MyApp());
}
```

Place the AdMobBannerWidget where you want the ad to appear.

```dart
class MyApp extends StatelessWidget {
  const MyApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: AdMobBannerWidget(
          adUnitId: BannerAd.testAdUnitId,
        ),
      ),
    );
  }
}
```

## Notes

### You cannot specify the size of the ads

The ad size will be the largest one that can be displayed within 1/8th of the height of the SafeArea.
AdMobBanner's SmartBanner standard is used as a reference.


### Ads cannot be moved as the widget is moved

They just appear and disappear.

You can't use it as a part of the list to scroll.


### You can't leave an ad running behind the scenes

It only calculates the position of the widget and puts the ad in front of it. You can't hide ads.