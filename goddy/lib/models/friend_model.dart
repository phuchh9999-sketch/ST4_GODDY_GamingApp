class FriendModel {
  final String id;
  final String username;
  final String avatar;
  final bool isOnline;
  final String rankTier;
  final String favoriteGame;

  const FriendModel({
    required this.id,
    required this.username,
    required this.avatar,
    this.isOnline = true,
    this.rankTier = 'Vàng',
    this.favoriteGame = 'Rubik 3D',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar': avatar,
    'isOnline': isOnline,
    'rankTier': rankTier,
    'favoriteGame': favoriteGame,
  };

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
    id: json['id'] as String? ?? '',
    username: json['username'] as String? ?? 'Bạn Bè',
    avatar: json['avatar'] as String? ?? '⚡',
    isOnline: json['isOnline'] as bool? ?? true,
    rankTier: json['rankTier'] as String? ?? 'Vàng',
    favoriteGame: json['favoriteGame'] as String? ?? 'Rubik 3D',
  );
}
