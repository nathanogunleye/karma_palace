import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/number_constants.dart';
import '../game_internals/karma_palace_game_state.dart';
import '../games_services/firebase_game_service.dart';
import '../model/firebase/room.dart';
import '../model/firebase/player.dart';
import '../model/firebase/card.dart' as game_card;
import '../style/palette.dart';
import 'karma_palace_player_widget.dart';
import 'karma_palace_play_pile_widget.dart';

class KarmaPalaceBoardWidget extends StatelessWidget {
  final Function(game_card.Card, String)? onCardTap;

  const KarmaPalaceBoardWidget({
    super.key,
    this.onCardTap,
  });

  void _onCardTap(game_card.Card card, String sourceZone) {
    onCardTap?.call(card, sourceZone);
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<FirebaseGameService>();
    final gameState = context.watch<KarmaPalaceGameState>();
    final palette = context.watch<Palette>();

    // Use Firebase data if available, otherwise use game state
    final room = gameService.currentRoom ?? gameState.room;
    
    if (room == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.backgroundMain,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: [
            // Background grid pattern
            _buildGridPattern(),
            
            // Central play pile
            Center(
              child: KarmaPalacePlayPileWidget(
                playPile: room.playPile,
                topCard: room.playPile.isNotEmpty ? room.playPile.last : null,
              ),
            ),
            
            // Player positions around the board
            _buildPlayerPositions(context, room),
            
            // Game status overlay
            if (gameState.isGameFinished)
              _buildGameOverlay(context, gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildGridPattern() {
    return CustomPaint(
      painter: GridPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildPlayerPositions(BuildContext context, Room room) {
    final players = room.players;
    final gameService = context.read<FirebaseGameService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widgets = <Widget>[];
        
        // Calculate how many positions to show based on player count
        final numPlayers = players.length;
        final numPositions = _calculateNumPositions(numPlayers);
        
        // Reorganize players for the calculated positions
        final reorganizedPlayers = _reorganizePlayers(players, gameService.currentPlayerId, numPositions);
        
        // Create positions based on player count
        for (int i = 0; i < numPositions; i++) {
          final player = reorganizedPlayers.length > i ? reorganizedPlayers[i] : null;
          final position = _getPlayerPosition(i, constraints.maxWidth, constraints.maxHeight, numPositions);
          
          final isCurrentTurn = player?.id == room.currentPlayer;
          print('DEBUG: Player ${player?.id} at position $i, room.currentPlayer: ${room.currentPlayer}, isCurrentTurn: $isCurrentTurn');
          
          widgets.add(
            Positioned(
              left: position.dx,
              top: position.dy,
              child: KarmaPalacePlayerWidget(
                player: player,
                position: i,
                isCurrentTurn: isCurrentTurn,
                isMyPlayer: i == _getMyPlayerPosition(numPositions), // Dynamic position for current player
                onCardTap: _onCardTap,
              ),
            ),
          );
        }
        
        return Stack(children: widgets);
      },
    );
  }

  /// Calculate how many positions to show based on player count
  int _calculateNumPositions(int numPlayers) {
    if (numPlayers <= 2) return 2; // 2 players: just show 2 positions
    if (numPlayers <= 4) return 4; // 3-4 players: show 4 positions
    return 6; // 5-6 players: show all 6 positions
  }

  /// Get the position index for the current player based on total positions
  int _getMyPlayerPosition(int numPositions) {
    if (numPositions == 2) return 1; // Bottom position for 2 players
    if (numPositions == 4) return 2; // Bottom position for 4 players
    return 3; // Bottom position for 6 players
  }

  List<Player> _reorganizePlayers(List<Player> players, String? currentPlayerId, int numPositions) {
    if (players.isEmpty) return players;
    
    print('DEBUG: Reorganizing players. Current player ID: $currentPlayerId');
    print('DEBUG: Original players: ${players.map((p) => p.id).toList()}');
    print('DEBUG: Number of positions: $numPositions');
    
    // Find current player
    final currentPlayerIndex = players.indexWhere((p) => p.id == currentPlayerId);
    if (currentPlayerIndex == -1) return players;
    
    print('DEBUG: Current player found at index: $currentPlayerIndex');
    
    // Create new list with current player at the appropriate position
    final reorganized = <Player>[];
    final myPosition = _getMyPlayerPosition(numPositions);
    
    // Add other players first
    for (int i = 0; i < players.length; i++) {
      if (i != currentPlayerIndex) {
        reorganized.add(players[i]);
      }
    }
    
    // Ensure current player is at the correct position
    while (reorganized.length < myPosition) {
      reorganized.add(Player(
        id: '', 
        name: '', 
        hand: [], 
        faceUp: [], 
        faceDown: [],
        isConnected: false,
        isPlaying: false,
        lastSeen: DateTime.now(),
        turnOrder: 0,
      ));
    }
    reorganized.insert(myPosition, players[currentPlayerIndex]);
    
    print('DEBUG: Reorganized players: ${reorganized.map((p) => p.id).toList()}');
    print('DEBUG: Player at position $myPosition: ${reorganized[myPosition].id}');
    
    return reorganized;
  }

  Offset _getPlayerPosition(int index, double width, double height, int numPositions) {
    // Use a more structured layout with proper spacing
    const playerWidth = playerAreaWidth;
    const playerHeight = playerAreaHeight;
    const margin = 20.0;
    
    // Position players based on number of positions
    switch (numPositions) {
      case 2:
        // 2 players: top and bottom
        switch (index) {
          case 0: // Top (other player)
            return Offset((width - playerWidth) / 2, margin);
          case 1: // Bottom (current player)
            return Offset((width - playerWidth) / 2, height - playerHeight - margin);
          default:
            return const Offset(0, 0);
        }
      case 4:
        // 4 players: top, left, right, bottom
        switch (index) {
          case 0: // Top (other player)
            return Offset((width - playerWidth) / 2, margin);
          case 1: // Left (other player)
            return Offset(margin, (height - playerHeight) / 2);
          case 2: // Bottom (current player)
            return Offset((width - playerWidth) / 2, height - playerHeight - margin);
          case 3: // Right (other player)
            return Offset(width - playerWidth - margin, (height - playerHeight) / 2);
          default:
            return const Offset(0, 0);
        }
      case 6:
        // 6 players: full layout
        switch (index) {
          case 0: // Top (other player)
            return Offset((width - playerWidth) / 2, margin);
          case 1: // Top-right (other player)
            return Offset(width - playerWidth - margin, margin + 30);
          case 2: // Bottom-right (other player)
            return Offset(width - playerWidth - margin, height - playerHeight - margin - 30);
          case 3: // Bottom (current player)
            return Offset((width - playerWidth) / 2, height - playerHeight - margin);
          case 4: // Bottom-left (other player)
            return Offset(margin, height - playerHeight - margin - 30);
          case 5: // Top-left (other player)
            return Offset(margin, margin + 30);
          default:
            return const Offset(0, 0);
        }
      default:
        return const Offset(0, 0);
    }
  }

  Widget _buildGameOverlay(BuildContext context, KarmaPalaceGameState gameState) {
    return Container(
      color: Colors.black54,
      child: Center(
                  child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gameState.winner != null 
                    ? '${gameState.winner!.name} Wins!'
                    : 'Game Over',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Handle rematch or return to lobby
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= 6; i++) {
      final y = (size.height / 6) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 