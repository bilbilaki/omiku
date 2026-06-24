import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import '../../env.dart';
import '../../models/models.dart';
import '../database.dart';

class MovieService {
  static const String _baseUrl = 'https://linod.worker-inosuke.workers.dev/3';
  static const String _apiKey = tmdbapitokensc;

  final http.Client _client;
  final DatabaseService _db = DatabaseService();

  MovieService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      };

  // ==========================================
  // AGGREGATED VIEWS & PROFILE LAYER (CACHE-FIRST)
  // ==========================================

  /// Entrypoint for full movie profile context (Details + Credits + Recommendations)
  Future<Map<String, Object>> mtom(dynamic id) async {
    final String tmdbIdStr = id.toString();
    Movie? movie = await _db.getMovieByTmdbId(tmdbIdStr);

    if (movie != null) {
      List<Movie> recommendations = await _fetchAndCacheRecommendations(tmdbIdStr);
      return {
        'details': movie,
        //'credits': movie.moviedetail.credits!,
        'recommendations': recommendations,
      };
    }

    final results = await _fetchMovieDetailsWithCreditsNetwork(int.parse(tmdbIdStr));
    return {
      'details': results[0] as Movie,
      'credits': results[1] as MovieCredits,
      'recommendations': results[2] as List<Movie>,
    };
  }

  /// Individual movie profile lookup
  Future<Movie> mtm(dynamic id) async {
    final String tmdbIdStr = id.toString();
    Movie? movie = await _db.getMovieByTmdbId(tmdbIdStr);

    if (movie != null) {
      return movie;
    }

    return await getMovieDetailsNetwork(int.parse(tmdbIdStr));
  }

  /// Individual TV/Series profile lookup
  Future<Series> tmtm(dynamic id) async {
    final String tmdbIdStr = id.toString();
    Series? series = await _db.getSeriesByTmdbId(tmdbIdStr);

    if (series != null && series.tvDetails != null && series.tvDetails!.hasDetails) {
      return series;
    }

    return await getTvShowDetailsNetwork(int.parse(tmdbIdStr));
  }

  // ==========================================
  // CORE NETWORK TO DATABASE SYNCHRONIZERS
  // ==========================================

  Future<Movie> getMovieDetailsNetwork(int movieId) async {
    final jsonMap = await getRawMovieDetails(movieId: movieId);
    
    Movie movie = await _db.getMovieByTmdbId(movieId.toString()) ?? Movie();
    movie.tmdbId = movieId.toString();
    movie.metaData.title = jsonMap['title'] ?? '';
    movie.metaData.overview = jsonMap['overview'] ?? '';
    movie.moviedetail = MovieDetail.fromJson(jsonMap);
    
    // if (jsonMap['genres'] != null) {
    //   movie.moviedetail.genres = (jsonMap['genres'] as List)
    //       .map((g) => g['name'].toString())
    //       .toList();
    // }

    await _db.put<Movie>(movie);
    return movie;
  }

  Future<Series> getTvShowDetailsNetwork(int tvShowId) async {
    final jsonMap = await getRawTvShowDetails(tvShowId: tvShowId);

    Series series = await _db.getSeriesByTmdbId(tvShowId.toString()) ?? Series();
    series.tmdbId = tvShowId.toString();
    series.metaData.title = jsonMap['name'] ?? '';
    series.metaData.overview = jsonMap['overview'] ?? '';
    series.tvDetails = TvShowDetail.fromJson(jsonMap);

    // if (jsonMap['genres'] != null) {
    //   series.metaData.genres = (jsonMap['genres'] as List)
    //       .map((g) => g['name'].toString())
    //       .toList();
    // }

    await _db.put<Series>(series);
    return series;
  }

  Future<List<dynamic>> _fetchMovieDetailsWithCreditsNetwork(int movieId) async {
    return await Future.wait([
      getMovieDetailsNetwork(movieId),
      _fetchMovieCreditsNetwork(movieId),
      _fetchAndCacheRecommendations(movieId.toString()),
    ]);
  }

  Future<MovieCredits> _fetchMovieCreditsNetwork(int movieId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/movie/$movieId/credits'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      final credits = MovieCredits.fromJson(jsonMap);

      Movie movie = await _db.getMovieByTmdbId(movieId.toString()) ?? Movie();
      movie.tmdbId = movieId.toString();
   //   movie.moviedetail.credits = credits;

      await _db.put<Movie>(movie);
      return credits;
    }
    throw Exception('Failed to fetch movie credits');
  }

  Future<List<Movie>> _fetchAndCacheRecommendations(String movieId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/movie/$movieId/recommendations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      final List<dynamic> results = jsonMap['results'] ?? [];
      List<Movie> recommendedMovies = [];

      for (var item in results) {
        final itemMap = Map<String, dynamic>.from(item);
        final int id = itemMap['id'];
        
        Movie movie = await _db.getMovieByTmdbId(id.toString()) ?? Movie();
        movie.tmdbId = id.toString();
        movie.metaData.title = itemMap['title'] ?? '';
        movie.metaData.overview = itemMap['overview'] ?? '';
        
        movie.moviedetail ??= MovieDetail.fromJson(itemMap);

        await _db.put<Movie>(movie);
        recommendedMovies.add(movie);
      }
      return recommendedMovies;
    }
    return [];
  }

  // ==========================================
  // DEEP EPISODE & SEASON METADATA HANDLERS
  // ==========================================

  /// Get details for a specific episode, including crew and guest stars
  Future<EpisodeDetails> getEpisodeDetails(int tvShowId, int seasonNumber, int episodeNumber) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tv/$tvShowId/season/$seasonNumber/episode/$episodeNumber'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return EpisodeDetails.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load episode details');
  }

  // ==========================================
  // RAW DATA FALLBACK PROVIDERS (FOR LOCALMETADATAMANAGER)
  // ==========================================

  /// Returns raw JSON payload directly for offline disk dump tasks
  Future<Map<String, dynamic>> getRawMovieDetails({required int movieId}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/movie/$movieId?append_to_response=images,videos'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch raw movie payload');
  }

  /// Returns raw JSON payload directly for offline disk dump tasks
  Future<Map<String, dynamic>> getRawTvShowDetails({required int tvShowId}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tv/$tvShowId?append_to_response=images,videos'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch raw TV payload');
  }

  // ==========================================
  // FRESH LIVE RESULTS (SEARCH METHODS BYPASS READ CACHE)
  // ==========================================

  /// Live query lookup for movies
  Future<TmdbPageResponse<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return TmdbPageResponse(page: page, results: [], totalPages: 0, totalResults: 0);

    final response = await _client.get(
      Uri.parse('$_baseUrl/search/movie?query=${Uri.encodeComponent(query)}&page=$page'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return TmdbPageResponse.fromJson(jsonMap, (itemJson) {
        final movie = Movie();
        movie.tmdbId = itemJson['id']?.toString();
        movie.metaData.title = itemJson['title'] ?? '';
        movie.metaData.overview = itemJson['overview'] ?? '';
        movie.moviedetail = MovieDetail.fromJson(itemJson);
        return movie;
      });
    }
    throw Exception('Failed to search movies');
  }

  /// Live query lookup for TV shows / Series
  Future<TmdbPageResponse<Series>> searchTvShows(String query, {int page = 1}) async {
    if (query.isEmpty) return TmdbPageResponse(page: page, results: [], totalPages: 0, totalResults: 0);

    final response = await _client.get(
      Uri.parse('$_baseUrl/search/tv?query=${Uri.encodeComponent(query)}&page=$page'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return TmdbPageResponse.fromJson(jsonMap, (itemJson) {
        final series = Series();
        series.tmdbId = itemJson['id']?.toString();
        series.metaData.title = itemJson['name'] ?? '';
        series.metaData.overview = itemJson['overview'] ?? '';
        series.tvDetails = TvShowDetail.fromJson(itemJson);
        return series;
      });
    }
    throw Exception('Failed to search TV shows');
  }

  /// Live query lookup for Actors, Directors, and Crew
  Future<TmdbPageResponse<Person>> searchPeople(String query, {int page = 1}) async {
    if (query.isEmpty) return TmdbPageResponse(page: page, results: [], totalPages: 0, totalResults: 0);

    final response = await _client.get(
      Uri.parse('$_baseUrl/search/person?query=${Uri.encodeComponent(query)}&page=$page'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return TmdbPageResponse.fromJson(jsonMap, (itemJson) {
        return Person.fromJson(itemJson);
      });
    }
    throw Exception('Failed to search cast and crew profiles');
  }
}