import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

@JsonSerializable(explicitToJson: true)
class Card {
  String image;

  String value;

  String suit;

  String code;

  Card(this.image, this.value, this.suit, this.code);

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);

  Map<String, dynamic> toJson() => _$CardToJson(this);
}
