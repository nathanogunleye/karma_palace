import 'package:json_annotation/json_annotation.dart';

part 'playing_card.g.dart';

@JsonSerializable(explicitToJson: true)
class PlayingCard {
  /// The image URL of the card
  String image;

  /// The value of the card (e.g. 9, 10, JACK, QUEEN)
  String value;

  /// The suit of the card (e.g. HEARTS, SPADES)
  String suit;

  String code;

  PlayingCard(this.image, this.value, this.suit, this.code);

  factory PlayingCard.fromJson(Map<String, dynamic> json) =>
      _$PlayingCardFromJson(json);

  Map<String, dynamic> toJson() => _$PlayingCardToJson(this);
}
