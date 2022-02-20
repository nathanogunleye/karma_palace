import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/deck_of_cards_response.dart';
import 'package:karma_palace/model/pile.dart';

part 'piles_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PilesResponse extends DeckOfCardsResponse {
  Map<String, Pile> piles;

  PilesResponse(bool success, String deckId, int remaining, this.piles)
      : super(success, deckId, remaining);

  factory PilesResponse.fromJson(Map<String, dynamic> json) =>
      _$PilesResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PilesResponseToJson(this);
}
