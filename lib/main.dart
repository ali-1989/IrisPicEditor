import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {

  Future<void> appInitialize() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

  ///===== call on any hot reload
  runZonedGuarded((){
    appInitialize();
    runApp(const MyApp());

  }, (error, stackTrace) {
    print('@@ catch on ZonedGuarded: ${error.toString()}');

    if(kDebugMode) {
      throw error;
    }
  }
  );

  //appInitialize();
  //runApp(const MyApp());
}
///==============================================================================================
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return const Material(
      child: Text('hi'),
    );
  }
}