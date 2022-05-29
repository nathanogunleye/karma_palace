import 'package:flutter/material.dart';
import 'package:karma_palace/screen/game_screen.dart';
import 'package:karma_palace/screen/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karma Palace',
      darkTheme: ThemeData(
        // primarySwatch: Colors.grey,
        primaryColor: Colors.green.shade900,
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      theme: ThemeData(
        // primaryColor: Colors.green.shade900,
        primarySwatch: Colors.grey,
      ),
      // home: const HomeScreen(),
      routes: {
        '/': (BuildContext context) => const HomeScreen(),
        '/game': (BuildContext context) => const GameScreen(),
      },
    );
  }
}
