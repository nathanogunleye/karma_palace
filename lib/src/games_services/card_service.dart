import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:karma_palace/src/api/deck_of_cards_api.dart';
import 'package:karma_palace/src/model/api/draw_a_card_response.dart';
import 'package:karma_palace/src/model/api/piles_response.dart';
import 'package:karma_palace/src/model/api/shuffle_cards_response.dart';
import 'package:logging/logging.dart';

class CardService {
  static final Logger _log = Logger('CardService');
  final Dio _dio = Dio();

  late DeckOfCardsAPI _deckOfCardsAPI;

  static final CardService _cardService = CardService._internal();

  factory CardService() {
    return _cardService;
  }

  CardService._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
          _log.info(options.path);
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          _log.finest(response);
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          _log.severe('DioError', e.error);
          return handler.next(e);
        },
      ),
    );

    _deckOfCardsAPI = DeckOfCardsAPI(_dio);
  }

  @visibleForTesting
  // ignore: invalid_use_of_visible_for_testing_member
  CardService.test(String baseUrl) {
    _deckOfCardsAPI = DeckOfCardsAPI(_dio, baseUrl: baseUrl);
  }

  Future<DeckResponse> createNewShuffledDeck(bool includeJoker) {
    return _deckOfCardsAPI.createNewShuffledDeck(1, includeJoker);
  }

  Future<DrawCardResponse> drawCards(String deckId, int count) {
    return _deckOfCardsAPI.drawCards(deckId, count);
  }

  /// Add cards (by code) to pile. This will NOT return cards in the pile.
  Future<PilesResponse> addToPile(
      String deckId, String pileName, List<String> cards) {
    return _deckOfCardsAPI.addToPile(deckId, pileName, cards.join(','));
  }

  Future<PilesResponse> drawFromPile(
      String deckId, String pileName, List<String> cards) {
    return _deckOfCardsAPI.drawFromPiles(deckId, pileName, cards.join(','));
  }

  Future<PilesResponse> listPile(String deckId, String pileName) {
    return _deckOfCardsAPI.listPiles(deckId, pileName);
  }
}
