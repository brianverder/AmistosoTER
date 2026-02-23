import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_model.dart';
import '../services/api_client.dart';
import '../services/matches_service.dart';
import 'auth_provider.dart';

// ─── Service provider ─────────────────────────────────────────────────────

final matchesServiceProvider = Provider<MatchesService>((ref) {
  return MatchesService(ref.watch(apiClientProvider));
});

// ─── Lista de partidos del usuario ────────────────────────────────────────

class MatchesNotifier extends AsyncNotifier<List<MatchModel>> {
  @override
  Future<List<MatchModel>> build() async {
    // Watch auth so this provider rebuilds when the session is established.
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];
    return ref.read(matchesServiceProvider).getMyMatches();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(matchesServiceProvider).getMyMatches(),
    );
  }

  Future<MatchModel?> submitResult(
    String matchId, {
    required int team1Score,
    required int team2Score,
  }) async {
    try {
      final updated = await ref.read(matchesServiceProvider).submitResult(
            matchId,
            team1Score: team1Score,
            team2Score: team2Score,
          );
      // Actualizar localmente
      final current = state.valueOrNull ?? [];
      state = AsyncData([
        for (final m in current)
          if (m.id == matchId) updated else m,
      ]);
      return updated;
    } on ApiException {
      rethrow;
    }
  }
}

final matchesNotifierProvider =
    AsyncNotifierProvider<MatchesNotifier, List<MatchModel>>(
        MatchesNotifier.new);

// ─── Partido individual ───────────────────────────────────────────────────

final matchDetailProvider =
    FutureProvider.autoDispose.family<MatchModel, String>((ref, id) async {
  return ref.watch(matchesServiceProvider).getMatch(id);
});
