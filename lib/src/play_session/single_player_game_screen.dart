import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/local_game_service.dart';
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
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

  @override
  void initState() {
    super.initState();
    _initializeGameState();
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
                  MyButton(
                    onPressed: gameService.currentPlayerId == room.currentPlayer ? _pickUpPile : null,
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
