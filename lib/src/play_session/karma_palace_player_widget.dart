import 'dart:developer' as dev;
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
        final currentIsCurrentTurn =
            player?.id == gameState.room?.currentPlayer;

        return Container(
          width: playerAreaWidth,
          height: playerAreaHeight,
          decoration: BoxDecoration(
            color: currentIsCurrentTurn
                ? palette.trueWhite.withValues(alpha: 0.9)
                : Colors.grey.withValues(alpha: 0.3),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player!.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: currentIsCurrentTurn ? palette.cardInk : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Turn indicator
                  if (currentIsCurrentTurn)
                    Container(
                      margin: const EdgeInsets.only(left: 2.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2.0, vertical: 1.0),
                      decoration: BoxDecoration(
                        color: palette.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TURN',
                        style: TextStyle(
                          fontSize: 8.0,
                          color: palette.cardInk,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // Face down and face up cards (stacked)
              _buildStackedCardZone(
                context,
                player!.faceDown,
                player!.faceUp,
                player!.hand,
                isMyPlayer: isMyPlayer,
                isCurrentTurn: currentIsCurrentTurn,
              ),

              if (isMyPlayer)
                // Hand cards (3 cards)
                _buildCardZone(
                  context,
                  player!.hand,
                  isHand: true,
                  isCurrentTurn: currentIsCurrentTurn,
                ),

              // Card count
              // Text(
              //   '${player!.totalCards} cards',
              //   style: TextStyle(
              //     fontSize: 10,
              //     color: currentIsCurrentTurn ? palette.ink : Colors.white70,
              //   ),
              // ),
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
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add,
            color: Colors.grey.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Empty',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardZone(
    BuildContext context,
    List<game_card.Card> cards, {
    bool isFaceDown = false,
    bool isHand = false,
    bool isCurrentTurn = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zone label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isHand
                  ? 'Hand'
                  : isFaceDown
                      ? 'Down'
                      : 'Up',
              style: const TextStyle(
                fontSize: 8,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isHand && cards.length > 3) ...[
              const SizedBox(width: 4),
              Text(
                '(${cards.length})',
                style: const TextStyle(
                  fontSize: 7,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 4),

        // Cards
        SizedBox(
          height: playerCardHeight,
          child: isHand && cards.length > 3
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < cards.length; i++)
                        Padding(
                          padding: EdgeInsets.only(right: i < cards.length - 1 ? 2.0 : 0),
                          child: Builder(
                            builder: (context) {
                              final isPlayable = isHand && isCurrentTurn;
                              if (isHand) {
                                dev.log(
                                    'DEBUG: Card ${cards[i].displayString} - isHand: $isHand, isCurrentTurn: $isCurrentTurn, isPlayable: $isPlayable');
                              }
                              return KarmaPalaceCardWidget(
                                card: cards[i],
                                isFaceDown: isFaceDown,
                                isPlayable: isPlayable,
                                size: const Size(playerCardWidth, playerCardHeight),
                                onTap: onCardTap != null
                                    ? () => onCardTap!(
                                        cards[i],
                                        isHand
                                            ? 'hand'
                                            : isFaceDown
                                                ? 'faceDown'
                                                : 'faceUp')
                                    : null,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                )
              : SizedBox(
                  width: 3 * playerCardWidth,
                  child: Stack(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Positioned(
                          left: i * playerCardWidth,
                          child: i < cards.length
                              ? Builder(
                                  builder: (context) {
                                    final isPlayable = isHand && isCurrentTurn;
                                    if (isHand) {
                                      dev.log(
                                          'DEBUG: Card ${cards[i].displayString} - isHand: $isHand, isCurrentTurn: $isCurrentTurn, isPlayable: $isPlayable');
                                    }
                                    return KarmaPalaceCardWidget(
                                      card: cards[i],
                                      isFaceDown: isFaceDown,
                                      isPlayable: isPlayable,
                                      size: const Size(playerCardWidth, playerCardHeight),
                                      onTap: onCardTap != null
                                          ? () => onCardTap!(
                                              cards[i],
                                              isHand
                                                  ? 'hand'
                                                  : isFaceDown
                                                      ? 'faceDown'
                                                      : 'faceUp')
                                          : null,
                                    );
                                  },
                                )
                              : Container(
                                  width: playerCardWidth,
                                  height: playerCardHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStackedCardZone(
    BuildContext context,
    List<game_card.Card> faceDownCards,
    List<game_card.Card> faceUpCards,
    List<game_card.Card> handCards, {
    bool isMyPlayer = false,
    bool isCurrentTurn = false,
  }) {
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
        SizedBox(
          height: 1.5 * playerCardHeight,
          width: 3 * playerCardWidth,
          child: Stack(
            children: [
              // Face down cards (bottom layer)
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * playerCardWidth,
                  // top: 2.0, // Slightly offset down
                  bottom: 6.0,
                  child: i < faceDownCards.length
                      ? KarmaPalaceCardWidget(
                          card: faceDownCards[i],
                          isFaceDown: true,
                          isPlayable: isMyPlayer && isCurrentTurn && faceUpCards.isEmpty,
                          size: const Size(playerCardWidth, playerCardHeight),
                          onTap: onCardTap != null
                              ? () => onCardTap!(faceDownCards[i], 'faceDown')
                              : null,
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                ),
              // Face up cards (top layer)
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * playerCardWidth,
                  top: 0.0, // Slightly offset up
                  child: i < faceUpCards.length
                      ? KarmaPalaceCardWidget(
                          card: faceUpCards[i],
                          isFaceDown: false,
                          isPlayable: isMyPlayer && isCurrentTurn && handCards.isEmpty,
                          size: const Size(playerCardWidth, playerCardHeight),
                          onTap: onCardTap != null
                              ? () => onCardTap!(faceUpCards[i], 'faceUp')
                              : null,
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.5),
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
