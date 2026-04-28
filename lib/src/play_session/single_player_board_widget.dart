import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';

import 'karma_palace_card_widget.dart';
import 'package:karma_palace/src/games_services/local_game_service.dart';

class SinglePlayerBoardWidget extends StatelessWidget {
  final Function(game_card.Card, String)? onCardTap;

  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;
  final String? inlineMessage;
  final Color inlineMessageColor;

  const SinglePlayerBoardWidget({
    super.key,
    this.onCardTap,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
    this.inlineMessage,
    this.inlineMessageColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<LocalGameService>();
    final room = gameService.currentRoom;

    if (room == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final humanPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.last,
    );

    final otherPlayers = room.players
        .where((p) => p.id != gameService.currentPlayerId)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = otherPlayers.length == 1
        ? screenWidth - 24
        : (screenWidth - 40) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Other players grid
        if (otherPlayers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: otherPlayers
                  .map((p) => _OtherPlayerTile(
                        player: p,
                        isCurrentTurn: p.id == room.currentPlayer,
                        tileWidth: tileWidth,
                      ))
                  .toList(),
            ),
          ),

        const Spacer(),

        // Deck + Pile
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DeckTile(deckCount: room.deck.length),
            const SizedBox(width: 32),
            _PileTile(playPile: room.playPile),
          ],
        ),

        const Spacer(),

        // Fixed-height slot above player card area — always reserves space so layout never shifts
        SizedBox(
          height: 44,
          child: inlineMessage != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: inlineMessageColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      inlineMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : null,
        ),

        // Current player zones
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _CurrentPlayerZones(
            player: humanPlayer,
            isCurrentTurn: room.currentPlayer == humanPlayer.id,
            onCardTap: onCardTap,
            selectedCardIds: selectedCardIds,
            isMultiSelectMode: isMultiSelectMode,
            multiSelectValue: multiSelectValue,
            multiSelectSourceZone: multiSelectSourceZone,
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Other player tile ──────────────────────────────────────────────────────

class _OtherPlayerTile extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final double tileWidth;

  const _OtherPlayerTile({
    required this.player,
    required this.isCurrentTurn,
    required this.tileWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileWidth,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentTurn ? const Color(0x33FACC15) : const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentTurn ? const Color(0xFFFACC15) : const Color(0x33FFFFFF),
          width: isCurrentTurn ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name + TURN badge
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCurrentTurn ? Colors.white : Colors.white60,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrentTurn) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TURN',
                    style: TextStyle(fontSize: 7, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Hand count badge + visible cards
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hand count
              Container(
                width: 36,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0x66FFFFFF)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${player.hand.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'cards',
                      style: TextStyle(fontSize: 7, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Face-up cards (or face-down backs if none)
              if (player.faceUp.isNotEmpty)
                ...player.faceUp.take(3).map((card) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: KarmaPalaceCardWidget(
                        card: card,
                        isFaceDown: false,
                        isPlayable: false,
                        size: const Size(32, 46),
                      ),
                    ))
              else
                ...player.faceDown.take(3).map((_) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Container(
                        width: 32,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0x66FFFFFF), width: 0.5),
                        ),
                      ),
                    )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Deck tile ──────────────────────────────────────────────────────────────

class _DeckTile extends StatelessWidget {
  final int deckCount;

  const _DeckTile({required this.deckCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'DECK',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white60,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 62,
          height: 88,
          decoration: BoxDecoration(
            gradient: deckCount > 0
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  )
                : null,
            color: deckCount == 0 ? Colors.white10 : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
          ),
          child: Center(
            child: deckCount > 0
                ? Text(
                    '$deckCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : const Icon(Icons.inbox_outlined, size: 24, color: Colors.white38),
          ),
        ),
      ],
    );
  }
}

// ── Pile tile ──────────────────────────────────────────────────────────────

class _PileTile extends StatelessWidget {
  final List<game_card.Card> playPile;

  const _PileTile({required this.playPile});

