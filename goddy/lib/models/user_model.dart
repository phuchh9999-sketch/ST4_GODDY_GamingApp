import '../core/constants.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String avatar;
  final int exp;
  final int gamesPlayed;
  final int winsCount;
  final int rubikBestSeconds;
  final int caroBestScore;
  final int sudokuBestSeconds;
  final int puzzleBestSeconds;
  final List<String> badges;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.avatar,
    this.exp = 0,
    this.gamesPlayed = 0,
    this.winsCount = 0,
    this.rubikBestSeconds = 0,
    this.caroBestScore = 0,
    this.sudokuBestSeconds = 0,
    this.puzzleBestSeconds = 0,
    this.badges = const [],
  });

  RankTier get rankTier => RankTierExtension.fromExp(exp);

  double get winRate => gamesPlayed == 0 ? 0 : (winsCount / gamesPlayed) * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'avatar': avatar,
    'exp': exp,
    'gamesPlayed': gamesPlayed,
    'winsCount': winsCount,
    'rubikBestSeconds': rubikBestSeconds,
    'caroBestScore': caroBestScore,
    'sudokuBestSeconds': sudokuBestSeconds,
    'puzzleBestSeconds': puzzleBestSeconds,
    'badges': badges,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String? ?? 'user_1',
    email: json['email'] as String? ?? 'player@goddy.io',
    username: json['username'] as String? ?? 'GoddyPlayer',
    avatar: json['avatar'] as String? ?? '🤖',
    exp: json['exp'] as int? ?? 0,
    gamesPlayed: json['gamesPlayed'] as int? ?? 0,
    winsCount: json['winsCount'] as int? ?? 0,
    rubikBestSeconds: json['rubikBestSeconds'] as int? ?? 0,
    caroBestScore: json['caroBestScore'] as int? ?? 0,
    sudokuBestSeconds: json['sudokuBestSeconds'] as int? ?? 0,
    puzzleBestSeconds: json['puzzleBestSeconds'] as int? ?? 0,
    badges: (json['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? avatar,
    int? exp,
    int? gamesPlayed,
    int? winsCount,
    int? rubikBestSeconds,
    int? caroBestScore,
    int? sudokuBestSeconds,
    int? puzzleBestSeconds,
    List<String>? badges,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      exp: exp ?? this.exp,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      winsCount: winsCount ?? this.winsCount,
      rubikBestSeconds: rubikBestSeconds ?? this.rubikBestSeconds,
      caroBestScore: caroBestScore ?? this.caroBestScore,
      sudokuBestSeconds: sudokuBestSeconds ?? this.sudokuBestSeconds,
      puzzleBestSeconds: puzzleBestSeconds ?? this.puzzleBestSeconds,
      badges: badges ?? this.badges,
    );
  }
}
