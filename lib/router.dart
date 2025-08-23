// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:karma_palace/src/main_menu/main_menu_screen.dart';
import 'package:karma_palace/src/play_session/karma_palace_live_screen.dart';
import 'package:karma_palace/src/play_session/room_management_screen.dart';
import 'package:karma_palace/src/settings/settings_screen.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(key: Key('main menu')),
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
      ],
    ),
  ],
);
