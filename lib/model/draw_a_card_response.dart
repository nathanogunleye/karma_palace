import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/card.dart';
import 'package:karma_palace/model/deck_of_cards_response.dart';

part 'draw_a_card_response.g.dart';

@JsonSerializable(explicitToJson: true)
class DrawACardResponse extends DeckOfCardsResponse {
  List<Card> cards;

  DrawACardResponse(bool success, String deckId, int remaining, this.cards)
      : super(success, deckId, remaining);

  factory DrawACardResponse.fromJson(Map<String, dynamic> json) =>
      _$DrawACardResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DrawACardResponseToJson(this);
}
