import 'package:flutter/material.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';
import 'card_bounce_scope.dart';

class KarmaPalaceCardWidget extends StatelessWidget {
  final game_card.Card card;
  final bool isFaceDown;
  final bool isPlayable;
  final Size size;
  final VoidCallback? onTap;
  final Function(Offset)? onTapWithCenter;

  // Multi-card selection support
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool isMultiSelectEligible;

  const KarmaPalaceCardWidget({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.isPlayable = false,
    this.size = const Size(40, 60),
    this.onTap,
    this.onTapWithCenter,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.isMultiSelectEligible = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    // Determine border color based on state
    Color borderColor = palette.ink;
    double borderWidth = 1;

    if (isSelected) {
      borderColor = Colors.green;
      borderWidth = 3;
    } else if (isMultiSelectMode && isMultiSelectEligible) {
      borderColor = Colors.blue;
      borderWidth = 2;
    } else if (isPlayable) {
      borderColor = Colors.blue;
      borderWidth = 2;
    }

    final cardContent = Builder(
      builder: (cardContext) => GestureDetector(
        onTap: isPlayable && onTapWithCenter == null ? onTap : null,
        onTapUp: isPlayable && onTapWithCenter != null
            ? (_) {
                final box = cardContext.findRenderObject() as RenderBox?;
                if (box == null) return;
                onTapWithCenter!(
                    box.localToGlobal(box.size.center(Offset.zero)));
              }
            : null,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: isFaceDown ? palette.ink : palette.trueWhite,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              else if (isPlayable ||
                  (isMultiSelectMode && isMultiSelectEligible))
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Stack(
            children: [
              // Card content - centered
              Center(
                child: isFaceDown
                    ? _buildFaceDownCard(palette)
                    : _buildFaceUpCard(context, palette),
              ),

              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!isSelected) return cardContent;

    final bounceAnim = CardBounceScope.maybeOf(context);
    if (bounceAnim == null) return cardContent;

    return AnimatedBuilder(
      animation: bounceAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, bounceAnim.value),
        child: child,
      ),
      child: cardContent,
    );
  }

  Widget _buildFaceDownCard(Palette palette) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF7C3AED)
          ], // blue-600 → purple-600
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: size.width * 0.5,
          height: size.height * 0.5,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceUpCard(BuildContext context, Palette palette) {
    final textColor = _getCardColor(palette);

    // Large card layout (pile display): proper playing card corners + center
    if (size.width >= 50) {
      final cornerFontSize = size.width * 0.26;
      final centerFontSize = size.width * 0.50;
      return Stack(
        children: [
          // Top-left corner
          Positioned(
            top: size.width * 0.08,
            left: size.width * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: cornerFontSize,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  card.suit,
                  style: TextStyle(
                      color: textColor,
                      fontSize: cornerFontSize * 0.95,
                      height: 1.0),
                ),
              ],
            ),
          ),
          // Center suit symbol
          Center(
            child: Text(
              card.suit,
              style: TextStyle(color: textColor, fontSize: centerFontSize),
            ),
          ),
          // Bottom-right corner (rotated)
          Positioned(
            bottom: size.width * 0.08,
            right: size.width * 0.08,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.value,
                    style: TextStyle(
                      color: textColor,
                      fontSize: cornerFontSize,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    card.suit,
                    style: TextStyle(
                        color: textColor,
                        fontSize: cornerFontSize * 0.95,
                        height: 1.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Small card layout: centered rank + suit
    final fontSize = size.width * 0.46;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          card.value,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          card.suit,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize * 0.85,
          ),
          textAlign: TextAlign.center,
        ),
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
        return palette.blackInk;
      default:
        return palette.blackInk;
    }
  }
}
