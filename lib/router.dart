// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:karma_palace/constants/text_constants.dart';
import 'package:karma_palace/src/main_menu/main_menu_screen.dart';
import 'package:provider/provider.dart';

import 'package:karma_palace/src/game_internals/score.dart';
import 'package:karma_palace/src/play_session/play_session_screen.dart';
import 'package:karma_palace/src/play_session/karma_palace_test_screen.dart';
import 'package:karma_palace/src/play_session/karma_palace_live_screen.dart';
import 'package:karma_palace/src/play_session/room_management_screen.dart';
import 'package:karma_palace/src/settings/settings_screen.dart';
import 'package:karma_palace/src/style/my_transition.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'package:karma_palace/src/win_game/win_game_screen.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(key: Key('main menu')),
      routes: [
        GoRoute(
          path: pathPlay,
          pageBuilder: (context, state) => buildMyTransition<void>(
            key: const ValueKey(pathPlay),
            color: context.watch<Palette>().backgroundPlaySession,
            child: const PlaySessionScreen(
              key: Key('level selection'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'karma-palace-test',
              builder: (context, state) => const KarmaPalaceTestScreen(),
            ),
            GoRoute(
              path: 'won',
              redirect: (context, state) {
                if (state.extra == null) {
                  // Trying to navigate to a win screen without any data.
                  // Possibly by using the browser's back button.
                  return '/';
                }

                // Otherwise, do not redirect.
                return null;
              },
              pageBuilder: (context, state) {
                final map = state.extra! as Map<String, dynamic>;
                final score = map['score'] as Score;

                return buildMyTransition<void>(
                  key: const ValueKey('won'),
                  color: context.watch<Palette>().backgroundPlaySession,
                  child: WinGameScreen(
                    score: score,
                    key: const Key('win game'),
                  ),
                );
              },
            )
          ],
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) =>
              const SettingsScreen(key: Key('settings')),
        ),
        GoRoute(
          path: 'room-management',
          builder: (context, state) =>
              const RoomManagementScreen(key: Key('room management')),
        ),
        GoRoute(
          path: 'karma-palace-live',
          builder: (context, state) =>
              const KarmaPalaceLiveScreen(key: Key('karma palace live')),
        ),
      ],
    ),
  ],
);
