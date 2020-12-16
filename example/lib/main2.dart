import 'dart:io';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_banner_stabilizer/admob_banner_stabilizer.dart';
import 'package:provider/provider.dart';

// This example is with Navigator.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAdMob.instance.initialize(
      appId: Platform.isAndroid
          // AdMob App ID for Firebase Demo Project (Flood-It!)
          ? 'ca-app-pub-8123415297019784~2664022459'
          // test GADApplicationIdentifier. see https://developers.google.com/admob/ios/quick-start?hl=en
          : 'ca-app-pub-3940256099942544~1458002511');
  runApp(ChangeNotifierProvider(
    create: (BuildContext context) => PagesNotifier(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Navigator(
        observers: [RouteObserver<PageRoute<dynamic>>()],
        pages: [
          MaterialPage(key: ValueKey('MyBody'), child: MyBody()),
          if (Provider.of<PagesNotifier>(context).myBody2isPushed)
            MaterialPage(key: ValueKey('MyBody2'), child: MyBody2()),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          return true;
        },
      ),
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
      appBar: AppBar(
        title: Text('MyBody'),
      ),
      body: Column(
        children: [
          SizedBox(height: isUpperPosition ? 50 : 150),
          Text("↓↓↓↓↓↓↓↓↓↓↓↓↓ AD HERE ↓↓↓↓↓↓↓↓↓↓↓↓↓"),
          AdMobBannerWidget(
            adUnitId: BannerAd.testAdUnitId,
            backgroundColor: Colors.yellow,
          ),
          Text("↑↑↑↑↑↑↑↑↑↑↑↑↑ AD HERE ↑↑↑↑↑↑↑↑↑↑↑↑↑"),
          RaisedButton(
              child: Text('Change Ad Position'),
              onPressed: () {
                setState(() {
                  isUpperPosition = !isUpperPosition;
                });
              }),
          RaisedButton(
            child: Text('push MyBody2'),
            onPressed: () {
              Provider.of<PagesNotifier>(context, listen: false).pushMyBody2();
            },
          )
        ],
      ),
    );
  }
}

class MyBody2 extends StatelessWidget {
  const MyBody2({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyBody2'),
      ),
      body: Column(
        children: [
          SizedBox(height: 100),
          Text("↓↓↓↓↓↓↓↓↓↓↓↓↓ AD HERE ↓↓↓↓↓↓↓↓↓↓↓↓↓"),
          AdMobBannerWidget(
            adUnitId: BannerAd.testAdUnitId,
            backgroundColor: Colors.yellow,
          ),
          Text("↑↑↑↑↑↑↑↑↑↑↑↑↑ AD HERE ↑↑↑↑↑↑↑↑↑↑↑↑↑"),
        ],
      ),
    );
  }
}

class PagesNotifier extends ChangeNotifier {
  bool myBody2isPushed = true;
  void pushMyBody2() {
    myBody2isPushed = true;
    notifyListeners();
  }
}
