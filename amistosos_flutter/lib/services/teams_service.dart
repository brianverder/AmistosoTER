import '../core/constants.dart';
import '../models/team_model.dart';
import 'api_client.dart';

class TeamsService {
  final ApiClient _client;

  TeamsService(this._client);

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<List<TeamModel>> getMyTeams() async {
    final data = await _client.get(AppConstants.teamsEndpoint) as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(TeamModel.fromJson)
        .toList();
  }

  Future<TeamModel> getTeam(String id) async {
    final data = await _client.get('${AppConstants.teamsEndpoint}/$id')
        as Map<String, dynamic>;
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> createTeam({
    required String name,
    String? instagram,
    String? league,
  }) async {
    final data = await _client.post(
      AppConstants.teamsEndpoint,
      data: {
        'name': name,
        if (instagram != null && instagram.isNotEmpty) 'instagram': instagram,
        if (league != null && league.isNotEmpty) 'league': league,
      },
    ) as Map<String, dynamic>;
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> updateTeam(
    String id, {
    String? name,
    String? instagram,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (instagram != null) body['instagram'] = instagram;

    final data = await _client.put(
      '${AppConstants.teamsEndpoint}/$id',
      data: body,
    ) as Map<String, dynamic>;
    return TeamModel.fromJson(data);
  }

  Future<void> deleteTeam(String id) async {
    await _client.delete('${AppConstants.teamsEndpoint}/$id');
  }

  // ─── Estadísticas ─────────────────────────────────────────────────────────

  /// Devuelve el detalle completo con estadísticas del equipo.
  Future<TeamModel> getTeamStats(String id) async {
    final data = await _client.get(
      '${AppConstants.teamsEndpoint}/$id/stats',
    ) as Map<String, dynamic>;
    return TeamModel.fromJson(data['team'] as Map<String, dynamic>);
  }
}
