import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/deck_of_cards_response.dart';
import 'package:karma_palace/model/playing_card.dart';

part 'draw_a_card_response.g.dart';

@JsonSerializable(explicitToJson: true)
class DrawCardResponse extends DeckOfCardsResponse {
  List<PlayingCard>? cards;

  DrawCardResponse({
    bool? success,
    String? deckId,
    int? remaining,
    this.cards,
  }) : super(
          success: success,
          deckId: deckId,
          remaining: remaining,
        );

  factory DrawCardResponse.fromJson(Map<String, dynamic> json) =>
      _$DrawCardResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DrawCardResponseToJson(this);
}
