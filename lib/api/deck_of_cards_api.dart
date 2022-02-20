import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'deck_of_cards_api.g.dart';

@RestApi(baseUrl: 'https://deckofcardsapi.com')
abstract class DeckOfCardsAPI {
  factory DeckOfCardsAPI(Dio dio, {String baseUrl}) = _DeckOfCardsAPI;

  @GET('/api/deck/new/shuffle?deck_count=1')
  Future<dynamic> shuffleCards();
}
