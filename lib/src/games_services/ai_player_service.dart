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
  static (game_card.Card, String)? chooseCardToPlay(
    Player aiPlayer,
    Room room,
    AIDifficulty difficulty,
  ) {
    final choice = chooseCardsToPlay(aiPlayer, room, difficulty);
    if (choice == null) return null;
    return (choice.$1.first, choice.$2);
  }

  /// Choose the best card group to play for the AI.
  ///
  /// Human players can play matching ranks together, so medium and hard AI use
  /// the same tool when it helps them shed cards faster.
  static (List<game_card.Card>, String)? chooseCardsToPlay(
    Player aiPlayer,
    Room room,
    AIDifficulty difficulty,
  ) {
    _log.info('AI choosing card to play with difficulty: $difficulty');

    final effectiveTopCard = _getEffectiveTopCard(room.playPile);

    // Get all playable cards from all zones
    final playableCards = <(game_card.Card, String)>[];

    // Check hand cards first
    for (final card in aiPlayer.hand) {
      if (_canPlayCard(card, effectiveTopCard, aiPlayer, room.resetActive)) {
        playableCards.add((card, 'hand'));
      }
    }

    // Check face-up cards if hand is empty
    if (aiPlayer.hand.isEmpty) {
      for (final card in aiPlayer.faceUp) {
        if (_canPlayCard(card, effectiveTopCard, aiPlayer, room.resetActive)) {
          playableCards.add((card, 'faceUp'));
        }
      }
    }

    // Check face-down cards if hand and face-up are empty
    if (aiPlayer.hand.isEmpty && aiPlayer.faceUp.isEmpty) {
      for (final card in aiPlayer.faceDown) {
        if (_canPlayCard(card, effectiveTopCard, aiPlayer, room.resetActive)) {
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
        return _asSingleCardPlay(_chooseEasyCard(playableCards));
      case AIDifficulty.medium:
        return _withMatchingCards(
          _chooseMediumCard(playableCards, effectiveTopCard),
          aiPlayer,
        );
      case AIDifficulty.hard:
        return _withMatchingCards(
          _chooseHardCard(playableCards, effectiveTopCard, aiPlayer, room),
          aiPlayer,
        );
    }
  }

  static (List<game_card.Card>, String) _asSingleCardPlay(
    (game_card.Card, String) choice,
  ) {
    return ([choice.$1], choice.$2);
  }

  static (List<game_card.Card>, String) _withMatchingCards(
    (game_card.Card, String) choice,
    Player aiPlayer,
  ) {
    final card = choice.$1;
    final sourceZone = choice.$2;
    if (sourceZone == 'faceDown') {
      return ([card], sourceZone);
    }

    final sourceCards = switch (sourceZone) {
      'hand' => aiPlayer.hand,
      'faceUp' => aiPlayer.faceUp,
      _ => const <game_card.Card>[],
    };
    final matchingCards = sourceCards
        .where((c) => c.value == card.value)
        .toList();

    return (matchingCards.isEmpty ? [card] : matchingCards, sourceZone);
  }

  /// Easy AI: Random choice
  static (game_card.Card, String) _chooseEasyCard(
    List<(game_card.Card, String)> playableCards,
  ) {
    final randomIndex = _random.nextInt(playableCards.length);
    final choice = playableCards[randomIndex];
    _log.info('Easy AI chose: ${choice.$1.displayString} from ${choice.$2}');
    return choice;
  }

  /// Medium AI: Prefer lower cards to save high cards
  static (game_card.Card, String) _chooseMediumCard(
    List<(game_card.Card, String)> playableCards,
    game_card.Card? topCard,
  ) {
    // Sort by card value (lower is better for medium AI)
    playableCards.sort(
      (a, b) => a.$1.numericValue.compareTo(b.$1.numericValue),
    );

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
  static (game_card.Card, String) _chooseHardCard(
    List<(game_card.Card, String)> playableCards,
    game_card.Card? topCard,
    Player aiPlayer,
    Room room,
  ) {
    // Prefer playing from hand first, then face-up, then face-down
    playableCards.sort((a, b) {
      final zoneOrder = {'hand': 0, 'faceUp': 1, 'faceDown': 2};
      return zoneOrder[a.$2]!.compareTo(zoneOrder[b.$2]!);
    });

    playableCards.sort((a, b) {
      final scoreA = _hardCardScore(a, topCard, aiPlayer, room);
      final scoreB = _hardCardScore(b, topCard, aiPlayer, room);
      final scoreCompare = scoreA.compareTo(scoreB);
      if (scoreCompare != 0) return scoreCompare;
      return a.$1.numericValue.compareTo(b.$1.numericValue);
    });

    final choice = playableCards.first;
    _log.info('Hard AI chose: ${choice.$1.displayString} from ${choice.$2}');
    return choice;
  }

  static int _hardCardScore(
    (game_card.Card, String) choice,
    game_card.Card? topCard,
    Player aiPlayer,
    Room room,
  ) {
    final card = choice.$1;
    final sameRankCount = _sameRankCount(choice, aiPlayer);
    final canShedGroup = choice.$2 != 'faceDown' && sameRankCount > 1;
    var score = card.numericValue;

    if (canShedGroup) score -= sameRankCount * 8;
    if (aiPlayer.totalCards <= sameRankCount) score -= 40;
    if (room.resetActive || topCard == null) {
      if (card.hasSpecialEffect) score += 18;
      return score;
    }

    if (card.value == '10') {
      score -= room.playPile.length >= 3 || aiPlayer.totalCards <= 3 ? 30 : 6;
    } else if (card.value == '9') {
      score -= 18;
    } else if (card.value == '7') {
      score -= 14;
    } else if (card.value == '2') {
      score += topCard.numericValue >= 10 || aiPlayer.forcedToPlayLow
          ? -22
          : 12;
    } else if (card.value == '5') {
      score += ['J', 'Q', 'K'].contains(topCard.value) ? -16 : 8;
    } else if (['J', 'Q', 'K', 'A'].contains(card.value)) {
      score += 10;
    }

    return score;
  }

  static int _sameRankCount((game_card.Card, String) choice, Player aiPlayer) {
    final sourceCards = switch (choice.$2) {
      'hand' => aiPlayer.hand,
      'faceUp' => aiPlayer.faceUp,
      _ => const <game_card.Card>[],
    };
    return sourceCards.where((c) => c.value == choice.$1.value).length;
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

    // All cards are 5s, so treat the pile like an open reset.
    return null;
  }

  /// Check if a card can be played (same logic as game state)
  static bool _canPlayCard(
    game_card.Card card,
    game_card.Card? topCard,
    Player player,
    bool resetActive,
  ) {
    if (topCard == null) {
      return true; // First card of the game
    }

    if (resetActive) {
      return true; // Any card can be played after a 2
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
