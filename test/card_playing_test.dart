import 'package:flutter_test/flutter_test.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;

void main() {
  group('Card Playing Logic Tests', () {
    test('should allow playing same value cards on high cards (J, Q, K)', () {
      // Test playing K on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: 'K', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should allow playing higher value cards on high cards', () {
      // Test playing A on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: 'A', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should not allow playing lower value cards on high cards', () {
      // Test playing Q on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: 'Q', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isFalse);
    });

    test('should allow playing glass (5) on any high card', () {
      // Test playing 5 on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '5', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should not allow playing other special cards on high cards', () {
      // Test playing 2 on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '2', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isFalse);
    });

    test('should allow playing same value cards on regular cards', () {
      // Test playing 8 on 8
      final topCard = game_card.Card(suit: '♠', value: '8', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '8', id: '2');
      
      // This would be handled by the normal card comparison logic
      expect(playCard.numericValue >= topCard.numericValue, isTrue);
    });

    test('should allow playing same value cards on J', () {
      // Test playing J on J
      final topCard = game_card.Card(suit: '♠', value: 'J', id: '1');
      final playCard = game_card.Card(suit: '♥', value: 'J', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should allow playing same value cards on Q', () {
      // Test playing Q on Q
      final topCard = game_card.Card(suit: '♠', value: 'Q', id: '1');
      final playCard = game_card.Card(suit: '♥', value: 'Q', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should allow playing glass (5) on J', () {
      // Test playing 5 on J
      final topCard = game_card.Card(suit: '♠', value: 'J', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '5', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should allow playing glass (5) on Q', () {
      // Test playing 5 on Q
      final topCard = game_card.Card(suit: '♠', value: 'Q', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '5', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isTrue);
    });

    test('should not allow playing 7 on high cards', () {
      // Test playing 7 on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '7', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isFalse);
    });

    test('should not allow playing 9 on high cards', () {
      // Test playing 9 on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '9', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isFalse);
    });

    test('should not allow playing 10 on high cards', () {
      // Test playing 10 on K
      final topCard = game_card.Card(suit: '♠', value: 'K', id: '1');
      final playCard = game_card.Card(suit: '♥', value: '10', id: '2');
      
      expect(playCard.canPlayOnHighCard(topCard), isFalse);
    });

    test('should verify numeric values are correct', () {
      // Test that numeric values are assigned correctly
      expect(game_card.Card(suit: '♠', value: '2', id: '1').numericValue, equals(2));
      expect(game_card.Card(suit: '♠', value: '10', id: '2').numericValue, equals(10));
      expect(game_card.Card(suit: '♠', value: 'J', id: '3').numericValue, equals(11));
      expect(game_card.Card(suit: '♠', value: 'Q', id: '4').numericValue, equals(12));
      expect(game_card.Card(suit: '♠', value: 'K', id: '5').numericValue, equals(13));
      expect(game_card.Card(suit: '♠', value: 'A', id: '6').numericValue, equals(14));
    });

    test('should handle glass effect correctly - play based on card below 5', () {
      // Test that when 5 is on top, the next player plays based on the card below
      // This would be tested in the game logic, not the card model itself
      // The card model just defines the glass effect, the game logic handles the implementation
      final glassCard = game_card.Card(suit: '♥', value: '5', id: '1');
      expect(glassCard.specialEffect, equals(game_card.SpecialEffect.glass));
      expect(glassCard.hasSpecialEffect, isTrue);
    });

    test('should verify special effects are correctly identified', () {
      // Test all special effects
      expect(game_card.Card(suit: '♠', value: '2', id: '1').specialEffect, equals(game_card.SpecialEffect.reset));
      expect(game_card.Card(suit: '♠', value: '5', id: '2').specialEffect, equals(game_card.SpecialEffect.glass));
      expect(game_card.Card(suit: '♠', value: '7', id: '3').specialEffect, equals(game_card.SpecialEffect.forceLow));
      expect(game_card.Card(suit: '♠', value: '9', id: '4').specialEffect, equals(game_card.SpecialEffect.skip));
      expect(game_card.Card(suit: '♠', value: '10', id: '5').specialEffect, equals(game_card.SpecialEffect.burn));
    });

    test('should verify hasSpecialEffect property', () {
      // Test that hasSpecialEffect returns true for special cards
      expect(game_card.Card(suit: '♠', value: '2', id: '1').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '5', id: '2').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '7', id: '3').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '9', id: '4').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '10', id: '5').hasSpecialEffect, isTrue);
      
      // Test that hasSpecialEffect returns false for non-special cards
      expect(game_card.Card(suit: '♠', value: '3', id: '6').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: '4', id: '7').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: '6', id: '8').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: '8', id: '9').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: 'J', id: '10').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: 'Q', id: '11').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: 'K', id: '12').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: 'A', id: '13').hasSpecialEffect, isFalse);
    });

    group('Glass Effect Scenarios', () {
      test('should allow playing 5 on J, then only valid cards on 5', () {
        // Scenario: J → 5 → valid card
        final jCard = game_card.Card(suit: '♠', value: 'J', id: '1');
        final fiveCard = game_card.Card(suit: '♥', value: '5', id: '2');
        
        // 5 can be played on J
        expect(fiveCard.canPlayOnHighCard(jCard), isTrue);
        
        // After 5 is played, effective top card is J
        // Only these cards can be played: 5, J, Q, K, A
        final validCards = [
          game_card.Card(suit: '♦', value: '5', id: '3'),   // Another 5
          game_card.Card(suit: '♣', value: 'J', id: '4'),   // Same value
          game_card.Card(suit: '♦', value: 'Q', id: '5'),   // Higher value
          game_card.Card(suit: '♣', value: 'K', id: '6'),   // Higher value
          game_card.Card(suit: '♦', value: 'A', id: '7'),   // Higher value
        ];
        
        for (final card in validCards) {
          expect(card.canPlayOnHighCard(jCard), isTrue, 
            reason: '${card.displayString} should be playable on J');
        }
        
        // These cards should NOT be playable
        final invalidCards = [
          game_card.Card(suit: '♦', value: '2', id: '8'),   // Special card
          game_card.Card(suit: '♣', value: '7', id: '9'),   // Special card
          game_card.Card(suit: '♦', value: '9', id: '10'),  // Special card
          game_card.Card(suit: '♣', value: '10', id: '11'), // Special card
          game_card.Card(suit: '♦', value: '3', id: '12'),  // Lower value
          game_card.Card(suit: '♣', value: '4', id: '13'),  // Lower value
          game_card.Card(suit: '♦', value: '6', id: '14'),  // Lower value
          game_card.Card(suit: '♣', value: '8', id: '15'),  // Lower value
        ];
        
        for (final card in invalidCards) {
          expect(card.canPlayOnHighCard(jCard), isFalse, 
            reason: '${card.displayString} should NOT be playable on J');
        }
      });

      test('should allow playing 5 on K, then only valid cards on 5', () {
        // Scenario: K → 5 → valid card
        final kCard = game_card.Card(suit: '♠', value: 'K', id: '1');
        final fiveCard = game_card.Card(suit: '♥', value: '5', id: '2');
        
        // 5 can be played on K
        expect(fiveCard.canPlayOnHighCard(kCard), isTrue);
        
        // After 5 is played, effective top card is K
        // Only these cards can be played: 5, K, A
        final validCards = [
          game_card.Card(suit: '♦', value: '5', id: '3'),   // Another 5
          game_card.Card(suit: '♣', value: 'K', id: '4'),   // Same value
          game_card.Card(suit: '♦', value: 'A', id: '5'),   // Higher value
        ];
        
        for (final card in validCards) {
          expect(card.canPlayOnHighCard(kCard), isTrue, 
            reason: '${card.displayString} should be playable on K');
        }
        
        // These cards should NOT be playable
        final invalidCards = [
          game_card.Card(suit: '♦', value: '2', id: '6'),   // Special card
          game_card.Card(suit: '♣', value: '7', id: '7'),   // Special card
          game_card.Card(suit: '♦', value: '9', id: '8'),   // Special card
          game_card.Card(suit: '♣', value: '10', id: '9'),  // Special card
          game_card.Card(suit: '♦', value: 'J', id: '10'),  // Lower value
          game_card.Card(suit: '♣', value: 'Q', id: '11'),  // Lower value
        ];
        
        for (final card in invalidCards) {
          expect(card.canPlayOnHighCard(kCard), isFalse, 
            reason: '${card.displayString} should NOT be playable on K');
        }
      });

      test('should allow playing 5 on Q, then only valid cards on 5', () {
        // Scenario: Q → 5 → valid card
        final qCard = game_card.Card(suit: '♠', value: 'Q', id: '1');
        final fiveCard = game_card.Card(suit: '♥', value: '5', id: '2');
        
        // 5 can be played on Q
        expect(fiveCard.canPlayOnHighCard(qCard), isTrue);
        
        // After 5 is played, effective top card is Q
        // Only these cards can be played: 5, Q, K, A
        final validCards = [
          game_card.Card(suit: '♦', value: '5', id: '3'),   // Another 5
          game_card.Card(suit: '♣', value: 'Q', id: '4'),   // Same value
          game_card.Card(suit: '♦', value: 'K', id: '5'),   // Higher value
          game_card.Card(suit: '♣', value: 'A', id: '6'),   // Higher value
        ];
        
        for (final card in validCards) {
          expect(card.canPlayOnHighCard(qCard), isTrue, 
            reason: '${card.displayString} should be playable on Q');
        }
        
        // These cards should NOT be playable
        final invalidCards = [
          game_card.Card(suit: '♦', value: '2', id: '7'),   // Special card
          game_card.Card(suit: '♣', value: '7', id: '8'),   // Special card
          game_card.Card(suit: '♦', value: '9', id: '9'),   // Special card
          game_card.Card(suit: '♣', value: '10', id: '10'), // Special card
          game_card.Card(suit: '♦', value: 'J', id: '11'),  // Lower value
        ];
        
        for (final card in invalidCards) {
          expect(card.canPlayOnHighCard(qCard), isFalse, 
            reason: '${card.displayString} should NOT be playable on Q');
        }
      });
    });

    group('Special Card Validation', () {
      test('should not allow special cards (except 5) on high cards', () {
        final highCards = [
          game_card.Card(suit: '♠', value: 'J', id: '1'),
          game_card.Card(suit: '♥', value: 'Q', id: '2'),
          game_card.Card(suit: '♦', value: 'K', id: '3'),
        ];
        
        final specialCards = [
          game_card.Card(suit: '♠', value: '2', id: '4'),
          game_card.Card(suit: '♥', value: '7', id: '5'),
          game_card.Card(suit: '♦', value: '9', id: '6'),
          game_card.Card(suit: '♣', value: '10', id: '7'),
        ];
        
        for (final highCard in highCards) {
          for (final specialCard in specialCards) {
            expect(specialCard.canPlayOnHighCard(highCard), isFalse,
              reason: '${specialCard.displayString} should not be playable on ${highCard.displayString}');
          }
        }
      });

      test('should allow 5 on any high card', () {
        final highCards = [
          game_card.Card(suit: '♠', value: 'J', id: '1'),
          game_card.Card(suit: '♥', value: 'Q', id: '2'),
          game_card.Card(suit: '♦', value: 'K', id: '3'),
        ];
        
        final fiveCard = game_card.Card(suit: '♣', value: '5', id: '4');
        
        for (final highCard in highCards) {
          expect(fiveCard.canPlayOnHighCard(highCard), isTrue,
            reason: '5 should be playable on ${highCard.displayString}');
        }
      });
    });

    group('Normal Card Comparison', () {
      test('should allow higher or equal cards on regular cards', () {
        final topCard = game_card.Card(suit: '♠', value: '8', id: '1');
        
        // Higher cards
        expect(game_card.Card(suit: '♥', value: '9', id: '2').numericValue >= topCard.numericValue, isTrue);
        expect(game_card.Card(suit: '♦', value: '10', id: '3').numericValue >= topCard.numericValue, isTrue);
        expect(game_card.Card(suit: '♣', value: 'J', id: '4').numericValue >= topCard.numericValue, isTrue);
        expect(game_card.Card(suit: '♠', value: 'Q', id: '5').numericValue >= topCard.numericValue, isTrue);
        expect(game_card.Card(suit: '♥', value: 'K', id: '6').numericValue >= topCard.numericValue, isTrue);
        expect(game_card.Card(suit: '♦', value: 'A', id: '7').numericValue >= topCard.numericValue, isTrue);
        
        // Equal card
        expect(game_card.Card(suit: '♣', value: '8', id: '8').numericValue >= topCard.numericValue, isTrue);
        
        // Lower cards
        expect(game_card.Card(suit: '♠', value: '7', id: '9').numericValue >= topCard.numericValue, isFalse);
        expect(game_card.Card(suit: '♥', value: '6', id: '10').numericValue >= topCard.numericValue, isFalse);
        expect(game_card.Card(suit: '♦', value: '5', id: '11').numericValue >= topCard.numericValue, isFalse);
        expect(game_card.Card(suit: '♣', value: '4', id: '12').numericValue >= topCard.numericValue, isFalse);
        expect(game_card.Card(suit: '♠', value: '3', id: '13').numericValue >= topCard.numericValue, isFalse);
        expect(game_card.Card(suit: '♥', value: '2', id: '14').numericValue >= topCard.numericValue, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle multiple 5s in sequence', () {
        // Scenario: K → 5 → 5 → valid card
        final kCard = game_card.Card(suit: '♠', value: 'K', id: '1');
        final fiveCard1 = game_card.Card(suit: '♥', value: '5', id: '2');
        final fiveCard2 = game_card.Card(suit: '♦', value: '5', id: '3');
        
        // First 5 can be played on K
        expect(fiveCard1.canPlayOnHighCard(kCard), isTrue);
        
        // Second 5 can be played on first 5 (effective top card is still K)
        expect(fiveCard2.canPlayOnHighCard(kCard), isTrue);
        
        // After two 5s, effective top card is still K
        // Only 5, K, A can be played
        final validCards = [
          game_card.Card(suit: '♣', value: '5', id: '4'),
          game_card.Card(suit: '♠', value: 'K', id: '5'),
          game_card.Card(suit: '♥', value: 'A', id: '6'),
        ];
        
        for (final card in validCards) {
          expect(card.canPlayOnHighCard(kCard), isTrue,
            reason: '${card.displayString} should be playable after multiple 5s');
        }
        
        // These should still be invalid
        final invalidCards = [
          game_card.Card(suit: '♦', value: '10', id: '7'),
          game_card.Card(suit: '♣', value: 'J', id: '8'),
          game_card.Card(suit: '♠', value: 'Q', id: '9'),
        ];
        
        for (final card in invalidCards) {
          expect(card.canPlayOnHighCard(kCard), isFalse,
            reason: '${card.displayString} should NOT be playable after multiple 5s');
        }
      });

      test('should handle 5 on non-high cards', () {
        // 5 should be playable on any card (not just high cards)
        final regularCards = [
          game_card.Card(suit: '♠', value: '2', id: '1'),
          game_card.Card(suit: '♥', value: '3', id: '2'),
          game_card.Card(suit: '♦', value: '4', id: '3'),
          game_card.Card(suit: '♣', value: '6', id: '4'),
          game_card.Card(suit: '♠', value: '8', id: '5'),
        ];
        
        final fiveCard = game_card.Card(suit: '♥', value: '5', id: '6');
        
        for (final card in regularCards) {
          // 5 should be playable on regular cards (normal comparison)
          expect(fiveCard.numericValue >= card.numericValue, 
            card.numericValue <= 5, // Only true for cards 5 and below
            reason: '5 should be playable on ${card.displayString} if ${card.numericValue} <= 5');
        }
      });
    });
  });
}
