import 'package:json_annotation/json_annotation.dart';
import 'package:karma_palace/src/model/api/playing_card.dart';

part 'pile.g.dart';

@JsonSerializable(explicitToJson: true)
class Pile {
  List<PlayingCard>? cards;

  int? remaining;

  Pile({
    this.cards,
    this.remaining,
  });

  factory Pile.fromJson(Map<String, dynamic> json) => _$PileFromJson(json);

  Map<String, dynamic> toJson() => _$PileToJson(this);
}
