import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';

class KarmaPalaceCardWidget extends StatelessWidget {
  final game_card.Card card;
  final bool isFaceDown;
  final bool isPlayable;
  final Size size;
  final VoidCallback? onTap;

  const KarmaPalaceCardWidget({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.isPlayable = false,
    this.size = const Size(40, 60),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: isFaceDown ? palette.ink : palette.trueWhite,
          border: Border.all(
            color: isPlayable ? Colors.blue : palette.ink,
            width: isPlayable ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isPlayable ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: isFaceDown
            ? _buildFaceDownCard(palette)
            : _buildFaceUpCard(context, palette),
      ),
    );
  }

  Widget _buildFaceDownCard(Palette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.ink,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: palette.trueWhite,
          size: size.width * 0.4,
        ),
      ),
    );
  }

  Widget _buildFaceUpCard(BuildContext context, Palette palette) {
    final textColor = _getCardColor(palette);
    final fontSize = size.width * 0.4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Card value
        Text(
          card.value,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Card suit
        Text(
          card.suit,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize * 0.8,
          ),
        ),
        
        // Special effect indicator
        // if (card.hasSpecialEffect)
        //   Container(
        //     margin: const EdgeInsets.only(top: 2),
        //     padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        //     decoration: BoxDecoration(
        //       color: _getSpecialEffectColor(),
        //       borderRadius: BorderRadius.circular(2),
        //     ),
        //     child: Text(
        //       _getSpecialEffectSymbol(),
        //       style: TextStyle(
        //         color: Colors.white,
        //         fontSize: fontSize * 0.3,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Color _getCardColor(Palette palette) {
    // Determine card color based on suit
    switch (card.suit) {
      case '♥':
      case '♦':
        return Colors.red;
      case '♣':
      case '♠':
        return palette.ink;
      default:
        return palette.ink;
    }
  }

  Color _getSpecialEffectColor() {
    switch (card.specialEffect) {
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
      default:
        return Colors.grey;
    }
  }

  String _getSpecialEffectSymbol() {
    switch (card.specialEffect) {
      case game_card.SpecialEffect.reset:
        return '↻';
      case game_card.SpecialEffect.glass:
        return '👁';
      case game_card.SpecialEffect.forceLow:
        return '↓';
      case game_card.SpecialEffect.skip:
        return '⏭';
      case game_card.SpecialEffect.burn:
        return '🔥';
      default:
        return '';
    }
  }
} 