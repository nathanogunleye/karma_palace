import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'karma_palace_player_widget.dart';
import 'karma_palace_play_pile_widget.dart';

class SinglePlayerBoardWidget extends StatelessWidget {
  final Function(game_card.Card, String)? onCardTap;

  const SinglePlayerBoardWidget({
    super.key,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final gameState = context.watch<KarmaPalaceGameState>();
    final room = gameState.room;

    if (room == null) {
      return const Center(
        child: Text('No game data available'),
      );
    }

    // Find human and AI players
    final humanPlayer = room.players.firstWhere(
      (p) => p.id == gameState.currentPlayerId,
      orElse: () => room.players.first,
    );
    
    final aiPlayer = room.players.firstWhere(
      (p) => p.id != gameState.currentPlayerId,
      orElse: () => room.players.last,
    );

    return Container(
      color: palette.backgroundMain,
      child: Column(
        children: [
          // AI Player (top)
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(8),
              child: KarmaPalacePlayerWidget(
                player: aiPlayer,
                position: 0,
                isCurrentTurn: room.currentPlayer == aiPlayer.id,
                isMyPlayer: false,
                onCardTap: null, // AI cards are not interactive
              ),
            ),
          ),

          // Central Play Area
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // Left side - Game info
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Deck: ${room.deck.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.ink,
                          ),
                        ),
                        // const SizedBox(height: 8),
                        Text(
                          'Turn: ${room.currentPlayer == humanPlayer.id ? "Your Turn" : "AI Turn"}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: room.currentPlayer == humanPlayer.id
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center - Play Pile
                  Expanded(
                    flex: 2,
                    child: KarmaPalacePlayPileWidget(
                      playPile: room.playPile,
                      topCard: room.playPile.isNotEmpty ? room.playPile.last : null,
                    ),
                  ),

                  // Right side - Game status
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Status: ${room.gameState.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (room.resetActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'RESET ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Human Player (bottom)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(8),
              child: KarmaPalacePlayerWidget(
                player: humanPlayer,
                position: 1,
                isCurrentTurn: room.currentPlayer == humanPlayer.id,
                isMyPlayer: true,
                onCardTap: onCardTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
