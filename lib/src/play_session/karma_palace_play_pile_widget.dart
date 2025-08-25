import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';
import 'karma_palace_card_widget.dart';

class KarmaPalacePlayPileWidget extends StatelessWidget {
  final List<game_card.Card> playPile;
  final game_card.Card? topCard;
  final bool showBurnNotification;

  const KarmaPalacePlayPileWidget({
    super.key,
    required this.playPile,
    required this.topCard,
    this.showBurnNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Container(
      decoration: BoxDecoration(
        color: palette.backgroundPlaySession.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.ink.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play pile label
            Text(
              'PLAY PILE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: palette.ink,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Top card and info
            if (topCard != null) ...[
              // Glass effect indicator
              if (topCard!.value == '5' && playPile.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.cyan.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GLASS: See ${playPile[playPile.length - 2].displayString}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Top card (main card) - larger size
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: KarmaPalaceCardWidget(
                  card: topCard!,
                  size: const Size(80, 120),
                ),
              ),
              
              const SizedBox(height: 12),

              // Recent cards in a clean row layout
              if (playPile.length > 1) ...[
                Text(
                  'Recent Cards:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.ink.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: playPile.length - 1,
                    itemBuilder: (context, index) {
                      final card = playPile[playPile.length - 2 - index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 55,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.9),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            card.displayString,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else
              // Empty pile with optional burn notification
              Column(
                children: [
                  // Burn notification if applicable
                  if (showBurnNotification) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepOrange.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.deepOrange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PILE BURNED!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Empty pile indicator
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Empty',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Pile count and info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pile count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${playPile.length} cards',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                    ),
                  ),
                ),

                // Special effect indicator for top card
                if (topCard?.hasSpecialEffect == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSpecialEffectColor(topCard!.specialEffect!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _getSpecialEffectColor(topCard!.specialEffect!).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSpecialEffectIcon(topCard!.specialEffect!),
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSpecialEffectDescription(topCard!.specialEffect!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSpecialEffectColor(game_card.SpecialEffect effect) {
    switch (effect) {
      case game_card.SpecialEffect.reset:
        return Colors.orange;
      case game_card.SpecialEffect.glass:
        return Colors.cyan;
      case game_card.SpecialEffect.forceLow:
        return Colors.purple;
      case game_card.SpecialEffect.skip:
        return Colors.red;
      case game_card.SpecialEffect.burn:
        return Colors.deepOrange;
    }
  }

  IconData _getSpecialEffectIcon(game_card.SpecialEffect effect) {
    switch (effect) {
      case game_card.SpecialEffect.reset:
        return Icons.refresh;
      case game_card.SpecialEffect.glass:
        return Icons.visibility;
      case game_card.SpecialEffect.forceLow:
        return Icons.keyboard_arrow_down;
      case game_card.SpecialEffect.skip:
        return Icons.skip_next;
      case game_card.SpecialEffect.burn:
        return Icons.local_fire_department;
    }
  }

  String _getSpecialEffectDescription(game_card.SpecialEffect effect) {
    switch (effect) {
      case game_card.SpecialEffect.reset:
        return 'RESET';
      case game_card.SpecialEffect.glass:
        return 'GLASS';
      case game_card.SpecialEffect.forceLow:
        return 'FORCE LOW';
      case game_card.SpecialEffect.skip:
        return 'SKIP';
      case game_card.SpecialEffect.burn:
        return 'BURN';
    }
  }
}
