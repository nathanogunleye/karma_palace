import 'package:json_annotation/json_annotation.dart';

part 'deck_of_cards_response.g.dart';

@JsonSerializable(explicitToJson: true)
class DeckOfCardsResponse {
  bool success;

  @JsonKey(name: 'deck_id')
  String deckId;

  int remaining;

  DeckOfCardsResponse(this.success, this.deckId, this.remaining);

  factory DeckOfCardsResponse.fromJson(Map<String, dynamic> json) =>
      _$DeckOfCardsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeckOfCardsResponseToJson(this);
}
