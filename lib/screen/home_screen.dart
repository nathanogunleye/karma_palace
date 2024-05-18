import 'package:flutter/material.dart';
import 'package:karma_palace/constants/text_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              kAppName,
              style: TextStyle(
                fontSize: 48.0,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.play_arrow_rounded,
              ),
              label: const Text('Play'),
              onPressed: () => Navigator.pushNamed(context, '/game'),
            ),
            // ElevatedButton.icon(
            //   icon: const Icon(
            //     Icons.rule_folder_rounded,
            //   ),
            //   label: const Text('Rules'),
            //   onPressed: () {},
            // ),
          ],
        ),
      ),
    );
  }
}
