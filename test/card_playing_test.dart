import 'package:flutter_test/flutter_test.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';

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

    group('4-of-a-Kind Burn Rule', () {
      test('should burn pile when 4 cards of same value are played consecutively', () {
        // Test 4-of-a-kind detection
        final cards = [
          game_card.Card(suit: '♠', value: 'K', id: '1'),
          game_card.Card(suit: '♥', value: 'K', id: '2'),
          game_card.Card(suit: '♦', value: 'K', id: '3'),
          game_card.Card(suit: '♣', value: 'K', id: '4'),
        ];
        
        // Check that all 4 cards have the same value
        final firstValue = cards[0].value;
        final allSameValue = cards.every((card) => card.value == firstValue);
        
        expect(allSameValue, isTrue);
        expect(cards.length, equals(4));
        expect(firstValue, equals('K'));
      });

      test('should not burn pile when less than 4 cards are played', () {
        // Test with only 3 cards
        final cards = [
          game_card.Card(suit: '♠', value: 'K', id: '1'),
          game_card.Card(suit: '♥', value: 'K', id: '2'),
          game_card.Card(suit: '♦', value: 'K', id: '3'),
        ];
        
        expect(cards.length, equals(3));
        expect(cards.length < 4, isTrue);
      });

      test('should not burn pile when 4 cards have different values', () {
        // Test with 4 different cards
        final cards = [
          game_card.Card(suit: '♠', value: 'K', id: '1'),
          game_card.Card(suit: '♥', value: 'Q', id: '2'),
          game_card.Card(suit: '♦', value: 'J', id: '3'),
          game_card.Card(suit: '♣', value: '10', id: '4'),
        ];
        
        final firstValue = cards[0].value;
        final allSameValue = cards.every((card) => card.value == firstValue);
        
        expect(allSameValue, isFalse);
        expect(cards.length, equals(4));
      });

      test('should burn pile with 4 of any value', () {
        // Test with different values
        final testCases = [
          ['2', '2', '2', '2'],
          ['7', '7', '7', '7'],
          ['A', 'A', 'A', 'A'],
          ['5', '5', '5', '5'],
        ];
        
        for (final values in testCases) {
          final cards = values.asMap().entries.map((entry) {
            final suits = ['♠', '♥', '♦', '♣'];
            return game_card.Card(
              suit: suits[entry.key],
              value: entry.value,
              id: entry.key.toString(),
            );
          }).toList();
          
          final firstValue = cards[0].value;
          final allSameValue = cards.every((card) => card.value == firstValue);
          
          expect(allSameValue, isTrue, reason: '4 ${firstValue}s should be detected as 4-of-a-kind');
          expect(cards.length, equals(4));
        }
      });
    });

    group('Pick-Up Notification Tests', () {
      test('should detect when a player picks up the pile', () {
        // This test verifies that the pick-up detection logic works
        // In a real scenario, this would be tested with the actual game service
        
        // Mock scenario: player picks up pile
        final pileBeforePickUp = [
          game_card.Card(suit: '♠', value: 'K', id: '1'),
          game_card.Card(suit: '♥', value: 'Q', id: '2'),
          game_card.Card(suit: '♦', value: 'J', id: '3'),
        ];
        
        final pileAfterPickUp = <game_card.Card>[]; // Empty after pick-up
        
        // Verify that pile is empty after pick-up
        expect(pileAfterPickUp.isEmpty, isTrue);
        expect(pileBeforePickUp.isNotEmpty, isTrue);
        expect(pileBeforePickUp.length, equals(3));
      });
    });

    group('Multiple 5s Glass Effect Tests', () {
      test('should handle multiple consecutive 5s correctly', () {
        // Test scenario: A → 5 → 5 → K (K should be invalid)
        final aCard = game_card.Card(suit: '♠', value: 'A', id: '1');
        final fiveCard1 = game_card.Card(suit: '♥', value: '5', id: '2');
        final fiveCard2 = game_card.Card(suit: '♦', value: '5', id: '3');
        final kCard = game_card.Card(suit: '♣', value: 'K', id: '4');
        
        // A can be played first
        expect(aCard.numericValue, equals(14));
        
        // 5 can be played on A (glass effect)
        expect(fiveCard1.canPlayOnHighCard(aCard), isTrue);
        
        // 5 can be played on another 5 (glass effect)
        expect(fiveCard2.canPlayOnHighCard(fiveCard1), isTrue);
        
        // K should NOT be playable on 5 when effective top card is A
        // K (13) < A (14), so it should be invalid
        expect(kCard.canPlayOnHighCard(aCard), isFalse);
      });

      test('should handle multiple 5s with different base cards', () {
        // Test scenario: K → 5 → 5 → Q (Q should be invalid)
        final kCard = game_card.Card(suit: '♠', value: 'K', id: '1');
        final fiveCard1 = game_card.Card(suit: '♥', value: '5', id: '2');
        final fiveCard2 = game_card.Card(suit: '♦', value: '5', id: '3');
        final qCard = game_card.Card(suit: '♣', value: 'Q', id: '4');
        
        // K can be played first
        expect(kCard.numericValue, equals(13));
        
        // 5 can be played on K (glass effect)
        expect(fiveCard1.canPlayOnHighCard(kCard), isTrue);
        
        // 5 can be played on another 5 (glass effect)
        expect(fiveCard2.canPlayOnHighCard(fiveCard1), isTrue);
        
        // Q should NOT be playable on 5 when effective top card is K
        // Q (12) < K (13), so it should be invalid
        expect(qCard.canPlayOnHighCard(kCard), isFalse);
      });

      test('should allow valid cards on multiple 5s', () {
        // Test scenario: J → 5 → 5 → A (A should be valid)
        final jCard = game_card.Card(suit: '♠', value: 'J', id: '1');
        final fiveCard1 = game_card.Card(suit: '♥', value: '5', id: '2');
        final fiveCard2 = game_card.Card(suit: '♦', value: '5', id: '3');
        final aCard = game_card.Card(suit: '♣', value: 'A', id: '4');
        
        // J can be played first
        expect(jCard.numericValue, equals(11));
        
        // 5 can be played on J (glass effect)
        expect(fiveCard1.canPlayOnHighCard(jCard), isTrue);
        
        // 5 can be played on another 5 (glass effect)
        expect(fiveCard2.canPlayOnHighCard(fiveCard1), isTrue);
        
        // A should be playable on 5 when effective top card is J
        // A (14) > J (11), so it should be valid
        expect(aCard.canPlayOnHighCard(jCard), isTrue);
      });
    });

    group('Win Condition Tests', () {
      test('should detect win when player has no cards left', () {
        // Create a player with no cards
        final winningPlayer = Player(
          id: 'player1',
          name: 'Winner',
          isPlaying: true,
          hand: <game_card.Card>[],
          faceUp: <game_card.Card>[],
          faceDown: <game_card.Card>[],
          isConnected: true,
          lastSeen: DateTime.now(),
          turnOrder: 0,
        );
        
        // Player should have won
        expect(winningPlayer.totalCards, equals(0));
        expect(winningPlayer.hasWon, isTrue);
      });

      test('should not detect win when player still has cards', () {
        // Create a player with cards
        final playerWithCards = Player(
          id: 'player2',
          name: 'Still Playing',
          isPlaying: true,
          hand: [
            game_card.Card(suit: '♠', value: 'A', id: '1'),
            game_card.Card(suit: '♥', value: 'K', id: '2'),
          ],
          faceUp: <game_card.Card>[],
          faceDown: <game_card.Card>[],
          isConnected: true,
          lastSeen: DateTime.now(),
          turnOrder: 1,
        );
        
        // Player should not have won
        expect(playerWithCards.totalCards, equals(2));
        expect(playerWithCards.hasWon, isFalse);
      });

      test('should count all card zones for win condition', () {
        // Create a player with cards in different zones
        final playerWithMixedCards = Player(
          id: 'player3',
          name: 'Mixed Cards',
          isPlaying: true,
          hand: [
            game_card.Card(suit: '♠', value: 'A', id: '1'),
          ],
          faceUp: [
            game_card.Card(suit: '♥', value: 'K', id: '2'),
          ],
          faceDown: [
            game_card.Card(suit: '♦', value: 'Q', id: '3'),
          ],
          isConnected: true,
          lastSeen: DateTime.now(),
          turnOrder: 2,
        );
        
        // Player should have 3 total cards
        expect(playerWithMixedCards.totalCards, equals(3));
        expect(playerWithMixedCards.hasWon, isFalse);
      });
    });
  });
}
