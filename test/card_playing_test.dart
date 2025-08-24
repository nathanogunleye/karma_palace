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
      // Test special effect detection
      expect(game_card.Card(suit: '♠', value: '2', id: '1').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '5', id: '2').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '7', id: '3').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '9', id: '4').hasSpecialEffect, isTrue);
      expect(game_card.Card(suit: '♠', value: '10', id: '5').hasSpecialEffect, isTrue);
      
      // Test non-special cards
      expect(game_card.Card(suit: '♠', value: '3', id: '6').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: '8', id: '7').hasSpecialEffect, isFalse);
      expect(game_card.Card(suit: '♠', value: 'J', id: '8').hasSpecialEffect, isFalse);
    });
  });
}
