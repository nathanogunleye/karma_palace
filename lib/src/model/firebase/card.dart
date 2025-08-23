import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

@JsonSerializable(explicitToJson: true)
class Card {
  /// Card suit (hearts, diamonds, clubs, spades)
  String suit;

  /// Card value (2-10, J, Q, K, A)
  String value;

  /// Card ID for tracking
  String id;

  Card({
    required this.suit,
    required this.value,
    required this.id,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    // Handle null values with defaults
    final safeJson = <String, dynamic>{
      'suit': json['suit'] ?? '',
      'value': json['value'] ?? '',
      'id': json['id'] ?? '',
    };
    return _$CardFromJson(safeJson);
  }

  Map<String, dynamic> toJson() => _$CardToJson(this);

  /// Get numeric value for comparison
  int get numericValue {
    switch (value) {
      case '2': return 2;
      case '3': return 3;
      case '4': return 4;
      case '5': return 5;
      case '6': return 6;
      case '7': return 7;
      case '8': return 8;
      case '9': return 9;
      case '10': return 10;
      case 'J': return 11;
      case 'Q': return 12;
      case 'K': return 13;
      case 'A': return 14;
      default: return 0;
    }
  }

  /// Check if card has special effect
  bool get hasSpecialEffect {
    return value == '2' || value == '5' || value == '7' || 
           value == '9' || value == '10';
  }

  /// Get special effect type
  SpecialEffect? get specialEffect {
    switch (value) {
      case '2': return SpecialEffect.reset;
      case '5': return SpecialEffect.glass;
      case '7': return SpecialEffect.forceLow;
      case '9': return SpecialEffect.skip;
      case '10': return SpecialEffect.burn;
      default: return null;
    }
  }

  /// Check if card can be played on J, Q, K
  /// This method should be called with the top card as context
  bool canPlayOnHighCard(Card topCard) {
    // 5 (glass) can always be played on high cards
    if (value == '5') return true;
    
    // Special cards (2, 7, 9, 10) cannot be played on high cards
    if (hasSpecialEffect && value != '5') return false;
    
    // Higher or equal cards can be played on high cards
    if (numericValue >= topCard.numericValue) return true;
    
    // Lower cards cannot be played on high cards
    return false;
  }

  /// Get display string
  String get displayString => '$value$suit';

  @override
  String toString() => displayString;
}

enum SpecialEffect {
  @JsonValue('reset')
  reset,
  @JsonValue('glass')
  glass,
  @JsonValue('forceLow')
  forceLow,
  @JsonValue('skip')
  skip,
  @JsonValue('burn')
  burn,
} 