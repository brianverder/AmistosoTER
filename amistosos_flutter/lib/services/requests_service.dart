import '../core/constants.dart';
import '../models/match_request_model.dart';
import 'api_client.dart';

class RequestsService {
  final ApiClient _client;

  RequestsService(this._client);

  // ─── Filtros ──────────────────────────────────────────────────────────────

  /// Obtiene solicitudes disponibles (other users) con filtros opcionales.
  Future<List<MatchRequestModel>> getAvailableRequests({
    String? footballType,
    String? country,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'mode': 'available',
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (footballType != null && footballType.isNotEmpty) {
      params['footballType'] = footballType;
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }

    final result = await _client.get(
      AppConstants.requestsEndpoint,
      queryParameters: params,
    );

    // El endpoint puede devolver { requests: [...], pagination: {...} } o []
    if (result is Map<String, dynamic> && result.containsKey('requests')) {
      return (result['requests'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MatchRequestModel.fromJson)
          .toList();
    } else if (result is List<dynamic>) {
      return result
          .cast<Map<String, dynamic>>()
          .map(MatchRequestModel.fromJson)
          .toList();
    }
    return [];
  }

  /// Obtiene las solicitudes propias del usuario.
  Future<List<MatchRequestModel>> getMyRequests({
    String? footballType,
    String? country,
  }) async {
    final params = <String, dynamic>{'mode': 'my'};
    if (footballType != null && footballType.isNotEmpty) {
      params['footballType'] = footballType;
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }

    final result = await _client.get(
      AppConstants.requestsEndpoint,
      queryParameters: params,
    );

    if (result is List<dynamic>) {
      return result
          .cast<Map<String, dynamic>>()
          .map(MatchRequestModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<MatchRequestModel> getRequest(String id) async {
    final data = await _client.get('${AppConstants.requestsEndpoint}/$id')
        as Map<String, dynamic>;
    return MatchRequestModel.fromJson(data);
  }

  // ─── Crear ────────────────────────────────────────────────────────────────

  Future<MatchRequestModel> createRequest({
    required String teamId,
    String? footballType,
    String? fieldName,
    String? fieldAddress,
    String? country,
    String? state,
    double? fieldPrice,
    DateTime? matchDate,
    String? league,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'teamId': teamId,
      if (footballType != null && footballType.isNotEmpty)
        'footballType': footballType,
      if (fieldName != null && fieldName.isNotEmpty) 'fieldName': fieldName,
      if (fieldAddress != null && fieldAddress.isNotEmpty)
        'fieldAddress': fieldAddress,
      if (country != null && country.isNotEmpty) 'country': country,
      if (state != null && state.isNotEmpty) 'state': state,
      if (fieldPrice != null) 'fieldPrice': fieldPrice,
      if (matchDate != null) 'matchDate': matchDate.toIso8601String(),
      if (league != null && league.isNotEmpty) 'league': league,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    final data = await _client.post(
      AppConstants.requestsEndpoint,
      data: body,
    ) as Map<String, dynamic>;
    return MatchRequestModel.fromJson(data);
  }

  // ─── Eliminar ─────────────────────────────────────────────────────────────

  Future<void> deleteRequest(String id) async {
    await _client.delete('${AppConstants.requestsEndpoint}/$id');
  }

  // ─── Match (unirse a una solicitud) ──────────────────────────────────────

  /// Hace "match" con una solicitud existente enviando el teamId del usuario.
  Future<Map<String, dynamic>> matchRequest(
      String requestId, String teamId) async {
    final data = await _client.post(
      '${AppConstants.requestsEndpoint}/$requestId/match',
      data: {'teamId': teamId},
    ) as Map<String, dynamic>;
    return data;
  }

  // ─── Solicitudes públicas (sin auth) ─────────────────────────────────────

  Future<List<MatchRequestModel>> getPublicRequests({
    String? footballType,
    String? country,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (footballType != null && footballType.isNotEmpty) {
      params['footballType'] = footballType;
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }

    final result = await _client.get(
      AppConstants.publicRequestsEndpoint,
      queryParameters: params,
    );

    if (result is Map<String, dynamic> && result.containsKey('requests')) {
      return (result['requests'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MatchRequestModel.fromJson)
          .toList();
    } else if (result is List<dynamic>) {
      return result
          .cast<Map<String, dynamic>>()
          .map(MatchRequestModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<MatchRequestModel> getPublicRequest(String id) async {
    final data = await _client.get('${AppConstants.publicRequestsEndpoint}/$id')
        as Map<String, dynamic>;
    return MatchRequestModel.fromJson(data);
  }
}
