import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/firebase_game_service.dart';
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/style/palette.dart';
import '../style/my_button.dart';
import 'karma_palace_board_widget.dart';

class KarmaPalaceLiveScreen extends StatefulWidget {
  const KarmaPalaceLiveScreen({super.key});

  @override
  State<KarmaPalaceLiveScreen> createState() => _KarmaPalaceLiveScreenState();
}

class _KarmaPalaceLiveScreenState extends State<KarmaPalaceLiveScreen> with WidgetsBindingObserver {
  static final Logger _log = Logger('KarmaPalaceLiveScreen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer initialization to avoid build-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGameState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for Firebase service changes and update game state
    final gameService = context.read<FirebaseGameService>();
    final gameState = context.read<KarmaPalaceGameState>();
    
    // Update game state whenever Firebase room changes
    if (gameService.currentRoom != null && gameService.currentPlayerId != null) {
      _log.info('DEBUG: Updating game state for player: ${gameService.currentPlayerId}');
      _log.info('DEBUG: Current game state player ID: ${gameState.currentPlayerId}');
      
      // Initialize game state if not already done for this player
      if (gameState.currentPlayerId == null || gameState.currentPlayerId != gameService.currentPlayerId) {
        _log.info('DEBUG: Initializing game state for new player: ${gameService.currentPlayerId}');
        _log.info('DEBUG: Previous player ID was: ${gameState.currentPlayerId}');
        
        // Reset game state completely for new player
        if (gameState.currentPlayerId != null) {
          _log.info('DEBUG: Resetting game state for different player');
          gameState.resetForNewPlayer();
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          gameState.initializeGame(gameService.currentRoom!, gameService.currentPlayerId!);
        });
      } else {
        // Just update the room data
        _log.info('DEBUG: Updating room data for existing player');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          gameState.updateRoom(gameService.currentRoom!);
        });
      }
    }
  }

  void _initializeGameState() {
    final gameService = context.read<FirebaseGameService>();
    final gameState = context.read<KarmaPalaceGameState>();
    
    if (gameService.currentRoom != null && gameService.currentPlayerId != null) {
      _log.info('DEBUG: Initializing game state for player: ${gameService.currentPlayerId}');
      _log.info('DEBUG: Current game state player ID: ${gameState.currentPlayerId}');
      gameState.initializeGame(gameService.currentRoom!, gameService.currentPlayerId!);
      _log.info('Initialized game state for room: ${gameService.currentRoomId}');
    } else {
      _log.info('DEBUG: Cannot initialize game state - room or playerId is null');
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
      final gameState = context.read<KarmaPalaceGameState>();
      
      // Validate the card play
      _log.info('DEBUG: Validating card play: ${card.displayString}');
      _log.info('DEBUG: Game state can play card: ${gameState.canPlayCard(card)}');
      _log.info('DEBUG: Is my turn: ${gameState.isMyTurn}');
      _log.info('DEBUG: Game in progress: ${gameState.gameInProgress}');
      _log.info('DEBUG: Current player ID: ${gameState.currentPlayerId}');
      _log.info('DEBUG: Room current player: ${gameState.room?.currentPlayer}');
      
      if (!gameState.canPlayCard(card)) {
        _log.info('DEBUG: Card play validation failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot play ${card.displayString} - invalid move'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      _log.info('DEBUG: Card play validation passed');

      final gameService = context.read<FirebaseGameService>();
      await gameService.playCard(card, sourceZone);
      _log.info('Played card: ${card.displayString} from $sourceZone');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Played ${card.displayString}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _log.severe('Failed to play card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play card: $e'),
            backgroundColor: Colors.red,
          ),
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
    // Store services before async operation
    final gameService = context.read<FirebaseGameService>();
    
    // Show confirmation dialog
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Room?'),
          content: const Text('Are you sure you want to leave this room? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    // If user confirmed, leave the room
    if (shouldLeave == true) {
      try {
        await gameService.leaveRoom();
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        _log.severe('Failed to leave room: $e');
      }
    }
  }

  void _onCardTap(game_card.Card card, String sourceZone) {
    _log.info('DEBUG: Card tapped: ${card.displayString} from $sourceZone');
    _playCard(card, sourceZone);
  }

  /// Check if the current player can play any cards
  bool _canCurrentPlayerPlayAnyCard() {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    
    if (room == null || gameService.currentPlayerId == null) return false;
    
    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );
    
    // Check hand cards
    for (final card in currentPlayer.hand) {
      if (_canPlayCard(card, currentPlayer, 'hand')) {
        return true;
      }
    }
    
    // Check face-up cards if hand is empty
    if (currentPlayer.hand.isEmpty) {
      for (final card in currentPlayer.faceUp) {
        if (_canPlayCard(card, currentPlayer, 'faceUp')) {
          return true;
        }
      }
    }
    
    // Check face-down cards if hand and face-up are empty
    if (currentPlayer.hand.isEmpty && currentPlayer.faceUp.isEmpty) {
      for (final card in currentPlayer.faceDown) {
        if (_canPlayCard(card, currentPlayer, 'faceDown')) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Check if a specific card can be played by the current player
  bool _canPlayCard(game_card.Card card, Player player, String sourceZone) {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    
    if (room == null) return false;
    
    // Check zone restrictions
    if (sourceZone == 'faceUp' && player.hand.isNotEmpty) {
      return false; // Can't play face-up cards if hand has cards
    }
    if (sourceZone == 'faceDown' && (player.hand.isNotEmpty || player.faceUp.isNotEmpty)) {
      return false; // Can't play face-down cards if hand or face-up has cards
    }
    
    final topCard = room.playPile.isNotEmpty ? room.playPile.last : null;
    
    if (topCard == null) {
      return true; // First card of the game
    }

    // Check if reset effect is active (2 was played)
    if (room.resetActive == true) {
      return true; // Any card can be played after a 2
    }

    // Check if current player is forced to play low (from card 7 effect)
    if (player.forcedToPlayLow == true) {
      return card.numericValue <= 7;
    }

    // Check if card can be played on high cards (J, Q, K)
    if (['J', 'Q', 'K'].contains(topCard.value)) {
      return card.canPlayOnHighCard(topCard);
    }

    // Check if top card is 7 - forces next player to play 7 or lower
    if (topCard.value == '7') {
      return card.numericValue <= 7;
    }

    // Check if playing a special card on a non-royal card
    if (card.hasSpecialEffect && !['J', 'Q', 'K'].contains(topCard.value)) {
      return true; // Special cards can be played on any non-royal card
    }

    // Normal card comparison
    return card.numericValue >= topCard.numericValue;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final gameService = context.watch<FirebaseGameService>();

    // Update game state when room changes - moved to didChangeDependencies

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
        title: Text('Room: ${room.id}'),
        backgroundColor: palette.backgroundPlaySession,
        foregroundColor: palette.ink,
        automaticallyImplyLeading: false,
        actions: [
          // Copy Room ID button
          IconButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: room.id));
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Room ID copied to clipboard!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
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
            child: Row(
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
          ),

          // Game Board
          Expanded(
            child: KarmaPalaceBoardWidget(
              onCardTap: _onCardTap,
            ),
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
                        // Show "Play Card" button if player has valid moves
                        if (_canCurrentPlayerPlayAnyCard())
                          MyButton(
                            onPressed: () {
                              // Show card selection dialog
                              _showCardSelectionDialog();
                            },
                            child: const Text('Play Card'),
                          ),
                        // Show "Pick Up Pile" button if player has no valid moves
                        if (!_canCurrentPlayerPlayAnyCard())
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
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
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
      ),
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