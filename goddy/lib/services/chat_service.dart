import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'api_client.dart';

class ChatService extends ChangeNotifier {
  static const String _keyGlobalChat = 'goddy_global_chat_v1';
  static const String _chatEndpoint = 'https://ntfy.sh/goddy_global_chat';

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Timer? _chatSyncTimer;
  bool _isDisposed = false;

  static const List<String> quickStickers = [
    '⚔️ Solo Caro không?',
    '🔥 Quá đỉnh!',
    '🧩 Cần gợi ý Rubik!',
    '😎 GG! Trận hay lắm!',
    '🚀 Sắp phá kỷ lục!',
    '💀 Toang rồi ông giáo ơi!',
    '⏳ Chờ tí sắp xong!',
    '🏆 Bảng vàng vẫy gọi!',
  ];

  ChatService() {
    _loadMessages();
    _startChatSync();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _chatSyncTimer?.cancel();
    super.dispose();
  }

  void _startChatSync() {
    _chatSyncTimer?.cancel();
    _chatSyncTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (!_isDisposed) {
        _pollRemoteMessages();
      }
    });
    // Immediate first poll
    _pollRemoteMessages();
  }

  Future<void> refreshMessages() async {
    await _pollRemoteMessages();
  }

  Future<void> _loadMessages() async {
    await StorageService.init();
    final raw = StorageService.getStringList(_keyGlobalChat) ?? [];
    _messages.clear();

    if (raw.isEmpty) {
      // Khoi dong phong chat trong sach khong co tin nhan he thong ao
      _saveMessages();
    } else {
      for (final item in raw) {
        try {
          final msg = ChatMessage.fromJson(jsonDecode(item));
          // Loc bo tin nhan ao cu neu con sot lai trong local cache
          if (msg.senderId != 'bot_admin' && 
              msg.senderId != 'sys' && 
              msg.senderId != 'player_viper' && 
              msg.senderId != 'player_caro' &&
              !msg.senderName.contains('GoddySystem')) {
            _messages.add(msg);
          }
        } catch (e) {
          debugPrint('Error decoding chat message: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    final raw = _messages.map((e) => jsonEncode(e.toJson())).toList();
    await StorageService.setStringList(_keyGlobalChat, raw);
  }

  Future<void> _pollRemoteMessages() async {
    // 1. Poll from WebAPI & SQLite
    try {
      final res = await ApiClient().get('chat/messages?roomId=global');
      if (res != null && res.statusCode == 200 && !_isDisposed) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        bool hasNew = false;
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final id = m['id']?.toString() ?? 'msg_${m['timestamp']}';
          final sId = m['senderId']?.toString() ?? '';
          final sName = m['senderName']?.toString() ?? '';
          if (sId == 'sys' || sId == 'bot_admin' || sId == 'viper' || sName.contains('GoddySystem')) {
            continue; // Bo qua tin nhan he thong ao
          }
          if (!_messages.any((x) => x.id == id)) {
            final rawTime = m['timestamp']?.toString();
            final parsedTime = rawTime != null
                ? (DateTime.tryParse(rawTime)?.toLocal() ?? DateTime.now())
                : DateTime.now();

            _messages.add(ChatMessage(
              id: id,
              roomId: m['roomId']?.toString() ?? 'global',
              senderId: m['senderId']?.toString() ?? '',
              senderName: m['senderName']?.toString() ?? 'Game thủ',
              senderAvatar: m['senderAvatar']?.toString() ?? '👾',
              text: m['text']?.toString() ?? '',
              isSticker: m['isSticker'] as bool? ?? false,
              timestamp: parsedTime,
            ));
            hasNew = true;
          }
        }
        if (hasNew && !_isDisposed) {
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          await _saveMessages();
          notifyListeners();
        }
      }
    } catch (_) {}

    // 2. Backup poll from cloud channel
    try {
      final url = Uri.parse('$_chatEndpoint/json?poll=1&since=all');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 && !_isDisposed) {
        final lines = res.body.split('\n');
        bool hasNew = false;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final jsonLine = jsonDecode(trimmed);
            if (jsonLine['event'] == 'message' && jsonLine['message'] != null) {
              final rawMsg = jsonLine['message'];
              final msgMap = jsonDecode(rawMsg);
              final msg = ChatMessage.fromJson(msgMap);
              if (!_messages.any((m) => m.id == msg.id)) {
                _messages.add(msg);
                hasNew = true;
              }
            }
          } catch (_) {}
        }

        if (hasNew && !_isDisposed) {
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          await _saveMessages();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> sendMessage({
    required UserModel sender,
    required String text,
    String roomId = 'global',
    bool isSticker = false,
  }) async {
    if (text.trim().isEmpty) return;

    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      roomId: roomId,
      senderId: sender.id,
      senderName: sender.username,
      senderAvatar: sender.avatar,
      text: text.trim(),
      isSticker: isSticker,
      timestamp: DateTime.now(),
    );

    _messages.add(msg);
    await _saveMessages();
    notifyListeners();

    // 1. Post to WebAPI & SQLite (Kích hoạt Live Terminal Logger trên màn hình HDMI)
    try {
      ApiClient().post('chat/send', {
        'id': msg.id,
        'roomId': roomId,
        'senderId': sender.id,
        'senderName': sender.username,
        'senderAvatar': sender.avatar,
        'text': text.trim(),
        'isSticker': isSticker,
        'timestamp': msg.timestamp.toUtc().toIso8601String(),
      }).catchError((e) => null);
    } catch (_) {}

    // 2. Broadcast across devices via cloud endpoint
    try {
      await http.post(
        Uri.parse(_chatEndpoint),
        headers: {'Title': 'Chat', 'Priority': '3'},
        body: jsonEncode(msg.toJson()),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Failed to broadcast chat: $e');
    }
  }

  List<ChatMessage> getMessagesForRoom(String roomId) {
    return _messages.where((m) => m.roomId == roomId).toList();
  }
}
