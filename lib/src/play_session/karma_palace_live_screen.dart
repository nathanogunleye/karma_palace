import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/firebase_game_service.dart';
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/style/palette.dart';
import '../style/my_button.dart';
import 'karma_palace_board_widget.dart';

class KarmaPalaceLiveScreen extends StatefulWidget {
  const KarmaPalaceLiveScreen({super.key});

  @override
  State<KarmaPalaceLiveScreen> createState() => _KarmaPalaceLiveScreenState();
}

class _KarmaPalaceLiveScreenState extends State<KarmaPalaceLiveScreen> {
  static final Logger _log = Logger('KarmaPalaceLiveScreen');

  @override
  void initState() {
    super.initState();
    // Defer initialization to avoid build-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGameState();
    });
  }

  void _initializeGameState() {
    final gameService = context.read<FirebaseGameService>();
    final gameState = context.read<KarmaPalaceGameState>();
    
    if (gameService.currentRoom != null && gameService.currentPlayerId != null) {
      gameState.initializeGame(gameService.currentRoom!, gameService.currentPlayerId!);
      _log.info('Initialized game state for room: ${gameService.currentRoomId}');
    }
  }

  Future<void> _startGame() async {
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.startGame();
      _log.info('Game started');
    } catch (e) {
      _log.severe('Failed to start game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start game: $e')),
        );
      }
    }
  }

  Future<void> _playCard(game_card.Card card, String sourceZone) async {
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.playCard(card, sourceZone);
      _log.info('Played card: ${card.displayString} from $sourceZone');
    } catch (e) {
      _log.severe('Failed to play card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play card: $e')),
        );
      }
    }
  }

  Future<void> _pickUpPile() async {
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.pickUpPile();
      _log.info('Picked up play pile');
    } catch (e) {
      _log.severe('Failed to pick up pile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick up pile: $e')),
        );
      }
    }
  }

  Future<void> _leaveRoom() async {
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.leaveRoom();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      _log.severe('Failed to leave room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final gameService = context.watch<FirebaseGameService>();

    if (!gameService.isConnected || gameService.currentRoom == null) {
      return Scaffold(
        backgroundColor: palette.backgroundPlaySession,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Not connected to a room',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              MyButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Main Menu'),
              ),
            ],
          ),
        ),
      );
    }

    final room = gameService.currentRoom!;
    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      appBar: AppBar(
        title: Text('Room: ${room.id.substring(0, 8)}...'),
        backgroundColor: palette.backgroundPlaySession,
        foregroundColor: palette.ink,
        actions: [
          // Copy Room ID button
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: room.id));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Room ID copied to clipboard!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Room ID',
          ),
          if (gameService.isHost && room.gameState == GameState.waiting)
            IconButton(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start Game',
            ),
          IconButton(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Room',
          ),
        ],
      ),
      body: Column(
        children: [
          // Room Status
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Players: ${room.players.length}/6',
                      style: TextStyle(
                        fontSize: 16,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      'Status: ${room.gameState.name.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Room ID display with copy button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room ID:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: palette.ink,
                              ),
                            ),
                            Text(
                              room.id,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                color: palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: room.id));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Room ID copied to clipboard!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.copy, color: palette.ink, size: 20),
                        tooltip: 'Copy Room ID',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Game Board
          const Expanded(
            child: KarmaPalaceBoardWidget(),
          ),

          // Player Controls
          if (room.gameState == GameState.playing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Current Player Info
                  Text(
                    'Your Turn: ${currentPlayer.isPlaying ? "YES" : "NO"}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: currentPlayer.isPlaying ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  if (currentPlayer.isPlaying) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MyButton(
                          onPressed: () {
                            // Show card selection dialog
                            _showCardSelectionDialog();
                          },
                          child: const Text('Play Card'),
                        ),
                        MyButton(
                          onPressed: _pickUpPile,
                          child: const Text('Pick Up Pile'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCardSelectionDialog() {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom!;
    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Card to Play'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentPlayer.hand.isNotEmpty) ...[
              const Text('Hand:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                                 children: currentPlayer.hand.map((card) {
                   return InkWell(
                     onTap: () {
                       Navigator.of(context).pop();
                       _playCard(card, 'hand');
                     },
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(card.displayString),
                     ),
                   );
                 }).toList(),
              ),
            ],
            if (currentPlayer.hand.isEmpty && currentPlayer.faceUp.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Face Up:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                                 children: currentPlayer.faceUp.map((card) {
                   return InkWell(
                     onTap: () {
                       Navigator.of(context).pop();
                       _playCard(card, 'faceUp');
                     },
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(card.displayString),
                     ),
                   );
                 }).toList(),
              ),
            ],
            if (currentPlayer.hand.isEmpty && currentPlayer.faceUp.isEmpty && currentPlayer.faceDown.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Face Down:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                                 children: currentPlayer.faceDown.map((card) {
                   return InkWell(
                     onTap: () {
                       Navigator.of(context).pop();
                       _playCard(card, 'faceDown');
                     },
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: const Text('???'),
                     ),
                   );
                 }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 