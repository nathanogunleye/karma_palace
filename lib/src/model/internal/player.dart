import 'package:karma_palace/src/model/internal/card.dart';

class Player {
  /// Name of player
  String name;

  /// Cards in players hand
  List<Card> hand;

  /// Cards faced down in front of player
  List<Card> downHand;

  /// Cards faced up in front of player
  List<Card> upHand;

  Player({
    required this.name,
    required this.hand,
    required this.downHand,
    required this.upHand,
  });
}
