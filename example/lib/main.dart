import 'dart:io';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebaseの各サービスを使う前に初期化を済ませておく必要がある
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();
  @override
  Widget build(BuildContext context) {
    FirebaseAdMob.instance.initialize(
        appId: Platform.isAndroid
            // AdMob App ID for Firebase Demo Project (Flood-It!)
            ? 'ca-app-pub-8123415297019784~2664022459'
            // test GADApplicationIdentifier. see https://developers.google.com/admob/ios/quick-start?hl=en
            : 'ca-app-pub-3940256099942544~1458002511');
    return MaterialApp(
      home: MyBody(),
    );
  }
}

class MyBody extends StatefulWidget {
  const MyBody({
    Key key,
  }) : super(key: key);

  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<MyBody> {
  bool isUpperPosition = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          SizedBox(height: isUpperPosition ? 100 : 300),
          Text("↓↓↓↓↓↓↓↓↓↓↓↓↓ AD HERE ↓↓↓↓↓↓↓↓↓↓↓↓↓"),
          AdMobBannerWidget(),
          Text("↑↑↑↑↑↑↑↑↑↑↑↑↑ AD HERE ↑↑↑↑↑↑↑↑↑↑↑↑↑"),
          RaisedButton(
              child: Text('Change Ad Position'),
              onPressed: () {
                setState(() {
                  isUpperPosition = !isUpperPosition;
                });
              })
        ],
      ),
    );
  }
}
