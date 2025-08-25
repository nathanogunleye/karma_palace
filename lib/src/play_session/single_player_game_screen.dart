import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/local_game_service.dart';
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'package:karma_palace/src/style/my_button.dart';
import 'single_player_board_widget.dart';

class SinglePlayerGameScreen extends StatefulWidget {
  const SinglePlayerGameScreen({super.key});

  @override
  State<SinglePlayerGameScreen> createState() => _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState extends State<SinglePlayerGameScreen> {
  static final Logger _log = Logger('SinglePlayerGameScreen');

  int _previousPlayPileLength = 0;

  @override
  void initState() {
    super.initState();
    _initializeGameState();
    
    // Listen for pick-up effects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameService = context.read<LocalGameService>();
      gameService.setPickUpEffectCallback(_onPickUpEffect);
      gameService.setBurnEffectCallback(_onBurnEffect);
      gameService.addListener(_onGameStateChanged);
    });
  }

  @override
  void dispose() {
    final gameService = context.read<LocalGameService>();
    gameService.clearPickUpEffectCallback();
    gameService.clearBurnEffectCallback();
    gameService.removeListener(_onGameStateChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameService = context.read<LocalGameService>();
    final gameState = context.read<KarmaPalaceGameState>();
    
    // Update game state whenever local room changes
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
    final gameService = context.read<LocalGameService>();
    final gameState = context.read<KarmaPalaceGameState>();
    
    if (gameService.currentRoom != null && gameService.currentPlayerId != null) {
      _log.info('DEBUG: Initializing game state for player: ${gameService.currentPlayerId}');
      _log.info('DEBUG: Current game state player ID: ${gameState.currentPlayerId}');
      gameState.initializeGame(gameService.currentRoom!, gameService.currentPlayerId!);
      _log.info('Initialized game state for single player game');
    } else {
      _log.info('DEBUG: Cannot initialize game state - room or playerId is null');
    }
  }

  Future<void> _startGame() async {
    try {
      final gameService = context.read<LocalGameService>();
      await gameService.startGame();
      _log.info('Started single player game');
    } catch (e) {
      _log.severe('Failed to start game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playCard(game_card.Card card, String sourceZone) async {
    try {
      final gameService = context.read<LocalGameService>();
      await gameService.playCard(card, sourceZone);
      _log.info('Played card: ${card.displayString} from $sourceZone');
      
      // Check for win condition after playing a card
      final room = gameService.currentRoom;
      if (room != null) {
        _checkWinCondition(room);
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
      final gameService = context.read<LocalGameService>();
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

  Future<void> _leaveGame() async {
    try {
      final gameService = context.read<LocalGameService>();
      await gameService.leaveGame();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      _log.severe('Failed to leave game: $e');
    }
  }

  void _onCardTap(game_card.Card card, String sourceZone) {
    _log.info('DEBUG: Card tapped: ${card.displayString} from $sourceZone');
    _playCard(card, sourceZone);
  }

  /// Check if the current player can play any cards
  bool _canCurrentPlayerPlayAnyCard() {
    final gameService = context.read<LocalGameService>();
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

  /// Get the effective top card (handles glass effect)
  game_card.Card? _getEffectiveTopCard() {
    final gameService = context.read<LocalGameService>();
    final room = gameService.currentRoom;
    
    if (room == null || room.playPile.isEmpty) {
      return null;
    }
    
    // Start from the top and work backwards through 5s
    for (int i = room.playPile.length - 1; i >= 0; i--) {
      final card = room.playPile[i];
      
      // If we find a non-5 card, that's our effective top card
      if (card.value != '5') {
        return card;
      }
    }
    
    // If we get here, all cards are 5s, so return the bottom 5
    return room.playPile.first;
  }

  /// Check if a specific card can be played by the current player
  bool _canPlayCard(game_card.Card card, Player player, String sourceZone) {
    final gameService = context.read<LocalGameService>();
    final room = gameService.currentRoom;
    
    if (room == null) return false;
    
    // Check zone restrictions
    if (sourceZone == 'faceUp' && player.hand.isNotEmpty) {
      return false; // Can't play face-up cards if hand has cards
    }
    if (sourceZone == 'faceDown' && (player.hand.isNotEmpty || player.faceUp.isNotEmpty)) {
      return false; // Can't play face-down cards if hand or face-up has cards
    }
    
    final effectiveTopCard = _getEffectiveTopCard();
    
    if (effectiveTopCard == null) {
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
    if (['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
      return card.canPlayOnHighCard(effectiveTopCard);
    }

    // Check if top card is 7 - forces next player to play 7 or lower
    if (effectiveTopCard.value == '7') {
      return card.numericValue <= 7;
    }

    // Check if playing a special card on a non-royal card
    if (card.hasSpecialEffect && !['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
      return true; // Special cards can be played on any non-royal card
    }

    // Normal card comparison
    return card.numericValue >= effectiveTopCard.numericValue;
  }

  void _onPickUpEffect() {
    if (mounted) {
      _showPickUpNotification();
    }
  }

  void _onBurnEffect() {
    if (mounted) {
      _showBurnNotification();
    }
  }

  void _showPickUpNotification() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.handshake,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '📦 Player picked up the pile!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showBurnNotification() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '🔥 Play pile burned! Same player goes again.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _onGameStateChanged() {
    final gameService = context.read<LocalGameService>();
    final room = gameService.currentRoom;
    
    if (room != null && mounted) {
      final currentPileLength = room.playPile.length;
      
      // Detect if pile was emptied (either by burn or pick-up)
      if (_previousPlayPileLength > 0 && currentPileLength == 0) {
        // Pile was emptied - determine if it was a pick-up or burn
        // We'll use a simple heuristic: if it's not our turn, it's likely a pick-up
        final isMyTurn = room.currentPlayer == gameService.currentPlayerId;
        
        if (!isMyTurn) {
          // AI likely picked up the pile
          _onPickUpEffect();
        }
        // If it is our turn, the callbacks will handle burn/pick-up detection
      }
      
      _previousPlayPileLength = currentPileLength;
      
      // Check for win condition
      _checkWinCondition(room);
    }
  }

  void _checkWinCondition(Room room) {
    final gameService = context.read<LocalGameService>();
    final humanPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.last,
    );
    
    // Check if human player has won (no cards left)
    if (humanPlayer.hasWon) {
      _showWinNotification();
    }
  }

  void _showWinNotification() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '🎉 You won! All cards played!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Play Again',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to win screen or restart game
              context.go('/win');
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final gameService = context.watch<LocalGameService>();

    if (!gameService.isConnected || gameService.currentRoom == null) {
      return Scaffold(
        backgroundColor: palette.backgroundMain,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Not connected to a game',
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


    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      appBar: AppBar(
        title: Text('Single Player - ${room.players[1].name}'),
        backgroundColor: palette.backgroundPlaySession,
        foregroundColor: palette.ink,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _leaveGame,
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Game Board
          Expanded(
            child: SinglePlayerBoardWidget(
              onCardTap: _onCardTap,
            ),
          ),

          // Player Controls
          if (room.gameState == GameState.playing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Only show "Pick Up Pile" button if player has no valid moves
                  if (gameService.currentPlayerId == room.currentPlayer && !_canCurrentPlayerPlayAnyCard())
                    MyButton(
                      onPressed: _pickUpPile,
                      child: const Text('Pick Up Pile'),
                    ),
                ],
              ),
            )
          else if (room.gameState == GameState.waiting)
            Container(
              padding: const EdgeInsets.all(16),
              child: MyButton(
                onPressed: gameService.isHost ? _startGame : null,
                child: const Text('Start Game'),
              ),
            ),
        ],
      ),
    );
  }
}
