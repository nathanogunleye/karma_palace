import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/deck_of_cards_response.dart';

part 'shuffle_cards_response.g.dart';

@JsonSerializable(explicitToJson: true)
class DeckResponse extends DeckOfCardsResponse {
  bool shuffled;

  DeckResponse(bool success, String deckId, int remaining, this.shuffled)
      : super(success, deckId, remaining);

  factory DeckResponse.fromJson(Map<String, dynamic> json) =>
      _$DeckResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeckResponseToJson(this);
}
