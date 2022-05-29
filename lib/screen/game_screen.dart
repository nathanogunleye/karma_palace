import 'package:flutter/material.dart';
import 'package:karma_palace/constants/widget_constants.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: backFloatingActionButton(context),
      body: Center(
        child: TextButton(
          onPressed: createNewDeck,
          child: const Text('Start'),
        ),
      ),
    );
  }

  void createNewDeck() {}
}
