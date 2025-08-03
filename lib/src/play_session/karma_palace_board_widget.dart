import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_internals/karma_palace_game_state.dart';
import '../games_services/firebase_game_service.dart';
import '../model/firebase/room.dart';
import '../style/palette.dart';
import 'karma_palace_player_widget.dart';
import 'karma_palace_play_pile_widget.dart';

class KarmaPalaceBoardWidget extends StatelessWidget {
  const KarmaPalaceBoardWidget({super.key});

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
        
        // Create 6 player positions (0-5)
        for (int i = 0; i < 6; i++) {
          final player = players.length > i ? players[i] : null;
          final position = _getPlayerPosition(i, constraints.maxWidth, constraints.maxHeight);
          
          widgets.add(
            Positioned(
              left: position.dx,
              top: position.dy,
              child: KarmaPalacePlayerWidget(
                player: player,
                position: i,
                isCurrentTurn: player?.id == room.currentPlayer,
                isMyPlayer: player?.id == gameService.currentPlayerId,
              ),
            ),
          );
        }
        
        return Stack(children: widgets);
      },
    );
  }

  Offset _getPlayerPosition(int index, double width, double height) {
    // Use a more structured layout with proper spacing
    final playerWidth = 100.0;
    final playerHeight = 140.0;
    final margin = 20.0;
    
    // Calculate safe area (accounting for player widget size)
    final safeWidth = width - (playerWidth + margin * 2);
    final safeHeight = height - (playerHeight + margin * 2);
    
    // Position players in a structured layout
    switch (index) {
      case 0: // Top
        return Offset((width - playerWidth) / 2, margin);
      case 1: // Top-right
        return Offset(width - playerWidth - margin, margin + 40);
      case 2: // Bottom-right
        return Offset(width - playerWidth - margin, height - playerHeight - margin - 40);
      case 3: // Bottom
        return Offset((width - playerWidth) / 2, height - playerHeight - margin);
      case 4: // Bottom-left
        return Offset(margin, height - playerHeight - margin - 40);
      case 5: // Top-left
        return Offset(margin, margin + 40);
      default:
        return Offset(0, 0);
    }
  }

  Widget _buildGameOverlay(BuildContext context, KarmaPalaceGameState gameState) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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