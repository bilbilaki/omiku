import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import '../../env.dart'; // Assumes malapitokensc or kitsu tokens are configured here
import '../../models/models.dart';

class AnimeMangaService {
  static const String _malBaseUrl = 'https://api.myanimelist.net/v2';
  static const String _anilistBaseUrl = 'https://graphql.anilist.co';
  static const String _token =
      malapitokensc; // Pattern matched with tmdbapitokensc

  final http.Client _client;

  AnimeMangaService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _malHeaders => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  // ==========================================================================
  // ANIME / SERIES LAYER (MyAnimeList System)
  // ==========================================================================

  /// Search or discover anime entries with pagination support
  Future<GetAnimeListResult> searchAnime(
    String query, {
    int limit = 10,
    int offset = 0,
  }) async {
    if (query.isEmpty) return GetAnimeListResult(data: []);

    final response = await _client.get(
      Uri.parse(
        '$_malBaseUrl/anime?q=${Uri.encodeComponent(query)}&limit=$limit&offset=$offset',
      ),
      headers: _malHeaders,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return GetAnimeListResult.fromJson(jsonMap);
    }
    throw Exception('Failed to look up Anime directory context');
  }

  /// Detailed lookup framework for individual Anime items
  Future<GetAnimeDetailResult> getAnimeDetails(int animeId) async {
    // List of fields required to fully hydrate our detailed UI layer models
    final fields = [
      'id',
      'title',
      'main_picture',
      'alternative_titles',
      'start_date',
      'end_date',
      'synopsis',
      'mean',
      'rank',
      'popularity',
      'num_list_users',
      'num_scoring_users',
      'nsfw',
      'created_at',
      'updated_at',
      'media_type',
      'status',
      'genres',
      'my_list_status',
      'num_episodes',
      'start_season',
      'broadcast',
      'source',
      'average_episode_duration',
      'rating',
      'pictures',
      'background',
      'related_anime',
      'recommendations',
      'studios',
      'statistics',
    ].join(',');

    final response = await _client.get(
      Uri.parse('$_malBaseUrl/anime/$animeId?fields=$fields'),
      headers: _malHeaders,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return GetAnimeDetailResult.fromJson(jsonMap);
    }
    throw Exception('Failed to fetch discrete details for Anime ID: $animeId');
  }

  // ==========================================================================
  // MANGA / BOOKS LAYER (AniList GraphQL System matching MangaMedia specs)
  // ==========================================================================

  /// Fetches Book / Manga information through GraphQL to map directly to MangaData structures
  Future<GetMangaResult> getMangaDetails(int mangaId) async {
    const String query = r'''
      query ($id: Int) {
        Media (id: $id, type: MANGA) {
          id
          description
          chapters
          bannerImage
          hashtag
          genres
          title {
            english
            romaji
            native
          }
          coverImage {
            medium
            large
            extraLarge
            color
          }
        }
      }
    ''';

    final response = await _client.post(
      Uri.parse(_anilistBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'query': query,
        'variables': {'id': mangaId},
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return GetMangaResult.fromJson(jsonMap);
    }
    throw Exception(
      'Failed to handle incoming stream resolution from AniList framework',
    );
  }

  Future<GetMangaResult> searchMangaDetails(String query) async {
    // 1. Hardcode MANGA directly into the query string and rename the variable
    const String graphQLQuery = r'''
      query ($search: String) {
         Media(search: $search, type: MANGA) {
            averageScore
            bannerImage
            chapters
            coverImage {
              medium
              large
              extraLarge
              color
            }
            id
            idMal
            description
            meanScore
            popularity
            title {
              romaji
              english
              native
            }
         }
      }
    ''';

    final response = await _client.post(
      Uri.parse(_anilistBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'query': graphQLQuery, // 2. Use the renamed query string variable
        'variables': {
          'search': query,
        }, // 3. 'query' now correctly refers to your method parameter
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return GetMangaResult.fromJson(jsonMap);
    }
    throw Exception(
      'Failed to handle incoming stream resolution from AniList framework',
    );
  }
}
