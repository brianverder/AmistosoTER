import 'package:equatable/equatable.dart';

enum RequestStatus {
  active,
  matched,
  completed,
  cancelled;

  factory RequestStatus.fromString(String? value) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequestStatus.active,
    );
  }

  String get label {
    switch (this) {
      case RequestStatus.active:
        return 'Activa';
      case RequestStatus.matched:
        return 'Match';
      case RequestStatus.completed:
        return 'Completada';
      case RequestStatus.cancelled:
        return 'Cancelada';
    }
  }
}

class MatchUserPreview extends Equatable {
  final String id;
  final String name;
  final String? phone;

  const MatchUserPreview({
    required this.id,
    required this.name,
    this.phone,
  });

  factory MatchUserPreview.fromJson(Map<String, dynamic> json) {
    return MatchUserPreview(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, phone];
}

class TeamPreview extends Equatable {
  final String id;
  final String name;
  final String? instagram;
  final int? gamesWon;
  final int? gamesLost;
  final int? gamesDrawn;
  final int? totalGames;

  const TeamPreview({
    required this.id,
    required this.name,
    this.instagram,
    this.gamesWon,
    this.gamesLost,
    this.gamesDrawn,
    this.totalGames,
  });

  factory TeamPreview.fromJson(Map<String, dynamic> json) {
    return TeamPreview(
      id: json['id'] as String,
      name: json['name'] as String,
      instagram: json['instagram'] as String?,
      gamesWon: (json['gamesWon'] as num?)?.toInt(),
      gamesLost: (json['gamesLost'] as num?)?.toInt(),
      gamesDrawn: (json['gamesDrawn'] as num?)?.toInt() ??
          (json['gamesDraw'] as num?)?.toInt(),
      totalGames: (json['totalGames'] as num?)?.toInt() ??
          (json['gamesPlayed'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, instagram, gamesWon, gamesLost, gamesDrawn, totalGames];
}

class MatchRequestModel extends Equatable {
  final String id;
  final String userId;
  final String teamId;
  final String? footballType;
  final String? fieldName;
  final String? fieldAddress;
  final String? country;
  final String? state;
  final double? fieldPrice;
  final DateTime? matchDate;
  final String? league;
  final String? description;
  final RequestStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TeamPreview? team;
  final MatchUserPreview? user;
  final String? matchId;

  const MatchRequestModel({
    required this.id,
    required this.userId,
    required this.teamId,
    this.footballType,
    this.fieldName,
    this.fieldAddress,
    this.country,
    this.state,
    this.fieldPrice,
    this.matchDate,
    this.league,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.team,
    this.user,
    this.matchId,
  });

  factory MatchRequestModel.fromJson(Map<String, dynamic> json) {
    final matchData = json['match'] as Map<String, dynamic>?;
    return MatchRequestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      teamId: json['teamId'] as String,
      footballType: json['footballType'] as String?,
      fieldName: json['fieldName'] as String?,
      fieldAddress: json['fieldAddress'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      fieldPrice: json['fieldPrice'] != null
          ? double.tryParse(json['fieldPrice'].toString())
          : null,
      matchDate: json['matchDate'] != null
          ? DateTime.tryParse(json['matchDate'].toString())
          : null,
      league: json['league'] as String?,
      description: json['description'] as String?,
      status: RequestStatus.fromString(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      team: json['team'] != null
          ? TeamPreview.fromJson(json['team'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? MatchUserPreview.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      matchId: matchData?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'teamId': teamId,
        'footballType': footballType,
        'fieldName': fieldName,
        'fieldAddress': fieldAddress,
        'country': country,
        'state': state,
        'fieldPrice': fieldPrice,
        'matchDate': matchDate?.toIso8601String(),
        'league': league,
        'description': description,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        teamId,
        footballType,
        fieldName,
        fieldAddress,
        country,
        state,
        fieldPrice,
        matchDate,
        league,
        description,
        status,
        createdAt,
        updatedAt,
        team,
        user,
        matchId,
      ];
}
