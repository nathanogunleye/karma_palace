import 'dart:math';
import 'package:logging/logging.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';

/// AI difficulty levels
enum AIDifficulty { easy, medium, hard }

class AIPlayerService {
  static final Logger _log = Logger('AIPlayerService');
  static final Random _random = Random();

  /// Choose the best card to play for the AI
  static (game_card.Card, String)? chooseCardToPlay(Player aiPlayer, Room room, AIDifficulty difficulty) {
    _log.info('AI choosing card to play with difficulty: $difficulty');
    
    final effectiveTopCard = _getEffectiveTopCard(room.playPile);
    
    // Get all playable cards from all zones
    final playableCards = <(game_card.Card, String)>[];
    
    // Check hand cards first
    for (final card in aiPlayer.hand) {
      if (_canPlayCard(card, effectiveTopCard, aiPlayer)) {
        playableCards.add((card, 'hand'));
      }
    }
    
    // Check face-up cards if hand is empty
    if (aiPlayer.hand.isEmpty) {
      for (final card in aiPlayer.faceUp) {
        if (_canPlayCard(card, effectiveTopCard, aiPlayer)) {
          playableCards.add((card, 'faceUp'));
        }
      }
    }
    
    // Check face-down cards if hand and face-up are empty
    if (aiPlayer.hand.isEmpty && aiPlayer.faceUp.isEmpty) {
      for (final card in aiPlayer.faceDown) {
        if (_canPlayCard(card, effectiveTopCard, aiPlayer)) {
          playableCards.add((card, 'faceDown'));
        }
      }
    }
    
    if (playableCards.isEmpty) {
      _log.info('AI has no playable cards');
      return null;
    }
    
    // Choose card based on difficulty
    switch (difficulty) {
      case AIDifficulty.easy:
        return _chooseEasyCard(playableCards);
      case AIDifficulty.medium:
        return _chooseMediumCard(playableCards, effectiveTopCard);
      case AIDifficulty.hard:
        return _chooseHardCard(playableCards, effectiveTopCard, aiPlayer);
    }
  }
  
  /// Easy AI: Random choice
  static (game_card.Card, String) _chooseEasyCard(List<(game_card.Card, String)> playableCards) {
    final randomIndex = _random.nextInt(playableCards.length);
    final choice = playableCards[randomIndex];
    _log.info('Easy AI chose: ${choice.$1.displayString} from ${choice.$2}');
    return choice;
  }
  
  /// Medium AI: Prefer lower cards to save high cards
  static (game_card.Card, String) _chooseMediumCard(List<(game_card.Card, String)> playableCards, game_card.Card? topCard) {
    // Sort by card value (lower is better for medium AI)
    playableCards.sort((a, b) => a.$1.numericValue.compareTo(b.$1.numericValue));
    
    // Prefer playing from hand first, then face-up, then face-down
    playableCards.sort((a, b) {
      final zoneOrder = {'hand': 0, 'faceUp': 1, 'faceDown': 2};
      return zoneOrder[a.$2]!.compareTo(zoneOrder[b.$2]!);
    });
    
    final choice = playableCards.first;
    _log.info('Medium AI chose: ${choice.$1.displayString} from ${choice.$2}');
    return choice;
  }
  
  /// Hard AI: Strategic play with special card consideration
  static (game_card.Card, String) _chooseHardCard(List<(game_card.Card, String)> playableCards, game_card.Card? topCard, Player aiPlayer) {
    // Prefer playing from hand first, then face-up, then face-down
    playableCards.sort((a, b) {
      final zoneOrder = {'hand': 0, 'faceUp': 1, 'faceDown': 2};
      return zoneOrder[a.$2]!.compareTo(zoneOrder[b.$2]!);
    });
    
    // Look for special cards first (2, 7, 10, J, Q, K)
    final specialCards = playableCards.where((card) => 
      card.$1.hasSpecialEffect || ['J', 'Q', 'K'].contains(card.$1.value)
    ).toList();
    
    if (specialCards.isNotEmpty) {
      // Choose the best special card
      final choice = _chooseBestSpecialCard(specialCards, topCard);
      _log.info('Hard AI chose special card: ${choice.$1.displayString} from ${choice.$2}');
      return choice;
    }
    
    // For regular cards, prefer lower values to save high cards
    playableCards.sort((a, b) => a.$1.numericValue.compareTo(b.$1.numericValue));
    
    final choice = playableCards.first;
    _log.info('Hard AI chose: ${choice.$1.displayString} from ${choice.$2}');
    return choice;
  }
  
  /// Choose the best special card to play
  static (game_card.Card, String) _chooseBestSpecialCard(List<(game_card.Card, String)> specialCards, game_card.Card? topCard) {
    // Priority order: 2 (reset) > 7 (force low) > 10 (burn) > J/Q/K (high cards)
    final priorityOrder = {
      '2': 0,  // Reset - highest priority
      '7': 1,  // Force low
      '10': 2, // Burn
      'J': 3,  // High cards
      'Q': 3,
      'K': 3,
    };
    
    specialCards.sort((a, b) {
      final priorityA = priorityOrder[a.$1.value] ?? 4;
      final priorityB = priorityOrder[b.$1.value] ?? 4;
      return priorityA.compareTo(priorityB);
    });
    
    return specialCards.first;
  }
  
  /// Get the effective top card (handles glass effect)
  static game_card.Card? _getEffectiveTopCard(List<game_card.Card> playPile) {
    if (playPile.isEmpty) {
      return null;
    }
    
    // Start from the top and work backwards through 5s
    for (int i = playPile.length - 1; i >= 0; i--) {
      final card = playPile[i];
      
      // If we find a non-5 card, that's our effective top card
      if (card.value != '5') {
        return card;
      }
    }
    
    // If we get here, all cards are 5s, so return the bottom 5
    return playPile.first;
  }

  /// Check if a card can be played (same logic as game state)
  static bool _canPlayCard(game_card.Card card, game_card.Card? topCard, Player player) {
    if (topCard == null) {
      return true; // First card of the game
    }
    
    // Check if player is forced to play low (from card 7 effect)
    if (player.forcedToPlayLow) {
      return card.numericValue <= 7;
    }
    
    // Check if card can be played on high cards (J, Q, K)
    if (['J', 'Q', 'K'].contains(topCard.value)) {
      return card.canPlayOnHighCard(topCard);
    }
    
    // Check if top card is 7 - forces next player to play 7 or lower
    if (topCard.value == '7') {
      return card.numericValue <= 7;
    }
    
    // Check if playing a special card on a non-royal card
    if (card.hasSpecialEffect && !['J', 'Q', 'K'].contains(topCard.value)) {
      return true; // Special cards can be played on any non-royal card
    }
    
    // Normal card comparison
    return card.numericValue >= topCard.numericValue;
  }
  
  /// Generate AI player name
  static String generateAIName() {
    final names = [
      'KarmaBot',
      'CardMaster',
      'PalaceGuard',
      'DeckWizard',
      'RoyalAI',
      'GameMaster',
      'CardShark',
      'PalaceKeeper',
    ];
    return names[_random.nextInt(names.length)];
  }
}