  @override
  Widget build(BuildContext context) {
    const cardW = 62.0;
    const cardH = 88.0;
    const stackOffset = 20.0;

    final visible = playPile.length > 3
        ? playPile.sublist(playPile.length - 3)
        : List<game_card.Card>.from(playPile);
    final n = visible.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playPile.isNotEmpty ? 'PILE (${playPile.length})' : 'PILE',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        if (playPile.isNotEmpty)
          SizedBox(
            width: cardW + stackOffset * 2,
            height: cardH,
            child: Stack(
              children: [
                for (int i = 0; i < n; i++)
                  Positioned(
                    left: i * stackOffset,
                    top: 0,
                    child: KarmaPalaceCardWidget(
                      card: visible[i],
                      isFaceDown: false,
                      isPlayable: false,
                      size: const Size(cardW, cardH),
                    ),
                  ),
              ],
            ),
          )
        else
          Container(
            width: cardW,
            height: cardH,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 24, color: Colors.white38),
                SizedBox(height: 4),
                Text('Empty', style: TextStyle(fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Current player zones ───────────────────────────────────────────────────

class _CurrentPlayerZones extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final Function(game_card.Card, String)? onCardTap;
  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;

  const _CurrentPlayerZones({
    required this.player,
    required this.isCurrentTurn,
    this.onCardTap,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrentTurn ? const Color(0x33FACC15) : const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? const Color(0xFFFACC15) : const Color(0x33FFFFFF),
          width: isCurrentTurn ? 1.5 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Uniform card size: 3 cards across half the inner width (with 8px column gap)
          final cardW = ((constraints.maxWidth - 8) / 6).clamp(0.0, 58.0);
          final cardH = cardW * (46 / 32);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "You" header
              Row(
                children: [
                  const Text(
                    'You',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (isCurrentTurn) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'YOUR TURN',
                        style: TextStyle(fontSize: 7, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Face Down + Face Up on top
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CardZoneColumn(
                      label: 'Face Down',
                      cards: player.faceDown,
                      isFaceDown: true,
                      isPlayable: isCurrentTurn && player.hand.isEmpty && player.faceUp.isEmpty,
                      zone: 'faceDown',
                      cardW: cardW,
                      cardH: cardH,
                      onCardTap: onCardTap,
                      selectedCardIds: selectedCardIds,
                      isMultiSelectMode: isMultiSelectMode,
                      multiSelectValue: multiSelectValue,
                      multiSelectSourceZone: multiSelectSourceZone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardZoneColumn(
                      label: 'Face Up',
                      cards: player.faceUp,
                      isFaceDown: false,
                      isPlayable: isCurrentTurn && player.hand.isEmpty,
                      zone: 'faceUp',
                      cardW: cardW,
                      cardH: cardH,
                      onCardTap: onCardTap,
                      selectedCardIds: selectedCardIds,
                      isMultiSelectMode: isMultiSelectMode,
                      multiSelectValue: multiSelectValue,
                      multiSelectSourceZone: multiSelectSourceZone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Hand below — full width, centred
              Center(
                child: _CardZoneColumn(
                  label: 'Hand',
                  cards: player.hand,
                  isFaceDown: false,
                  isPlayable: isCurrentTurn,
                  zone: 'hand',
                  isHand: true,
                  cardW: cardW,
                  cardH: cardH,
                  onCardTap: onCardTap,
                  selectedCardIds: selectedCardIds,
                  isMultiSelectMode: isMultiSelectMode,
                  multiSelectValue: multiSelectValue,
                  multiSelectSourceZone: multiSelectSourceZone,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Single card zone column ────────────────────────────────────────────────

class _CardZoneColumn extends StatelessWidget {
  final String label;
  final List<game_card.Card> cards;
  final bool isFaceDown;
  final bool isPlayable;
  final String zone;
  final bool isHand;
  final double cardW;
  final double cardH;
  final Function(game_card.Card, String)? onCardTap;
  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;

  const _CardZoneColumn({
    required this.label,
    required this.cards,
    required this.isFaceDown,
    required this.isPlayable,
    required this.zone,
    required this.cardW,
    required this.cardH,
    this.isHand = false,
    this.onCardTap,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
  });

  bool _isEligible(game_card.Card card) =>
      isMultiSelectMode &&
      multiSelectValue == card.value &&
      multiSelectSourceZone == zone;

  @override
  Widget build(BuildContext context) {
    final displayCards = isHand
        ? ([...cards]..sort((a, b) => a.numericValue.compareTo(b.numericValue)))
        : cards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isHand ? const Color(0xFF60A5FA) : Colors.white60,
          ),
        ),
        const SizedBox(height: 4),
        isHand && displayCards.length > 3
            ? SizedBox(
                width: double.infinity,
                height: cardH,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < displayCards.length; i++)
                        Padding(
                          padding: EdgeInsets.only(right: i < displayCards.length - 1 ? 2.0 : 0),
                          child: KarmaPalaceCardWidget(
                            card: displayCards[i],
                            isFaceDown: isFaceDown,
                            isPlayable: isPlayable,
                            size: Size(cardW, cardH),
                            onTap: onCardTap != null ? () => onCardTap!(displayCards[i], zone) : null,
                            isSelected: selectedCardIds?.contains(displayCards[i].id) ?? false,
                            isMultiSelectMode: isMultiSelectMode,
                            isMultiSelectEligible: _isEligible(displayCards[i]),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                width: cardW * 3,
                height: cardH,
                child: Stack(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Positioned(
                        left: i * cardW,
                        child: i < displayCards.length
                            ? KarmaPalaceCardWidget(
                                card: displayCards[i],
                                isFaceDown: isFaceDown,
                                isPlayable: isPlayable,
                                size: Size(cardW, cardH),
                                onTap: onCardTap != null ? () => onCardTap!(displayCards[i], zone) : null,
                                isSelected: selectedCardIds?.contains(displayCards[i].id) ?? false,
                                isMultiSelectMode: isMultiSelectMode,
                                isMultiSelectEligible: _isEligible(displayCards[i]),
                              )
                            : Container(
                                width: cardW,
                                height: cardH,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(3),
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
