import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';
import '../../constants/number_constants.dart';
import 'karma_palace_card_widget.dart';
import '../game_internals/karma_palace_game_state.dart';

class KarmaPalacePlayerWidget extends StatelessWidget {
  final Player? player;
  final int position;
  final bool isCurrentTurn;
  final bool isMyPlayer;
  final Function(game_card.Card, String)? onCardTap;

  const KarmaPalacePlayerWidget({
    super.key,
    required this.player,
    required this.position,
    required this.isCurrentTurn,
    required this.isMyPlayer,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    if (player == null) {
      return _buildEmptyPlayerSlot(context, palette);
    }

    return Consumer<KarmaPalaceGameState>(
      builder: (context, gameState, child) {
        // Recalculate isCurrentTurn based on current game state
        final currentIsCurrentTurn = player?.id == gameState.room?.currentPlayer;
        
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: currentIsCurrentTurn 
                ? palette.trueWhite.withOpacity(0.9)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: currentIsCurrentTurn ? palette.ink : Colors.grey,
              width: currentIsCurrentTurn ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player name
              Text(
                player!.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: currentIsCurrentTurn ? palette.ink : Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Card zones
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Face down and face up cards (stacked)
                  _buildStackedCardZone(
                    context,
                    player!.faceDown,
                    player!.faceUp,
                    isMyPlayer: isMyPlayer,
                    isCurrentTurn: currentIsCurrentTurn,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Hand cards (3 cards)
                  _buildCardZone(
                    context,
                    player!.hand,
                    isHand: true,
                    isMyPlayer: isMyPlayer,
                    isCurrentTurn: currentIsCurrentTurn,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Card count
              Text(
                '${player!.totalCards} cards',
                style: TextStyle(
                  fontSize: 10,
                  color: currentIsCurrentTurn ? palette.ink : Colors.white70,
                ),
              ),
              
              // Turn indicator
              if (currentIsCurrentTurn)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.ink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TURN',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );


  }

  Widget _buildEmptyPlayerSlot(BuildContext context, Palette palette) {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add,
            color: Colors.grey.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Empty',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardZone(
    BuildContext context,
    List<game_card.Card> cards,
    {
      bool isFaceDown = false,
      bool isHand = false,
      bool isMyPlayer = false,
      bool isCurrentTurn = false,
    }
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zone label
        Text(
          isHand ? 'Hand' : isFaceDown ? 'Down' : 'Up',
          style: TextStyle(
            fontSize: 8,
            color: isMyPlayer ? Colors.blue : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Cards
        Container(
          height: 40,
          width: 45, // Further reduced width to prevent overflow
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 5.0, // Reduced spacing
                  child: i < cards.length
                      ? Builder(
                          builder: (context) {
                            final isPlayable = isMyPlayer && isHand && isCurrentTurn;
                            if (isMyPlayer && isHand) {
                              print('DEBUG: Card ${cards[i].displayString} - isMyPlayer: $isMyPlayer, isHand: $isHand, isCurrentTurn: $isCurrentTurn, isPlayable: $isPlayable');
                            }
                            return KarmaPalaceCardWidget(
                              card: cards[i],
                              isFaceDown: isFaceDown,
                              isPlayable: isPlayable,
                              size: const Size(playerCardWidth, playerCardHeight),
                              onTap: onCardTap != null ? () => onCardTap!(cards[i], isHand ? 'hand' : isFaceDown ? 'faceDown' : 'faceUp') : null,
                            );
                          },
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStackedCardZone(
    BuildContext context,
    List<game_card.Card> faceDownCards,
    List<game_card.Card> faceUpCards,
    {
      bool isMyPlayer = false,
      bool isCurrentTurn = false,
    }
  ) {
    return Column(
      children: [
        // Zone labels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Down',
              style: TextStyle(
                fontSize: 8,
                color: isMyPlayer ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Up',
              style: TextStyle(
                fontSize: 8,
                color: isMyPlayer ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Stacked cards
        Container(
          height: 50, // Slightly taller for stacked cards
          width: 45, // Reduced to match other zones
          child: Stack(
            children: [
              // Face down cards (bottom layer)
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 6.0,
                  top: 2.0, // Slightly offset down
                  child: i < faceDownCards.length
                      ? KarmaPalaceCardWidget(
                          card: faceDownCards[i],
                          isFaceDown: true,
                          isPlayable: isMyPlayer && isCurrentTurn,
                          size: const Size(playerCardWidth, playerCardHeight),
                          onTap: onCardTap != null ? () => onCardTap!(faceDownCards[i], 'faceDown') : null,
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
              // Face up cards (top layer)
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 6.0,
                  top: 0.0, // Slightly offset up
                  child: i < faceUpCards.length
                      ? KarmaPalaceCardWidget(
                          card: faceUpCards[i],
                          isFaceDown: false,
                          isPlayable: isMyPlayer && isCurrentTurn,
                          size: const Size(playerCardWidth, playerCardHeight),
                          onTap: onCardTap != null ? () => onCardTap!(faceUpCards[i], 'faceUp') : null,
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 