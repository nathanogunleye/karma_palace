import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/firebase/player.dart';

part 'room.g.dart';

@JsonSerializable(explicitToJson: true)
class Room {
  /// Room ID. This is the same ID used for the deck API
  String id;

  /// List of players in the room
  List<Player> players;

  /// Player in play
  String currentPlayer;

  Room({
    required this.id,
    required this.players,
    required this.currentPlayer,
  });

  factory Room.fromJson(Map<String, dynamic> json) =>
      _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
