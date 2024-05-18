class Card {
  /// The image URL of the card
  String image;

  /// The value of the card (e.g. 9, 10, JACK, QUEEN)
  String value;

  /// The suit of the card (e.g. HEARTS, SPADES)
  String suit;

  /// Card code (e.g. 8C for 8 of Clubs)
  String code;

  Card({
    required this.image,
    required this.value,
    required this.suit,
    required this.code,
  });
}
