import 'package:equatable/equatable.dart';

enum MatchStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  factory MatchStatus.fromString(String? value) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchStatus.pending,
    );
  }
}

class MatchResultModel extends Equatable {
  final String id;
  final String matchId;
  final int team1Score;
  final int team2Score;
  final String? winnerId;
  final DateTime? createdAt;

  const MatchResultModel({
    required this.id,
    required this.matchId,
    required this.team1Score,
    required this.team2Score,
    this.winnerId,
    this.createdAt,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      team1Score: (json['team1Score'] as num).toInt(),
      team2Score: (json['team2Score'] as num).toInt(),
      winnerId: json['winnerId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, matchId, team1Score, team2Score, winnerId, createdAt];
}

class TeamSnapshot extends Equatable {
  final String id;
  final String name;
  final String? instagram;

  const TeamSnapshot({required this.id, required this.name, this.instagram});

  factory TeamSnapshot.fromJson(Map<String, dynamic> json) {
    return TeamSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      instagram: json['instagram'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, instagram];
}

class UserSnapshot extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  const UserSnapshot({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory UserSnapshot.fromJson(Map<String, dynamic> json) {
    return UserSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone];
}

class MatchRequestSnapshot extends Equatable {
  final String? footballType;
  final String? fieldAddress;
  final DateTime? matchDate;

  const MatchRequestSnapshot({
    this.footballType,
    this.fieldAddress,
    this.matchDate,
  });

  factory MatchRequestSnapshot.fromJson(Map<String, dynamic> json) {
    return MatchRequestSnapshot(
      footballType: json['footballType'] as String?,
      fieldAddress: json['fieldAddress'] as String?,
      matchDate: json['matchDate'] != null
          ? DateTime.tryParse(json['matchDate'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [footballType, fieldAddress, matchDate];
}

class MatchModel extends Equatable {
  final String id;
  final String matchRequestId;
  final String team1Id;
  final String team2Id;
  final String userId1;
  final String userId2;
  final MatchStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TeamSnapshot? team1;
  final TeamSnapshot? team2;
  final UserSnapshot? user1;
  final UserSnapshot? user2;
  final MatchResultModel? matchResult;
  final MatchRequestSnapshot? matchRequest;

  const MatchModel({
    required this.id,
    required this.matchRequestId,
    required this.team1Id,
    required this.team2Id,
    required this.userId1,
    required this.userId2,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.team1,
    this.team2,
    this.user1,
    this.user2,
    this.matchResult,
    this.matchRequest,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      matchRequestId: json['matchRequestId'] as String? ?? '',
      team1Id: json['team1Id'] as String? ?? '',
      team2Id: json['team2Id'] as String? ?? '',
      userId1: json['userId1'] as String? ?? '',
      userId2: json['userId2'] as String? ?? '',
      status: MatchStatus.fromString(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      team1: json['team1'] != null
          ? TeamSnapshot.fromJson(json['team1'] as Map<String, dynamic>)
          : null,
      team2: json['team2'] != null
          ? TeamSnapshot.fromJson(json['team2'] as Map<String, dynamic>)
          : null,
      user1: json['user1'] != null
          ? UserSnapshot.fromJson(json['user1'] as Map<String, dynamic>)
          : null,
      user2: json['user2'] != null
          ? UserSnapshot.fromJson(json['user2'] as Map<String, dynamic>)
          : null,
      matchResult: json['matchResult'] != null
          ? MatchResultModel.fromJson(
              json['matchResult'] as Map<String, dynamic>)
          : null,
      matchRequest: json['matchRequest'] != null
          ? MatchRequestSnapshot.fromJson(
              json['matchRequest'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isCompleted => matchResult != null;

  bool get isPending => status == MatchStatus.pending && !isCompleted;

  @override
  List<Object?> get props => [
        id,
        matchRequestId,
        team1Id,
        team2Id,
        userId1,
        userId2,
        status,
        createdAt,
        updatedAt,
        team1,
        team2,
        user1,
        user2,
        matchResult,
        matchRequest,
      ];
}
