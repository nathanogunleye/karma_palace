import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/model/api/deck_of_cards_response.dart';

part 'shuffle_cards_response.g.dart';

@JsonSerializable(explicitToJson: true)
class DeckResponse extends DeckOfCardsResponse {
  bool? shuffled;

  DeckResponse({
    super.success,
    super.deckId,
    super.remaining,
    this.shuffled,
  });

  factory DeckResponse.fromJson(Map<String, dynamic> json) =>
      _$DeckResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeckResponseToJson(this);
}
