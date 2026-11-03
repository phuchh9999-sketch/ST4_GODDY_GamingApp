class ChatMessage {
  final String id;
  final String roomId; // 'global' or roomCode
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime timestamp;
  final bool isSticker;

  ChatMessage({
    required this.id,
    this.roomId = 'global',
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    DateTime? timestamp,
    this.isSticker = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isSticker': isSticker,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    roomId: json['roomId'] as String? ?? 'global',
    senderId: json['senderId'] as String? ?? '',
    senderName: json['senderName'] as String? ?? 'Anonymous',
    senderAvatar: json['senderAvatar'] as String? ?? '👾',
    text: json['text'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    isSticker: json['isSticker'] as bool? ?? false,
  );
}
