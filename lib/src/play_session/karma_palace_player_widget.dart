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

  // Multi-card selection support
  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;

  const KarmaPalacePlayerWidget({
    super.key,
    required this.player,
    required this.position,
    required this.isCurrentTurn,
    required this.isMyPlayer,
    this.onCardTap,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    if (player == null) {
      return _buildEmptyPlayerSlot(context, palette);
    }

    return Consumer<KarmaPalaceGameState>(
      builder: (context, gameState, child) {
        final currentIsCurrentTurn = gameState.gameInProgress && player?.id == gameState.room?.currentPlayer;

        return _PlayerAreaContainer(
          isCurrentTurn: currentIsCurrentTurn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player name + turn badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player!.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: currentIsCurrentTurn ? Colors.white : Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentIsCurrentTurn) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15), // yellow
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TURN',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Face-down + face-up cards (stacked)
              _buildStackedCardZone(
                context,
                player!.faceDown,
                player!.faceUp,
                player!.hand,
                isMyPlayer: isMyPlayer,
                isCurrentTurn: currentIsCurrentTurn,
              ),

              if (isMyPlayer)
                _buildCardZone(
                  context,
                  player!.hand,
                  isHand: true,
                  isCurrentTurn: currentIsCurrentTurn,
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
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add, color: Colors.white24, size: 24),
          SizedBox(height: 8),
          Text('Empty', style: TextStyle(fontSize: 12, color: Colors.white30)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isHand ? 'Hand' : isFaceDown ? 'Down' : 'Up',
              style: TextStyle(
                fontSize: 8,
                color: isHand ? const Color(0xFF60A5FA) : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isHand && cards.length > 3) ...[
              const SizedBox(width: 4),
              Text(
                '(${cards.length})',
                style: const TextStyle(fontSize: 7, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
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
                          child: Builder(builder: (context) {
                            final isPlayable = isHand && isCurrentTurn;
                            if (isHand) {
                              dev.log('Card ${cards[i].displayString} - isPlayable: $isPlayable');
                            }
                            return KarmaPalaceCardWidget(
                              card: cards[i],
                              isFaceDown: isFaceDown,
                              isPlayable: isPlayable,
                              size: const Size(playerCardWidth, playerCardHeight),
                              onTap: onCardTap != null
                                  ? () => onCardTap!(cards[i], isHand ? 'hand' : isFaceDown ? 'faceDown' : 'faceUp')
                                  : null,
                              isSelected: selectedCardIds?.contains(cards[i].id) ?? false,
                              isMultiSelectMode: isMultiSelectMode,
                              isMultiSelectEligible: isMultiSelectMode &&
                                  multiSelectValue == cards[i].value &&
                                  multiSelectSourceZone == (isHand ? 'hand' : isFaceDown ? 'faceDown' : 'faceUp'),
                            );
                          }),
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
                              ? Builder(builder: (context) {
                                  final isPlayable = isHand && isCurrentTurn;
                                  if (isHand) {
                                    dev.log('Card ${cards[i].displayString} - isPlayable: $isPlayable');
                                  }
                                  return KarmaPalaceCardWidget(
                                    card: cards[i],
                                    isFaceDown: isFaceDown,
                                    isPlayable: isPlayable,
                                    size: const Size(playerCardWidth, playerCardHeight),
                                    onTap: onCardTap != null
                                        ? () => onCardTap!(cards[i], isHand ? 'hand' : isFaceDown ? 'faceDown' : 'faceUp')
                                        : null,
                                    isSelected: selectedCardIds?.contains(cards[i].id) ?? false,
                                    isMultiSelectMode: isMultiSelectMode,
                                    isMultiSelectEligible: isMultiSelectMode &&
                                        multiSelectValue == cards[i].value &&
                                        multiSelectSourceZone == (isHand ? 'hand' : isFaceDown ? 'faceDown' : 'faceUp'),
                                  );
                                })
                              : Container(
                                  width: playerCardWidth,
                                  height: playerCardHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: Colors.white24),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Down',
              style: TextStyle(
                fontSize: 8,
                color: isMyPlayer ? const Color(0xFF60A5FA) : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Up',
              style: TextStyle(
                fontSize: 8,
                color: isMyPlayer ? const Color(0xFF60A5FA) : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 1.5 * playerCardHeight,
          width: 3 * playerCardWidth,
          child: Stack(
            children: [
              // Face-down cards (bottom layer)
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * playerCardWidth,
                  bottom: 6.0,
                  child: i < faceDownCards.length
                      ? KarmaPalaceCardWidget(
                          card: faceDownCards[i],
                          isFaceDown: true,
                          isPlayable: isMyPlayer && isCurrentTurn && faceUpCards.isEmpty,
                          size: const Size(playerCardWidth, playerCardHeight),
                          onTap: onCardTap != null ? () => onCardTap!(faceDownCards[i], 'faceDown') : null,
                          isSelected: selectedCardIds?.contains(faceDownCards[i].id) ?? false,
                          isMultiSelectMode: isMultiSelectMode,
                          isMultiSelectEligible: isMultiSelectMode &&
                              multiSelectValue == faceDownCards[i].value &&
                              multiSelectSourceZone == 'faceDown',
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                ),
              // Face-up cards (top layer)
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * playerCardWidth,
                  top: 0.0,
                  child: i < faceUpCards.length
                      ? KarmaPalaceCardWidget(
                          card: faceUpCards[i],
                          isFaceDown: false,
                          isPlayable: isMyPlayer && isCurrentTurn && handCards.isEmpty,
                          size: const Size(playerCardWidth, playerCardHeight),
                          onTap: onCardTap != null ? () => onCardTap!(faceUpCards[i], 'faceUp') : null,
                          isSelected: selectedCardIds?.contains(faceUpCards[i].id) ?? false,
                          isMultiSelectMode: isMultiSelectMode,
                          isMultiSelectEligible: isMultiSelectMode &&
                              multiSelectValue == faceUpCards[i].value &&
                              multiSelectSourceZone == 'faceUp',
                        )
                      : Container(
                          width: playerCardWidth,
                          height: playerCardHeight,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.white24),
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

class _PlayerAreaContainer extends StatefulWidget {
  final bool isCurrentTurn;
  final Widget child;

  const _PlayerAreaContainer({
    required this.isCurrentTurn,
    required this.child,
  });

  @override
  State<_PlayerAreaContainer> createState() => _PlayerAreaContainerState();
}

class _PlayerAreaContainerState extends State<_PlayerAreaContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 8, end: 24).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCurrentTurn) {
      return Container(
        width: playerAreaWidth,
        height: playerAreaHeight,
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Container(
        width: playerAreaWidth,
        height: playerAreaHeight,
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFACC15).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFACC15).withValues(alpha: 0.6),
              blurRadius: _glow.value,
              spreadRadius: _glow.value / 3,
            ),
            BoxShadow(
              color: const Color(0xFFFACC15).withValues(alpha: 0.25),
              blurRadius: _glow.value * 2,
              spreadRadius: _glow.value / 2,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
