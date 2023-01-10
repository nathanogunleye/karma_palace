import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/player.dart';

part 'room.g.dart';

@JsonSerializable(explicitToJson: true)
class Room {
  List<Player> players;

  Room({
    required this.players,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
