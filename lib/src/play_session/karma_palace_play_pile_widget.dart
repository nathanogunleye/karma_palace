import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF), // glass white/10
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PLAY PILE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            if (topCard != null) ...[
              // Glass effect indicator (5 card)
              if (topCard!.value == '5' && playPile.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, size: 14, color: Colors.cyan),
                      const SizedBox(width: 4),
                      Text(
                        'GLASS: See ${playPile[playPile.length - 2].displayString}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Top card
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

              const SizedBox(height: 8),

              // Pile count + special effect badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${playPile.length} cards',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ),
                  if (topCard?.hasSpecialEffect == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _effectColor(topCard!.specialEffect!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _effectLabel(topCard!.specialEffect!),
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              // Empty pile
              if (showBurnNotification) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: Colors.deepOrange),
                      SizedBox(width: 4),
                      Text('PILE BURNED!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 28, color: Colors.white38),
                    SizedBox(height: 4),
                    Text('Empty', style: TextStyle(fontSize: 13, color: Colors.white38, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _effectColor(game_card.SpecialEffect e) => switch (e) {
        game_card.SpecialEffect.reset => Colors.orange,
        game_card.SpecialEffect.glass => Colors.cyan,
        game_card.SpecialEffect.forceLow => Colors.purple,
        game_card.SpecialEffect.skip => Colors.red,
        game_card.SpecialEffect.burn => Colors.deepOrange,
      };

  String _effectLabel(game_card.SpecialEffect e) => switch (e) {
        game_card.SpecialEffect.reset => 'RESET',
        game_card.SpecialEffect.glass => 'GLASS',
        game_card.SpecialEffect.forceLow => 'FORCE LOW',
        game_card.SpecialEffect.skip => 'SKIP',
        game_card.SpecialEffect.burn => 'BURN',
      };
}
