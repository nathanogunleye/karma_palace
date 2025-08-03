import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';
import 'karma_palace_card_widget.dart';

class KarmaPalacePlayerWidget extends StatelessWidget {
  final Player? player;
  final int position;
  final bool isCurrentTurn;
  final bool isMyPlayer;

  const KarmaPalacePlayerWidget({
    super.key,
    required this.player,
    required this.position,
    required this.isCurrentTurn,
    required this.isMyPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    if (player == null) {
      return _buildEmptyPlayerSlot(context, palette);
    }

    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: isCurrentTurn 
            ? palette.trueWhite.withOpacity(0.9)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentTurn ? palette.ink : Colors.grey,
          width: isCurrentTurn ? 2 : 1,
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
              color: isCurrentTurn ? palette.ink : Colors.white,
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
              // Face down cards (3 cards)
              _buildCardZone(
                context,
                player!.faceDown,
                isFaceDown: true,
                isMyPlayer: isMyPlayer,
              ),
              
              const SizedBox(width: 4),
              
              // Face up cards (3 cards)
              _buildCardZone(
                context,
                player!.faceUp,
                isFaceDown: false,
                isMyPlayer: isMyPlayer,
              ),
              
              const SizedBox(width: 4),
              
              // Hand cards (3 cards)
              _buildCardZone(
                context,
                player!.hand,
                isHand: true,
                isMyPlayer: isMyPlayer,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Card count
          Text(
            '${player!.totalCards} cards',
            style: TextStyle(
              fontSize: 10,
              color: isCurrentTurn ? palette.ink : Colors.white70,
            ),
          ),
          
          // Turn indicator
          if (isCurrentTurn)
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
          width: 50, // Reduced width to prevent overflow
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 6.0, // Reduced spacing
                  child: i < cards.length
                      ? KarmaPalaceCardWidget(
                          card: cards[i],
                          isFaceDown: isFaceDown,
                          isPlayable: isMyPlayer && isHand,
                          size: const Size(18, 28), // Smaller cards
                        )
                      : Container(
                          width: 18,
                          height: 28,
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