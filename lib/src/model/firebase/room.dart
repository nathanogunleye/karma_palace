import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/card.dart';

part 'room.g.dart';

@JsonSerializable(explicitToJson: true)
class Room {
  /// Room ID. This is the same ID used for the deck API
  String id;

  /// List of players in the room
  List<Player> players;

  /// Player in play
  String currentPlayer;

  /// Game state
  GameState gameState;

  /// Remaining cards in deck
  List<Card> deck;

  /// Cards in the play pile
  List<Card> playPile;

  /// Room creation timestamp
  DateTime createdAt;

  /// Last activity timestamp
  DateTime lastActivity;

  /// Flag indicating if a 2 was played (reset effect active)
  bool resetActive;

  Room({
    required this.id,
    required this.players,
    required this.currentPlayer,
    required this.gameState,
    required this.deck,
    required this.playPile,
    required this.createdAt,
    required this.lastActivity,
    this.resetActive = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // Handle null values with defaults
    final safeJson = <String, dynamic>{
      'id': json['id'] ?? '',
      'players': json['players'] ?? [],
      'currentPlayer': json['currentPlayer'] ?? '',
      'gameState': json['gameState'] ?? 'waiting',
      'deck': json['deck'] ?? [],
      'playPile': json['playPile'] ?? [],
      'createdAt': json['createdAt'] ?? DateTime.now().toIso8601String(),
      'lastActivity': json['lastActivity'] ?? DateTime.now().toIso8601String(),
      'resetActive': json['resetActive'] ?? false,
    };
    return _$RoomFromJson(safeJson);
  }

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}

enum GameState {
  @JsonValue('waiting')
  waiting,
  @JsonValue('playing')
  playing,
  @JsonValue('finished')
  finished,
}
