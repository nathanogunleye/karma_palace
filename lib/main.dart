// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karma_palace/firebase_options.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'src/app_lifecycle/app_lifecycle.dart';
import 'src/audio/audio_controller.dart';
import 'src/game_internals/karma_palace_game_state.dart';
import 'src/games_services/firebase_game_service.dart';
import 'src/player_progress/player_progress.dart';
import 'router.dart';
import 'src/settings/settings.dart';
import 'src/style/palette.dart';

void main() async {
  // Basic logging setup.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
    );
  });

  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Put game into full screen mode on mobile devices.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Lock the game to portrait mode on mobile devices.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        // This is where you add objects that you want to have available
        // throughout your game.
        //
        // Every widget in the game can access these objects by calling
        // `context.watch()` or `context.read()`.
        // See `lib/main_menu/main_menu_screen.dart` for example usage.
        providers: [
          Provider(create: (context) => SettingsController()),
          Provider(create: (context) => Palette()),
          ChangeNotifierProvider(create: (context) => PlayerProgress()),
          // Karma Palace game state
          ChangeNotifierProvider(create: (context) => KarmaPalaceGameState()),
          // Firebase game service
          ChangeNotifierProvider(create: (context) => FirebaseGameService()),
          // Set up audio.
          ProxyProvider2<AppLifecycleStateNotifier, SettingsController,
              AudioController>(
            create: (context) => AudioController(),
            update: (context, lifecycleNotifier, settings, audio) {
              audio!.attachDependencies(lifecycleNotifier, settings);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
            // Ensures that music starts immediately.
            lazy: false,
          ),
        ],
        child: Builder(builder: (context) {
          final palette = context.watch<Palette>();

          return MaterialApp.router(
            title: 'Karma Palace',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: palette.pen,
                brightness: Brightness.dark,
                surface: palette.backgroundMain,
                onSurface: palette.ink,
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(color: palette.ink),
                titleLarge: TextStyle(
                  color: palette.darkPen,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(
                  color: palette.darkPen,
                  fontWeight: FontWeight.w600,
                ),
                labelLarge: TextStyle(
                  color: palette.pen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              useMaterial3: true,
            ).copyWith(
              // Enhanced button styling
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  backgroundColor: palette.pen,
                  foregroundColor: palette.trueWhite,
                  elevation: 2,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  backgroundColor: const Color(0xFF1A1A1A), // Dark gray
                  foregroundColor: palette.pen,
                  elevation: 1,
                  side: BorderSide(color: palette.pen.withValues(alpha: 0.5)),
                ),
              ),
              cardTheme: CardThemeData(
                color: palette.trueWhite,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: palette.trueWhite,
                hintStyle: TextStyle(
                  color: palette.inputText.withValues(alpha: 0.6),
                ),
                labelStyle: TextStyle(
                  color: palette.inputText,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.pen.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.pen.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.pen, width: 2),
                ),
              ),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: palette.pen,
                selectionColor: palette.pen.withValues(alpha: 0.3),
                selectionHandleColor: palette.pen,
              ),
            ),
            routerConfig: router,
          );
        }),
      ),
    );
  }
}
