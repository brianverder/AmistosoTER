import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_request_model.dart';
import '../services/api_client.dart';
import '../services/requests_service.dart';
import 'auth_provider.dart';

// ─── Service provider ─────────────────────────────────────────────────────

final requestsServiceProvider = Provider<RequestsService>((ref) {
  return RequestsService(ref.watch(apiClientProvider));
});

// ─── Filtros ──────────────────────────────────────────────────────────────

class RequestFilters {
  final String tab; // 'available' | 'my'
  final String? mode; // alias for tab used by some screens
  final String? footballType;
  final String? country;

  const RequestFilters({
    this.tab = 'available',
    this.mode,
    this.footballType,
    this.country,
  });

  @override
  bool operator ==(Object other) =>
      other is RequestFilters &&
      other.tab == tab &&
      other.mode == mode &&
      other.footballType == footballType &&
      other.country == country;

  @override
  int get hashCode => Object.hash(tab, mode, footballType, country);

  RequestFilters copyWith({
    String? tab,
    String? mode,
    String? footballType,
    String? country,
    bool clearFootballType = false,
    bool clearCountry = false,
  }) {
    return RequestFilters(
      tab: tab ?? this.tab,
      mode: mode ?? this.mode,
      footballType: clearFootballType ? null : footballType ?? this.footballType,
      country: clearCountry ? null : country ?? this.country,
    );
  }
}

final requestFiltersProvider =
    StateProvider<RequestFilters>((ref) => const RequestFilters());

// ─── Lista de solicitudes (family: acepta RequestFilters como argumento) ──

final requestsProvider = FutureProvider.autoDispose
    .family<List<MatchRequestModel>, RequestFilters>((ref, filters) async {
  final service = ref.watch(requestsServiceProvider);
  final mode = filters.mode ?? filters.tab;
  if (mode == 'my') {
    return service.getMyRequests(
      footballType: filters.footballType,
      country: filters.country,
    );
  } else {
    return service.getAvailableRequests(
      footballType: filters.footballType,
      country: filters.country,
    );
  }
});

// ─── Solicitud individual ─────────────────────────────────────────────────

final requestDetailProvider =
    FutureProvider.autoDispose.family<MatchRequestModel, String>((ref, id) async {
  return ref.watch(requestsServiceProvider).getRequest(id);
});

// ─── Solicitudes públicas ─────────────────────────────────────────────────

final publicRequestFiltersProvider =
    StateProvider<RequestFilters>((_) => const RequestFilters());

final publicRequestsProvider = FutureProvider.autoDispose
    .family<List<MatchRequestModel>, RequestFilters>((ref, filters) async {
  return ref.watch(requestsServiceProvider).getPublicRequests(
        footballType: filters.footballType,
        country: filters.country,
      );
});

final publicRequestDetailProvider =
    FutureProvider.autoDispose.family<MatchRequestModel, String>((ref, id) async {
  return ref.watch(requestsServiceProvider).getPublicRequest(id);
});
