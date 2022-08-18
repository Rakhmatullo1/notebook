import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:temirdaftar/screens/qarz_details.dart';

import 'screens/main_screen.dart';
import 'package:temirdaftar/screens/new_qarz.dart';
import 'screens/splash_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (ctx, snap) {
          return MaterialApp(
            title: 'Temir Daftar',
            theme: ThemeData(primarySwatch: Colors.deepPurple),
            home: snap.connectionState == ConnectionState.waiting
                ? const SplashScreen()
                : const MainScreen(),
            routes: {
              NewQarz.routeName: (context) {
                final id=ModalRoute.of(context)?.settings.arguments as String;
                 return NewQarz(id);
              },
              QarzDetails.routeName: (context) => const QarzDetails()
            },
          );
        });
  }
}
