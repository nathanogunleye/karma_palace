// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karma_palace/src/games_services/messaging_service.dart';
import 'package:karma_palace/src/model/internal/player.dart';
import 'package:karma_palace/src/model/firebase/player.dart' as firebase_player;
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/board_state.dart';
import '../game_internals/score.dart';
import '../style/confetti.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import 'board_widget.dart';
import 'game_id_dialog.dart';

class PlaySessionScreenExtra {
  final String? gameId;
  final bool isHost;

  PlaySessionScreenExtra({
    required this.gameId,
    this.isHost = true,
  });
}

/// This widget defines the entirety of the screen that the player sees when
/// they are playing a level.
///
/// It is a stateful widget because it manages some state of its own,
/// such as whether the game is in a "celebration" state.
class PlaySessionScreen extends StatefulWidget {
  const PlaySessionScreen({super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  late DateTime _startOfPlay;

  late final BoardState _boardState;

  final MessagingService _messagingService = MessagingService();

  // To store the retrieved extra data
  PlaySessionScreenExtra? _screenExtra;

  @override
  void initState() {
    super.initState();
    _startOfPlay = DateTime.now();
    _boardState = BoardState(onWin: _playerWon);

    _messagingService.createRoom('test', Player(name: ''));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is a good place to access route arguments.
    if (_screenExtra == null) { // Only fetch it once
      final extra = GoRouterState.of(context).extra;
      if (extra is PlaySessionScreenExtra) {
        _screenExtra = extra;
        _log.info('Received gameId via GoRouterState.extra: ${_screenExtra?.gameId}');
        
        // Check if we need to show the game ID dialog
        if (!_screenExtra!.isHost && _screenExtra!.gameId == null) {
          _showGameIdDialog();
        } else {
          _initializeMessagingService();
        }
      } else {
        _log.warning(
            'PlaySessionScreenExtra not found in GoRouterState.extra. Type was: ${extra?.runtimeType}');
        // Fallback if no gameId is passed - e.g. creating a default room
        _messagingService.createRoom('default_test_room_no_extra', Player(name: 'PlayerHost'));
      }
    }
  }

  void _initializeMessagingService() {
    if (_screenExtra?.gameId != null) {
      if (_screenExtra!.isHost) {
        // Host creates a new room
        _messagingService.createRoom(_screenExtra!.gameId!, Player(name: 'PlayerHost'));
        _log.info('Host created room with gameId: ${_screenExtra!.gameId}');
      } else {
        // Guest joins an existing room
        _messagingService.joinRoom(_screenExtra!.gameId!, firebase_player.Player(
          id: 'PlayerGuest',
          name: 'PlayerGuest', 
          isPlaying: false,
          hand: [],
          faceUp: [],
          faceDown: [],
          isConnected: true,
          lastSeen: DateTime.now(),
          turnOrder: 1,
        ))
            .catchError((error) {
          _log.severe('Failed to join room: $error');
          // Handle room not found error - could show a dialog or go back to main menu
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Room not found: ${_screenExtra!.gameId}')),
            );
            GoRouter.of(context).go('/');
          }
        });
        _log.info('Guest joining room with gameId: ${_screenExtra!.gameId}');
      }
    } else {
      _log.warning('gameId is null in PlaySessionScreenExtra. Using default for MessagingService.');
      _messagingService.createRoom('default_test_room', Player(name: 'PlayerHost')); // Fallback
    }
  }

  Future<void> _showGameIdDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameIdDialog(
          animation: ModalRoute.of(context)!.animation!,
        );
      },
    );

    if (result != null) {
      // Update the screen extra with the provided game ID
      _screenExtra = PlaySessionScreenExtra(
        gameId: result,
        isHost: _screenExtra!.isHost,
      );
      _initializeMessagingService();
    } else {
      // User cancelled, go back to main menu
      if (mounted) {
        GoRouter.of(context).go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return MultiProvider(
      providers: [
        Provider.value(value: _boardState),
      ],
      child: IgnorePointer(
        // Ignore all input during the celebration animation.
        ignoring: _duringCelebration,
        child: Scaffold(
          backgroundColor: palette.backgroundPlaySession,
          // The stack is how you layer widgets on top of each other.
          // Here, it is used to overlay the winning confetti animation on top
          // of the game.
          body: Stack(
            children: [
              // This is the main layout of the play session screen,
              // with a settings button at top, the actual play area
              // in the middle, and a back button at the bottom.
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkResponse(
                      onTap: () => GoRouter.of(context).push('/settings'),
                      child: Image.asset(
                        'assets/images/settings.png',
                        semanticLabel: 'Settings',
                      ),
                    ),
                  ),
                  // const Spacer(),
                  // The actual UI of the game.
                  const BoardWidget(),
                  // const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: MyButton(
                      onPressed: () => GoRouter.of(context).go('/'),
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ),
              SizedBox.expand(
                child: Visibility(
                  visible: _duringCelebration,
                  child: IgnorePointer(
                    child: Confetti(
                      isStopped: !_duringCelebration,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _boardState.dispose();
    super.dispose();
  }

  Future<void> _playerWon() async {
    _log.info('Player won');

    // TODO: replace with some meaningful score for the card game
    final score = Score(1, 1, DateTime.now().difference(_startOfPlay));

    // final playerProgress = context.read<PlayerProgress>();
    // playerProgress.setLevelReached(widget.level.number);

    // Let the player see the game just after winning for a bit.
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    /// Give the player some time to see the celebration animation.
    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }
}
