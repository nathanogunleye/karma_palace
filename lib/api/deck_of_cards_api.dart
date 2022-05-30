import 'package:dio/dio.dart';
import 'package:karma_palace/model/draw_a_card_response.dart';
import 'package:karma_palace/model/piles_response.dart';
import 'package:karma_palace/model/shuffle_cards_response.dart';
import 'package:retrofit/retrofit.dart';

part 'deck_of_cards_api.g.dart';

@RestApi(baseUrl: 'https://deckofcardsapi.com')
abstract class DeckOfCardsAPI {
  factory DeckOfCardsAPI(Dio dio, {String baseUrl}) = _DeckOfCardsAPI;

  @GET('/api/deck/new/shuffle')
  Future<DeckResponse> createNewShuffledDeck(
    @Query('deck_count') int deckCount,
    @Query('jokers_enabled') bool jokersEnabled,
  );

  @GET('/api/deck/{deckId}/draw')
  Future<DrawCardResponse> drawCards(
    @Path('deckId') String deckId,
    @Query('count') int count,
  );

  @GET('/api/deck/{deckId}/shuffle')
  Future<DeckResponse> reshuffleCards(
    @Path('deckId') String deckId,
    @Query('remaining') bool remaining,
  );

  @GET('/api/deck/new')
  Future<DeckResponse> createNewDeck(
    @Query('jokers_enabled') bool jokersEnabled,
  );

  @GET('/api/deck/new/shuffle')
  Future<DeckResponse> createPartialDeck(
    @Query('cards') String cards,
  );

  @GET('/api/deck/{deckId}/pile/{pileName}/add')
  Future<PilesResponse> addToPile(
    @Path('deckId') String deckId,
    @Path('pileName') String pileName,
    @Query('cards') String cards,
  );

  @GET('/api/deck/{deckId}/pile/{pileName}/list')
  Future<PilesResponse> listPiles(
    @Path('deckId') String deckId,
    @Path('pileName') String pileName,
  );

  @GET('/api/deck/{deckId}/pile/{pileName}/draw')
  Future<PilesResponse> drawFromPiles(
    @Path('deckId') String deckId,
    @Path('pileName') String pileName,
    @Query('cards') String cards,
  );

  @GET('/api/deck/{deckId}/pile/{pileName}/return')
  Future<PilesResponse> returnCardsToDeck(
    @Path('deckId') String deckId,
    @Path('pileName') String pileName,
    @Query('cards') String cards,
  );
}
