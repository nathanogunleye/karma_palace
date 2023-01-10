import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable(explicitToJson: true)
class Player {
  String id;
  String name;

  Player({
    required this.id,
    required this.name,
  });

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this);
}
