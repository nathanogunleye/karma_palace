import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable(explicitToJson: true)
class Player {
  /// Name of player
  String name;

  /// Flag for if this is the current user's turn
  bool isPlaying;

  Player({
    required this.name,
    required this.isPlaying,
  });

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this);
}
