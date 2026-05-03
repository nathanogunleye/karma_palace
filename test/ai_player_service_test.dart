import 'package:flutter_test/flutter_test.dart';
import 'package:karma_palace/src/games_services/ai_player_service.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';

void main() {
  group('AIPlayerService', () {
    test('hard AI plays matching ranks together', () {
      final sixA = _card('6', 'six-a');
      final sixB = _card('6', 'six-b');
      final room = _room(
        playPile: [_card('4', 'top')],
        ai: _ai(hand: [sixA, sixB, _card('K', 'king')]),
      );

      final choice = AIPlayerService.chooseCardsToPlay(
        room.players.first,
        room,
        AIDifficulty.hard,
      );

      expect(choice, isNotNull);
      expect(choice!.$2, equals('hand'));
      expect(choice.$1.map((c) => c.id), containsAll(['six-a', 'six-b']));
      expect(choice.$1, hasLength(2));
    });

    test('medium AI also uses matching ranks to shed cards', () {
      final eightA = _card('8', 'eight-a');
      final eightB = _card('8', 'eight-b');
      final room = _room(
        playPile: [_card('6', 'top')],
        ai: _ai(hand: [_card('K', 'king'), eightA, eightB]),
      );

      final choice = AIPlayerService.chooseCardsToPlay(
        room.players.first,
        room,
        AIDifficulty.medium,
      );

      expect(choice, isNotNull);
      expect(choice!.$1.map((c) => c.id), containsAll(['eight-a', 'eight-b']));
      expect(choice.$1, hasLength(2));
    });

    test('hard AI saves reset cards when a lower regular card is enough', () {
      final room = _room(
        playPile: [_card('3', 'top')],
        ai: _ai(hand: [_card('2', 'reset'), _card('4', 'four')]),
      );

      final choice = AIPlayerService.chooseCardsToPlay(
        room.players.first,
        room,
        AIDifficulty.hard,
      );

      expect(choice, isNotNull);
      expect(choice!.$1.single.value, equals('4'));
    });

    test('hard AI prioritizes burning a built-up pile', () {
      final room = _room(
        playPile: [
          _card('4', 'pile-1'),
          _card('6', 'pile-2'),
          _card('8', 'top'),
        ],
        ai: _ai(hand: [_card('10', 'burn'), _card('K', 'king')]),
      );

      final choice = AIPlayerService.chooseCardsToPlay(
        room.players.first,
        room,
        AIDifficulty.hard,
      );

      expect(choice, isNotNull);
      expect(choice!.$1.single.value, equals('10'));
    });

    test('AI respects reset-active turns', () {
      final room = _room(
        resetActive: true,
        playPile: [_card('K', 'top')],
        ai: _ai(hand: [_card('3', 'three'), _card('A', 'ace')]),
      );

      final choice = AIPlayerService.chooseCardsToPlay(
        room.players.first,
        room,
        AIDifficulty.hard,
      );

      expect(choice, isNotNull);
      expect(choice!.$1.single.value, equals('3'));
    });
  });
}

game_card.Card _card(String value, String id) {
  return game_card.Card(suit: '♠', value: value, id: id);
}

Player _ai({required List<game_card.Card> hand}) {
  return Player(
    id: 'ai',
    name: 'AI',
    isPlaying: true,
    hand: hand,
    faceUp: const [],
    faceDown: const [],
    isConnected: true,
    lastSeen: DateTime(2026),
    turnOrder: 0,
  );
}

Room _room({
  required List<game_card.Card> playPile,
  required Player ai,
  bool resetActive = false,
}) {
  return Room(
    id: 'room',
    players: [ai],
    currentPlayer: ai.id,
    gameState: GameState.playing,
    deck: const [],
    playPile: playPile,
    createdAt: DateTime(2026),
    lastActivity: DateTime(2026),
    resetActive: resetActive,
  );
}
