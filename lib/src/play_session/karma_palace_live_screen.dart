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
import 'karma_palace_board_widget.dart';

class KarmaPalaceLiveScreen extends StatefulWidget {
  const KarmaPalaceLiveScreen({super.key});

  @override
  State<KarmaPalaceLiveScreen> createState() => _KarmaPalaceLiveScreenState();
}

class _KarmaPalaceLiveScreenState extends State<KarmaPalaceLiveScreen> with WidgetsBindingObserver {
  static final Logger _log = Logger('KarmaPalaceLiveScreen');

  int _previousPlayPileLength = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGameState();
    });
    
    // Listen for pick-up effects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameService = context.read<FirebaseGameService>();
      gameService.setPickUpEffectCallback(_onPickUpEffect);
      gameService.setBurnEffectCallback(_onBurnEffect);
      gameService.addListener(_onGameStateChanged);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final gameService = context.read<FirebaseGameService>();
    gameService.clearPickUpEffectCallback();
    gameService.clearBurnEffectCallback();
    gameService.removeListener(_onGameStateChanged);
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

  /// Get the effective top card (handles glass effect)
  game_card.Card? _getEffectiveTopCard() {
    final gameService = context.read<FirebaseGameService>();
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
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    
    if (room != null && mounted) {
      final currentPileLength = room.playPile.length;
      
      // Detect if pile was emptied (either by burn or pick-up)
      if (_previousPlayPileLength > 0 && currentPileLength == 0) {
        // Pile was emptied - determine if it was a pick-up or burn
        // We'll use a simple heuristic: if it's not our turn, it's likely a pick-up
        final isMyTurn = room.currentPlayer == gameService.currentPlayerId;
        
        if (!isMyTurn) {
          // Opponent likely picked up the pile
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
    final gameService = context.read<FirebaseGameService>();
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
    final gameService = context.watch<FirebaseGameService>();

    const gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF581C87), Color(0xFF6B21A8), Color(0xFF831843)],
      ),
    );

    if (!gameService.isConnected || gameService.currentRoom == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: gradientDecoration,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not connected to a room',
                      style: TextStyle(fontSize: 24, color: Colors.white)),
                  const SizedBox(height: 16),
                  _LiveGlassButton(label: 'Back to Main Menu', onTap: () => context.go('/')),
                ],
              ),
            ),
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: gradientDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // Custom header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LiveGlassButton(label: 'Leave', icon: Icons.exit_to_app, onTap: _leaveRoom),
                    Column(
                      children: [
                        const Text('Karma Palace',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Room: ${room.id}',
                            style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final sm = ScaffoldMessenger.of(context);
                            await Clipboard.setData(ClipboardData(text: room.id));
                            if (mounted) {
                              sm.showSnackBar(const SnackBar(
                                content: Text('Room ID copied!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.copy, color: Colors.white, size: 16),
                          ),
                        ),
                        if (gameService.isHost && room.gameState == GameState.waiting) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _startGame,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Room status strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Players: ${room.players.length}/6',
                        style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    Text(room.gameState.name.toUpperCase(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ],
                ),
              ),

              // Game board
              Expanded(
                child: KarmaPalaceBoardWidget(onCardTap: _onCardTap),
              ),

              // Action buttons
              if (room.gameState == GameState.playing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentPlayer.isPlaying ? 'Your Turn' : 'Waiting...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentPlayer.isPlaying ? const Color(0xFF4ADE80) : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (currentPlayer.isPlaying) ...[
                        if (_canCurrentPlayerPlayAnyCard())
                          _LiveGameButton(
                            label: 'Play Card',
                            color: const Color(0xFF22C55E),
                            onTap: _showCardSelectionDialog,
                          ),
                        if (!_canCurrentPlayerPlayAnyCard())
                          _LiveGameButton(
                            label: 'Pick Up Pile',
                            color: const Color(0xFFEF4444),
                            onTap: _pickUpPile,
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
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

// ── Helper widgets ──────────────────────────────────────────────────────────

class _LiveGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _LiveGlassButton({required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _LiveGameButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _LiveGameButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center),
      ),
    );
  }
} 