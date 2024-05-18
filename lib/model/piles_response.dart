import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/deck_of_cards_response.dart';
import 'package:karma_palace/model/pile.dart';
import 'package:karma_palace/model/playing_card.dart';

part 'piles_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PilesResponse extends DeckOfCardsResponse {
  Map<String, Pile>? piles;
  List<PlayingCard>? cards;

  PilesResponse({
    super.success,
    super.deckId,
    super.remaining,
    this.piles,
    this.cards,
  });

  factory PilesResponse.fromJson(Map<String, dynamic> json) =>
      _$PilesResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PilesResponseToJson(this);
}
