import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class TopTeamEntry {
  final String id;
  final String name;
  final int gamesWon;
  final int totalGames;

  const TopTeamEntry({
    required this.id,
    required this.name,
    required this.gamesWon,
    required this.totalGames,
  });

  factory TopTeamEntry.fromJson(Map<String, dynamic> json) => TopTeamEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        gamesWon: (json['gamesWon'] as num).toInt(),
        totalGames: (json['totalGames'] as num? ?? 0).toInt(),
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final topTeamsProvider = FutureProvider.autoDispose<List<TopTeamEntry>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return [];
  final client = ref.watch(apiClientProvider);
  final data = await client.get(AppConstants.topTeamsEndpoint) as List<dynamic>;
  return data
      .cast<Map<String, dynamic>>()
      .map(TopTeamEntry.fromJson)
      .toList();
});
