import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';
import 'karma_palace_card_widget.dart';

class KarmaPalacePlayPileWidget extends StatelessWidget {
  final List<game_card.Card> playPile;
  final game_card.Card? topCard;

  const KarmaPalacePlayPileWidget({
    super.key,
    required this.playPile,
    required this.topCard,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: palette.backgroundPlaySession.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.ink.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play pile label
          Text(
            'Play Pile',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.ink,
            ),
          ),

          const SizedBox(height: 8),

          // Top card
          if (topCard != null)
            KarmaPalaceCardWidget(
              card: topCard!,
              size: const Size(60, 90),
            )
          else
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              child: const Center(
                child: Text(
                  'Empty',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Pile count
          Text(
            '${playPile.length} cards',
            style: TextStyle(
              fontSize: 12,
              color: palette.ink.withOpacity(0.7),
            ),
          ),

          // Special effect indicator for top card
          if (topCard?.hasSpecialEffect == true)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSpecialEffectColor(topCard!.specialEffect!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getSpecialEffectDescription(topCard!.specialEffect!),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
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
