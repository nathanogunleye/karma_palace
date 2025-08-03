import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/src/model/firebase/card.dart';

part 'player.g.dart';

@JsonSerializable(explicitToJson: true)
class Player {
  /// Player ID
  String id;

  /// Name of player
  String name;

  /// Flag for if this is the current user's turn
  bool isPlaying;

  /// Player's hand cards (3 cards)
  List<Card> hand;

  /// Player's face up cards (3 cards)
  List<Card> faceUp;

  /// Player's face down cards (3 cards)
  List<Card> faceDown;

  /// Player connection status
  bool isConnected;

  /// Last seen timestamp
  DateTime lastSeen;

  /// Player's turn order
  int turnOrder;

  /// Flag for if player is forced to play 7 or lower (from card 7 effect)
  bool forcedToPlayLow;

  Player({
    required this.id,
    required this.name,
    required this.isPlaying,
    required this.hand,
    required this.faceUp,
    required this.faceDown,
    required this.isConnected,
    required this.lastSeen,
    required this.turnOrder,
    this.forcedToPlayLow = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    // Handle null values with defaults
    final safeJson = <String, dynamic>{
      'id': json['id'] ?? '',
      'name': json['name'] ?? '',
      'isPlaying': json['isPlaying'] ?? false,
      'hand': json['hand'] ?? [],
      'faceUp': json['faceUp'] ?? [],
      'faceDown': json['faceDown'] ?? [],
      'isConnected': json['isConnected'] ?? false,
      'lastSeen': json['lastSeen'] ?? DateTime.now().toIso8601String(),
      'turnOrder': json['turnOrder'] ?? 0,
      'forcedToPlayLow': json['forcedToPlayLow'] ?? false,
    };
    return _$PlayerFromJson(safeJson);
  }

  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  /// Get total number of cards player has
  int get totalCards => hand.length + faceUp.length + faceDown.length;

  /// Check if player has won (no cards left)
  bool get hasWon => totalCards == 0;

  /// Check if player can play from hand
  bool get canPlayFromHand => hand.isNotEmpty;

  /// Check if player can play from face up
  bool get canPlayFromFaceUp => hand.isEmpty && faceUp.isNotEmpty;

  /// Check if player can play from face down
  bool get canPlayFromFaceDown => hand.isEmpty && faceUp.isEmpty && faceDown.isNotEmpty;
}
