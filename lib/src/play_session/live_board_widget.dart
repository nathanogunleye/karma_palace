import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/games_services/firebase_game_service.dart';

import 'karma_palace_card_widget.dart';
import 'card_bounce_scope.dart';

class LiveBoardWidget extends StatelessWidget {
  final Function(game_card.Card, String, Offset)? onCardTap;
  final GlobalKey? pileKey;
  final GlobalKey? playerAreaKey;
  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;
  final String? inlineMessage;
  final Color inlineMessageColor;
  final bool isPreGame;

  const LiveBoardWidget({
    super.key,
    this.onCardTap,
    this.pileKey,
    this.playerAreaKey,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
    this.inlineMessage,
    this.inlineMessageColor = Colors.grey,
    this.isPreGame = false,
  });

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<FirebaseGameService>();
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

    return CardBounceScope(
      child: Column(
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
                    .map(
                      (p) => _OtherPlayerTile(
                        player: p,
                        isCurrentTurn:
                            room.gameState == GameState.playing &&
                            p.id == room.currentPlayer,
                        tileWidth: tileWidth,
                      ),
                    )
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
              SizedBox(
                key: pileKey,
                child: _PileTile(playPile: room.playPile),
              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
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
              key: playerAreaKey,
              player: humanPlayer,
              isCurrentTurn:
                  room.gameState == GameState.playing &&
                  room.currentPlayer == humanPlayer.id,
              isPreGame: isPreGame,
              onCardTap: onCardTap,
              selectedCardIds: selectedCardIds,
              isMultiSelectMode: isMultiSelectMode,
              multiSelectValue: multiSelectValue,
              multiSelectSourceZone: multiSelectSourceZone,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
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
    return _GlowingTileContainer(
      isCurrentTurn: isCurrentTurn,
      isOut: player.hasWon,
      width: tileWidth,
      padding: const EdgeInsets.all(8),
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
              if (player.hasWon) ...[
                const SizedBox(width: 4),
                const _StatusBadge(
                  label: 'OUT',
                  backgroundColor: Color(0xFF6B7280),
                  textColor: Colors.white,
                ),
              ] else if (isCurrentTurn) ...[
                const SizedBox(width: 4),
                const _StatusBadge(
                  label: 'TURN',
                  backgroundColor: Color(0xFFFACC15),
                  textColor: Colors.black,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (player.faceUp.isNotEmpty)
                ...player.faceUp
                    .take(3)
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: KarmaPalaceCardWidget(
                          card: card,
                          isFaceDown: false,
                          isPlayable: false,
                          size: const Size(34, 49),
                        ),
                      ),
                    )
              else
                ...player.faceDown
                    .take(3)
                    .map(
                      (_) => Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Container(
                          width: 34,
                          height: 49,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0x66FFFFFF),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
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
          width: 64,
          height: 90,
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
                : const Icon(
                    Icons.inbox_outlined,
                    size: 24,
                    color: Colors.white38,
                  ),
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
    const cardW = 64.0;
    const cardH = 90.0;
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
                Icon(Icons.inbox_outlined, size: 26, color: Colors.white38),
                SizedBox(height: 4),
                Text(
                  'Empty',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
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
  final bool isPreGame;
  final Function(game_card.Card, String, Offset)? onCardTap;
  final Set<String>? selectedCardIds;
  final bool isMultiSelectMode;
  final String? multiSelectValue;
  final String? multiSelectSourceZone;

  const _CurrentPlayerZones({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.isPreGame = false,
    this.onCardTap,
    this.selectedCardIds,
    this.isMultiSelectMode = false,
    this.multiSelectValue,
    this.multiSelectSourceZone,
  });

  @override
  Widget build(BuildContext context) {
    return _GlowingTileContainer(
      isCurrentTurn: isCurrentTurn,
      isOut: player.hasWon,
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Hand card size — unchanged
          final cardW = ((constraints.maxWidth - 2) / 6).clamp(0.0, 60.0);
          final cardH = cardW * (46 / 32);
          // Face-down/up: 2 zones × (3 cards + 2 gaps of 3pt) + 2pt zone divider = 14pt total, scaled down
          final faceCardW = (((constraints.maxWidth - 14) / 6) * 0.85).clamp(
            32.0,
            60.0,
          );
          final faceCardH = faceCardW * (46 / 32);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (player.hasWon) ...[
                    const SizedBox(width: 6),
                    const _StatusBadge(
                      label: 'OUT',
                      backgroundColor: Color(0xFF6B7280),
                      textColor: Colors.white,
                    ),
                  ] else if (isCurrentTurn) ...[
                    const SizedBox(width: 6),
                    const _StatusBadge(
                      label: 'YOUR TURN',
                      backgroundColor: Color(0xFFFACC15),
                      textColor: Colors.black,
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
                      isPlayable:
                          isCurrentTurn &&
                          player.hand.isEmpty &&
                          player.faceUp.isEmpty,
                      zone: 'faceDown',
                      cardW: faceCardW,
                      cardH: faceCardH,
                      onCardTap: onCardTap,
                      selectedCardIds: selectedCardIds,
                      isMultiSelectMode: isMultiSelectMode,
                      multiSelectValue: multiSelectValue,
                      multiSelectSourceZone: multiSelectSourceZone,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _CardZoneColumn(
                      label: 'Face Up',
                      cards: player.faceUp,
                      isFaceDown: false,
                      isPlayable:
                          isPreGame || (isCurrentTurn && player.hand.isEmpty),
                      zone: 'faceUp',
                      cardW: faceCardW,
                      cardH: faceCardH,
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
                  isPlayable: isPreGame || isCurrentTurn,
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
  final Function(game_card.Card, String, Offset)? onCardTap;
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
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth =
                      displayCards.length * cardW +
                      (displayCards.length - 1) * 3.0;
                  final cardWidgets = [
                    for (int i = 0; i < displayCards.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: i < displayCards.length - 1 ? 3.0 : 0,
                        ),
                        child: KarmaPalaceCardWidget(
                          card: displayCards[i],
                          isFaceDown: isFaceDown,
                          isPlayable: isPlayable,
                          size: Size(cardW, cardH),
                          onTap: null,
                          onTapWithCenter: onCardTap != null
                              ? (center) =>
                                    onCardTap!(displayCards[i], zone, center)
                              : null,
                          isSelected:
                              selectedCardIds?.contains(displayCards[i].id) ??
                              false,
                          isMultiSelectMode: isMultiSelectMode,
                          isMultiSelectEligible: _isEligible(displayCards[i]),
                        ),
                      ),
                  ];
                  return SizedBox(
                    height: cardH + 8,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: contentWidth <= constraints.maxWidth
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: cardWidgets,
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: cardWidgets),
                            ),
                    ),
                  );
                },
              )
            : SizedBox(
                width: cardW * 3 + 3 * 2,
                height: cardH + 8,
                child: Stack(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Positioned(
                        left: i * (cardW + 3),
                        bottom: 0,
                        child: i < displayCards.length
                            ? KarmaPalaceCardWidget(
                                card: displayCards[i],
                                isFaceDown: isFaceDown,
                                isPlayable: isPlayable,
                                size: Size(cardW, cardH),
                                onTap: null,
                                onTapWithCenter: onCardTap != null
                                    ? (center) => onCardTap!(
                                        displayCards[i],
                                        zone,
                                        center,
                                      )
                                    : null,
                                isSelected:
                                    selectedCardIds?.contains(
                                      displayCards[i].id,
                                    ) ??
                                    false,
                                isMultiSelectMode: isMultiSelectMode,
                                isMultiSelectEligible: _isEligible(
                                  displayCards[i],
                                ),
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

// ── Shared animated glow container ────────────────────────────────────────────

class _GlowingTileContainer extends StatefulWidget {
  final bool isCurrentTurn;
  final bool isOut;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;

  const _GlowingTileContainer({
    required this.isCurrentTurn,
    this.isOut = false,
    required this.child,
    required this.padding,
    required this.borderRadius,
    this.width,
  });

  @override
  State<_GlowingTileContainer> createState() => _GlowingTileContainerState();
}

class _GlowingTileContainerState extends State<_GlowingTileContainer>
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
    _glow = Tween<double>(
      begin: 8,
      end: 24,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOut) {
      return Container(
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: const Color(0x26374151),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: const Color(0x668B949E)),
        ),
        child: Opacity(
          opacity: 0.45,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: widget.child,
          ),
        ),
      );
    }

    if (!widget.isCurrentTurn) {
      return Container(
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Container(
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: const Color(0x1AFACC15),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: const Color(0xFFFACC15).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFACC15).withValues(alpha: 0.25),
              blurRadius: _glow.value,
              spreadRadius: _glow.value / 4,
            ),
            BoxShadow(
              color: const Color(0xFFFACC15).withValues(alpha: 0.1),
              blurRadius: _glow.value * 2,
              spreadRadius: _glow.value / 3,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
