import 'package:equatable/equatable.dart';

class TeamModel extends Equatable {
  final String id;
  final String name;
  final String? instagram;
  final String? league;
  final String userId;
  final int gamesWon;
  final int gamesLost;
  final int gamesDrawn;
  final int totalGames;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeamModel({
    required this.id,
    required this.name,
    this.instagram,
    this.league,
    required this.userId,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.gamesDrawn = 0,
    this.totalGames = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      instagram: json['instagram'] as String?,
      league: json['league'] as String?,
      userId: json['userId'] as String,
      gamesWon: (json['gamesWon'] as num?)?.toInt() ?? 0,
      gamesLost: (json['gamesLost'] as num?)?.toInt() ?? 0,
      gamesDrawn: (json['gamesDrawn'] as num?)?.toInt() ?? 0,
      totalGames: (json['totalGames'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'instagram': instagram,
        'league': league,
        'userId': userId,
        'gamesWon': gamesWon,
        'gamesLost': gamesLost,
        'gamesDrawn': gamesDrawn,
        'totalGames': totalGames,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Porcentaje de victorias sobre partidos jugados
  double get winRate => totalGames > 0 ? (gamesWon / totalGames) * 100 : 0.0;

  /// Puntos estilo liga: 3 pts por victoria, 1 por empate
  int get points => (gamesWon * 3) + gamesDrawn;

  TeamModel copyWith({
    String? id,
    String? name,
    String? instagram,
    String? league,
    String? userId,
    int? gamesWon,
    int? gamesLost,
    int? gamesDrawn,
    int? totalGames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      instagram: instagram ?? this.instagram,
      league: league ?? this.league,
      userId: userId ?? this.userId,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      gamesDrawn: gamesDrawn ?? this.gamesDrawn,
      totalGames: totalGames ?? this.totalGames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        instagram,
        league,
        userId,
        gamesWon,
        gamesLost,
        gamesDrawn,
        totalGames,
        createdAt,
        updatedAt,
      ];
}
