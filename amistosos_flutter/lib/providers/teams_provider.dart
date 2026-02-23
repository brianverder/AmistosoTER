import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/team_model.dart';
import '../services/api_client.dart';
import '../services/teams_service.dart';
import 'auth_provider.dart';

// ─── Service provider ─────────────────────────────────────────────────────

final teamsServiceProvider = Provider<TeamsService>((ref) {
  return TeamsService(ref.watch(apiClientProvider));
});

// ─── Lista de equipos del usuario ─────────────────────────────────────────

class TeamsNotifier extends AsyncNotifier<List<TeamModel>> {
  @override
  Future<List<TeamModel>> build() async {
    return await ref.read(teamsServiceProvider).getMyTeams();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(teamsServiceProvider).getMyTeams(),
    );
  }

  Future<TeamModel?> createTeam({
    required String name,
    String? instagram,
  }) async {
    try {
      final team = await ref.read(teamsServiceProvider).createTeam(
            name: name,
            instagram: instagram,
          );
      state = AsyncData([...(state.valueOrNull ?? []), team]);
      return team;
    } on ApiException catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteTeam(String id) async {
    try {
      await ref.read(teamsServiceProvider).deleteTeam(id);
      state = AsyncData(
        (state.valueOrNull ?? []).where((t) => t.id != id).toList(),
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  void updateTeamLocally(TeamModel updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final t in current)
        if (t.id == updated.id) updated else t,
    ]);
  }

  Future<TeamModel?> updateTeam({
    required String id,
    required String name,
    String? instagram,
  }) async {
    try {
      final updated = await ref.read(teamsServiceProvider).updateTeam(
            id,
            name: name,
            instagram: instagram,
          );
      updateTeamLocally(updated);
      return updated;
    } on ApiException {
      rethrow;
    }
  }
}

final teamsNotifierProvider =
    AsyncNotifierProvider<TeamsNotifier, List<TeamModel>>(TeamsNotifier.new);

// ─── Equipo individual ────────────────────────────────────────────────────

final teamDetailProvider =
    FutureProvider.family<TeamModel, String>((ref, id) async {
  return ref.watch(teamsServiceProvider).getTeam(id);
});

final teamStatsProvider =
    FutureProvider.family<TeamModel, String>((ref, id) async {
  return ref.watch(teamsServiceProvider).getTeamStats(id);
});
