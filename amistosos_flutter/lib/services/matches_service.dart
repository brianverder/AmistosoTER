import '../core/constants.dart';
import '../models/match_model.dart';
import 'api_client.dart';

class MatchesService {
  final ApiClient _client;

  MatchesService(this._client);

  Future<List<MatchModel>> getMyMatches() async {
    final data =
        await _client.get(AppConstants.matchesEndpoint) as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(MatchModel.fromJson)
        .toList();
  }

  Future<MatchModel> getMatch(String id) async {
    final data = await _client.get('${AppConstants.matchesEndpoint}/$id')
        as Map<String, dynamic>;
    return MatchModel.fromJson(data);
  }

  /// Carga el resultado de un partido (team1Score / team2Score).
  Future<MatchModel> submitResult(
    String matchId, {
    required int team1Score,
    required int team2Score,
  }) async {
    final data = await _client.post(
      '${AppConstants.matchesEndpoint}/$matchId/result',
      data: {
        'team1Score': team1Score,
        'team2Score': team2Score,
      },
    ) as Map<String, dynamic>;
    return MatchModel.fromJson(data);
  }
}
