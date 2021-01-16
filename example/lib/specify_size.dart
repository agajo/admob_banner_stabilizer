import 'dart:io';

import 'package:flutter/material.dart';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

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

class MyApp extends StatefulWidget {
  const MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double maxBannerHeight;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            SizedBox(height: 10),
            Row(
              children: [
                Text('Choose maxBannerHeight!'),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListWheelScrollView(
                      itemExtent: 20,
                      children:
                          List.generate(15, (i) => Text((i * 10).toString())),
                      physics: FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (value) {
                        setState(() {
                          maxBannerHeight = value.toDouble() * 10;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 64),
            Container(
              height: maxBannerHeight,
              color: Colors.blue,
              child: AdMobBannerWidget(
                adUnitId: BannerAd.testAdUnitId,
                maxHeight: maxBannerHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
