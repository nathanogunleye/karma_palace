// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karma_palace/src/main_menu/main_menu_screen.dart';
import 'package:karma_palace/src/play_session/karma_palace_live_screen.dart';
import 'package:karma_palace/src/play_session/room_management_screen.dart';
import 'package:karma_palace/src/play_session/single_player_setup_screen.dart';
import 'package:karma_palace/src/play_session/single_player_game_screen.dart';
import 'package:karma_palace/src/settings/settings_screen.dart';
import 'package:karma_palace/src/splash/splash_screen.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(key: Key('splash')),
    ),
    GoRoute(
      path: '/join/:roomId',
      builder: (context, state) => RoomManagementScreen(
        key: const Key('room management join'),
        initialRoomId: state.params['roomId'],
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainMenuScreen(key: Key('main menu')),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
      ),
      routes: [
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
        GoRoute(
          path: 'single-player-setup',
          builder: (context, state) => SinglePlayerSetupScreen(
            key: const Key('single player setup'),
            playerCount: state.extra as int? ?? 2,
          ),
        ),
        GoRoute(
          path: 'single-player-game',
          builder: (context, state) =>
              const SinglePlayerGameScreen(key: Key('single player game')),
        ),
        GoRoute(
          path: 'how-to-play',
          builder: (context, state) =>
              const SinglePlayerGameScreen(key: Key('how to play'), showTutorial: true),
        ),
      ],
    ),
  ],
);
