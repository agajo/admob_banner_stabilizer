import 'package:flutter/material.dart';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();
  @override
  Widget build(BuildContext context) {
    FirebaseAdMob.instance.initialize(
        appId: appId); // TODO: write test app id for Android and iOS
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            AdMobBannerWidgetWithRoute(),
            Text("Text"),
          ],
        ),
      ),
    );
  }
}
