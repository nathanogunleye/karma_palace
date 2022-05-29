import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:karma_palace/api/deck_of_cards_api.dart';
import 'package:karma_palace/model/draw_a_card_response.dart';
import 'package:karma_palace/model/shuffle_cards_response.dart';

class CardService {
  final Dio _dio = Dio();

  late DeckOfCardsAPI _deckOfCardsAPI;

  static final CardService _cardService = CardService._internal();

  factory CardService() {
    return _cardService;
  }

  CardService._internal() {
    _deckOfCardsAPI = DeckOfCardsAPI(_dio);
  }

  @visibleForTesting
  // ignore: invalid_use_of_visible_for_testing_member
  CardService.test(String baseUrl) {
    _deckOfCardsAPI = DeckOfCardsAPI(_dio, baseUrl: baseUrl);
  }

  Future<DeckResponse> createNewShuffledDeck() {
    return _deckOfCardsAPI.createNewShuffledDeck(1);
  }

  Future<DrawCardResponse> drawCards(String deckId, int count) {
    return _deckOfCardsAPI.drawCards(deckId, count);
  }
}
