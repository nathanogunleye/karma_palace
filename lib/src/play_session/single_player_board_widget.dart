import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;

import 'karma_palace_player_widget.dart';
import 'karma_palace_play_pile_widget.dart';
import 'package:karma_palace/src/games_services/local_game_service.dart';

class SinglePlayerBoardWidget extends StatelessWidget {
  final Function(game_card.Card, String)? onCardTap;
  
  // Multi-card selection support
  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;

  const SinglePlayerBoardWidget({
    super.key,
    this.onCardTap,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
  });

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<LocalGameService>();

    final room = gameService.currentRoom;
    
    if (room == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final humanPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.last,
    );

    final aiPlayer = room.players.firstWhere(
      (p) => p.id != gameService.currentPlayerId,
      orElse: () => room.players.last,
    );

    // Don't show burn notification for empty pile - let the callback system handle it
    const bool showBurnNotification = false;

    return Column(
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
                        // Deck display
                        Container(
                          width: 44,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: room.deck.isNotEmpty
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                  )
                                : null,
                            color: room.deck.isEmpty ? Colors.white10 : null,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              room.deck.isNotEmpty ? '${room.deck.length}' : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Deck',
                          style: const TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.currentPlayer == humanPlayer.id ? 'Your Turn' : 'AI Turn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: room.currentPlayer == humanPlayer.id
                                ? const Color(0xFF4ADE80) // green-400
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
                      showBurnNotification: showBurnNotification,
                    ),
                  ),

                  // Right side - Game status
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.gameState.name.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
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
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(8),
              child: KarmaPalacePlayerWidget(
                player: humanPlayer,
                position: 1,
                isCurrentTurn: room.currentPlayer == humanPlayer.id,
                isMyPlayer: true,
                onCardTap: onCardTap,
                selectedCardIds: selectedCardIds,
                isMultiSelectMode: isMultiSelectMode,
                multiSelectValue: multiSelectValue,
                multiSelectSourceZone: multiSelectSourceZone,
              ),
            ),
          ),
        ],
      );
  }
}
