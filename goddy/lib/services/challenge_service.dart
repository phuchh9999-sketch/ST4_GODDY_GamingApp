import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/challenge_room.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import 'api_client.dart';

class ChallengeService extends ChangeNotifier {
  static const String _syncBaseUrl = 'https://ntfy.sh';

  ChallengeRoom? _currentRoom;
  ChallengeRoom? get currentRoom => _currentRoom;

  final Map<String, ChallengeRoom> _activeRooms = {};
  final List<String> _recentRoomCodes = [];
  List<String> get recentRoomCodes => List.unmodifiable(_recentRoomCodes);

  String? lastJoinError;
  Timer? _roomSyncTimer;
  bool _isDisposed = false;

  // Friends list
  final List<FriendModel> _friends = [
    const FriendModel(id: 'fr_1', username: 'NguyenVanA', avatar: '⚡', isOnline: true, rankTier: 'Bạch Kim', favoriteGame: 'Rubik 3D'),
    const FriendModel(id: 'fr_2', username: 'TranThiB', avatar: '👑', isOnline: true, rankTier: 'Vàng', favoriteGame: 'Quantum Caro'),
    const FriendModel(id: 'fr_3', username: 'LeHoangC', avatar: '🥷', isOnline: true, rankTier: 'Kim Cương', favoriteGame: 'Sudoku Hologram'),
    const FriendModel(id: 'fr_4', username: 'CyberGamer99', avatar: '🚀', isOnline: true, rankTier: 'Cao Thủ', favoriteGame: 'Gyro Slide Puzzle'),
  ];

  List<FriendModel> get friends => List.unmodifiable(_friends);

  @override
  void dispose() {
    _isDisposed = true;
    _roomSyncTimer?.cancel();
    super.dispose();
  }

  void addFriend(String username, {String avatar = '🎮', String rankTier = 'Đồng'}) {
    if (username.trim().isEmpty) return;
    final newFriend = FriendModel(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      avatar: avatar,
      isOnline: true,
      rankTier: rankTier,
      favoriteGame: 'Rubik 3D',
    );
    _friends.add(newFriend);
    notifyListeners();
  }

  // Generate 6-char alphanumeric room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Broadcast current room state to network channel
  Future<void> _broadcastRoom(ChallengeRoom room) async {
    try {
      final code = room.roomCode.toUpperCase();
      final url = Uri.parse('$_syncBaseUrl/goddy_room_$code');
      await http.post(
        url,
        headers: {'Title': 'DuelRoom', 'Priority': '3'},
        body: jsonEncode(room.toJson()),
      ).timeout(const Duration(seconds: 4));

      // Also announce in global room directory so other devices can discover
      if (room.status == RoomStatus.waiting || room.status == RoomStatus.ready) {
        final dirUrl = Uri.parse('$_syncBaseUrl/goddy_active_rooms');
        await http.post(
          dirUrl,
          headers: {'Title': 'ActiveRoom', 'Priority': '2'},
          body: jsonEncode({
            'code': code,
            'hostName': room.hostName,
            'hostAvatar': room.hostAvatar,
            'gameType': room.gameType.name,
            'status': room.status.name,
            'time': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Broadcast room error: $e');
    }
  }

  // Fetch remote room state from network channel
  Future<ChallengeRoom?> _fetchRemoteRoom(String roomCode) async {
    try {
      final code = roomCode.toUpperCase();
      final url = Uri.parse('$_syncBaseUrl/goddy_room_$code/json?poll=1');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final lines = res.body.split('\n');
        for (int i = lines.length - 1; i >= 0; i--) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          try {
            final jsonLine = jsonDecode(line);
            if (jsonLine['event'] == 'message' && jsonLine['message'] != null) {
              final map = jsonDecode(jsonLine['message']);
              return ChallengeRoom.fromJson(map);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Fetch remote room error: $e');
    }
    return null;
  }

  void _startRoomSync(String roomCode) {
    _roomSyncTimer?.cancel();
    _roomSyncTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      if (_isDisposed || _currentRoom == null || _currentRoom!.roomCode != roomCode) {
        _roomSyncTimer?.cancel();
        return;
      }

      ChallengeRoom? remote;

      // 1. Try polling WebAPI first
      try {
        final res = await ApiClient().get('challenge/$roomCode');
        if (res != null && res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          remote = ChallengeRoom.fromJson(data);
        }
      } catch (e) {
        debugPrint('Poll room WebAPI error: $e');
      }

      // 2. Fallback to ntfy.sh channel
      remote ??= await _fetchRemoteRoom(roomCode);

      if (remote != null && _currentRoom != null && !_isDisposed) {
        final hasChanges = remote.guestId != _currentRoom!.guestId ||
            remote.guestName != _currentRoom!.guestName ||
            remote.hostReady != _currentRoom!.hostReady ||
            remote.guestReady != _currentRoom!.guestReady ||
            remote.status != _currentRoom!.status ||
            remote.hostScore != _currentRoom!.hostScore ||
            remote.guestScore != _currentRoom!.guestScore ||
            remote.lastMoveJson != _currentRoom!.lastMoveJson ||
            remote.currentTurn != _currentRoom!.currentTurn ||
            remote.winnerId != _currentRoom!.winnerId;

        if (hasChanges) {
          _currentRoom = remote;
          _activeRooms[roomCode] = remote;
          notifyListeners();
        }
      }
    });
  }

  Future<ChallengeRoom?> createRoomAsync({
    required UserModel host,
    required GameType gameType,
    String difficulty = 'Normal',
  }) async {
    final code = _generateRoomCode();
    final seed = Random().nextInt(100000);

    try {
      final res = await ApiClient().post('challenge/create', {
        'RoomCode': code,
        'HostId': host.id,
        'HostName': host.username,
        'HostAvatar': host.avatar,
        'GameType': gameType.name,
        'Difficulty': difficulty,
        'Seed': seed,
      });

      if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final room = ChallengeRoom.fromJson(data);
        _activeRooms[room.roomCode] = room;
        _currentRoom = room;
        if (!_recentRoomCodes.contains(room.roomCode)) {
          _recentRoomCodes.insert(0, room.roomCode);
        }
        notifyListeners();
        _broadcastRoom(room);
        _startRoomSync(room.roomCode);
        return room;
      }
    } catch (e) {
      debugPrint('WebAPI create room error: $e');
    }

    return null;
  }

  ChallengeRoom createRoom({
    required UserModel host,
    required GameType gameType,
    String difficulty = 'Normal',
  }) {
    final code = _generateRoomCode();
    final seed = Random().nextInt(100000);

    final room = ChallengeRoom(
      roomCode: code,
      hostId: host.id,
      hostName: host.username,
      hostAvatar: host.avatar,
      gameType: gameType,
      difficulty: difficulty,
      seed: seed,
      status: RoomStatus.waiting,
      hostReady: false,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );

    _activeRooms[code] = room;
    _currentRoom = room;
    if (!_recentRoomCodes.contains(code)) {
      _recentRoomCodes.insert(0, code);
    }
    notifyListeners();

    // Post to WebAPI backend
    ApiClient().post('challenge/create', {
      'RoomCode': code,
      'HostId': host.id,
      'HostName': host.username,
      'HostAvatar': host.avatar,
      'GameType': gameType.name,
      'Difficulty': difficulty,
      'Seed': seed,
    }).catchError((e) {
      debugPrint('WebAPI create room error: $e');
      return null;
    });

    _broadcastRoom(room);
    _startRoomSync(code);
    return room;
  }

  Future<bool> joinRoom({
    required String roomCode,
    required UserModel guest,
  }) async {
    lastJoinError = null;
    final code = roomCode.trim().toUpperCase();
    if (code.isEmpty) {
      lastJoinError = 'Vui lòng nhập mã phòng!';
      return false;
    }

    // 1. Attempt join via WebAPI
    try {
      final res = await ApiClient().post('challenge/join', {
        'RoomCode': code,
        'GuestId': guest.id,
        'GuestName': guest.username,
        'GuestAvatar': guest.avatar,
      });

      if (res != null) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final room = ChallengeRoom.fromJson(data);

          // Tuyệt đối không cho phép phòng bot ảo CyberRival
          if (room.hostId == 'host_auto' || room.hostName.toLowerCase() == 'cyberrival') {
            lastJoinError = 'Không tìm thấy phòng của người chơi thật!';
            return false;
          }

          _activeRooms[code] = room;
          _currentRoom = room;
          if (!_recentRoomCodes.contains(code)) {
            _recentRoomCodes.insert(0, code);
          }
          notifyListeners();
          _broadcastRoom(room);
          _startRoomSync(code);
          return true;
        } else if (res.statusCode == 404) {
          try {
            final errData = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
            lastJoinError = errData['message'] as String? ?? 'Phòng $code không tồn tại!';
          } catch (_) {
            lastJoinError = 'Phòng $code không tồn tại! Hãy chắc chắn Chủ phòng đã tạo phòng thành công.';
          }
          return false;
        } else if (res.statusCode == 400) {
          lastJoinError = 'Phòng $code đã có 2 người chơi!';
          return false;
        }
      }
    } catch (e) {
      debugPrint('Join room via WebAPI error: $e');
    }

    // 2. Kênh local broadcast chỉ dành cho người chơi thật (không bot)
    final ChallengeRoom? existing = await _fetchRemoteRoom(code) ?? _activeRooms[code];
    if (existing != null && existing.hostId != 'host_auto' && existing.hostName.toLowerCase() != 'cyberrival') {
      if (existing.isFull && existing.guestId != guest.id) {
        lastJoinError = 'Phòng $code đã có 2 người chơi!';
        return false;
      }

      final updated = existing.copyWith(
        guestId: guest.id,
        guestName: guest.username,
        guestAvatar: guest.avatar,
        status: RoomStatus.ready,
        guestReady: false,
        hostScore: 0,
        guestScore: 0,
      );

      _activeRooms[code] = updated;
      _currentRoom = updated;
      if (!_recentRoomCodes.contains(code)) {
        _recentRoomCodes.insert(0, code);
      }
      notifyListeners();

      await _broadcastRoom(updated);
      _startRoomSync(code);
      return true;
    }

    lastJoinError = 'Không thể kết nối đến phòng $code! Hãy kiểm tra địa chỉ IP máy chủ trong Cài đặt mạng.';
    return false;
  }

  Future<void> fetchActiveRooms() async {
    try {
      final res = await ApiClient().get('challenge/active');
      if (res != null && res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        for (final item in list) {
          final room = ChallengeRoom.fromJson(item as Map<String, dynamic>);
          _activeRooms[room.roomCode] = room;
          if (!_recentRoomCodes.contains(room.roomCode)) {
            _recentRoomCodes.add(room.roomCode);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch active rooms error: $e');
    }
  }

  void inviteFriend(FriendModel friend) {
    if (_currentRoom == null) return;
    _currentRoom = _currentRoom!.copyWith(
      guestId: friend.id,
      guestName: friend.username,
      guestAvatar: friend.avatar,
      status: RoomStatus.ready,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void addAiChallenger() {
    if (_currentRoom == null) return;
    final botNames = ['CyberBot_Omega', 'GoddyAI_Alpha', 'ViperMatrix'];
    final botAvatars = ['🤖', '👾', '🔥'];
    final idx = Random().nextInt(botNames.length);

    _currentRoom = _currentRoom!.copyWith(
      guestId: 'bot_ai_${Random().nextInt(1000)}',
      guestName: botNames[idx],
      guestAvatar: botAvatars[idx],
      status: RoomStatus.ready,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void toggleHostReady() {
    if (_currentRoom == null) return;
    final newReady = !_currentRoom!.hostReady;
    _currentRoom = _currentRoom!.copyWith(hostReady: newReady);
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();

    _broadcastRoom(_currentRoom!);
    ApiClient().post('challenge/ready', {
      'RoomCode': _currentRoom!.roomCode,
      'UserId': _currentRoom!.hostId,
      'IsReady': newReady,
    }).catchError((_) => null);
  }

  void toggleGuestReady() {
    if (_currentRoom == null) return;
    final newReady = !_currentRoom!.guestReady;
    _currentRoom = _currentRoom!.copyWith(guestReady: newReady);
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();

    _broadcastRoom(_currentRoom!);
    ApiClient().post('challenge/ready', {
      'RoomCode': _currentRoom!.roomCode,
      'UserId': _currentRoom!.guestId ?? '',
      'IsReady': newReady,
    }).catchError((_) => null);
  }

  bool canStartMatch() {
    if (_currentRoom == null) return false;
    return _currentRoom!.bothReady;
  }

  void startMatch() {
    if (_currentRoom == null) return;
    if (!_currentRoom!.bothReady) return;

    _currentRoom = _currentRoom!.copyWith(
      status: RoomStatus.playing,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);

    ApiClient().post('challenge/start', {
      'RoomCode': _currentRoom!.roomCode,
    }).catchError((_) => null);
  }

  Future<void> sendCaroMove({
    required String roomCode,
    required String userId,
    required int row,
    required int col,
    required int player,
    String? skill,
    int? swapR1,
    int? swapC1,
    int? swapR2,
    int? swapC2,
  }) async {
    final payload = {
      'RoomCode': roomCode,
      'UserId': userId,
      'Row': row,
      'Col': col,
      'Player': player,
      'Skill': skill,
      'SwapR1': swapR1,
      'SwapC1': swapC1,
      'SwapR2': swapR2,
      'SwapC2': swapC2,
    };

    if (_currentRoom != null && _currentRoom!.roomCode == roomCode) {
      _currentRoom = _currentRoom!.copyWith(
        lastMoveJson: jsonEncode(payload),
        currentTurn: player == 1 ? 2 : 1,
      );
      _activeRooms[roomCode] = _currentRoom!;
      notifyListeners();
    }

    try {
      await ApiClient().post('challenge/move', payload);
    } catch (e) {
      debugPrint('Error sending Caro move: $e');
    }

    if (_currentRoom != null) {
      _broadcastRoom(_currentRoom!);
    }
  }

  void submitResult({
    required String userId,
    required String username,
    required int timeSeconds,
    required int mistakes,
    required int score,
  }) {
    if (_currentRoom == null) return;

    ApiClient().post('challenge/submit-result', {
      'RoomCode': _currentRoom!.roomCode,
      'UserId': userId,
      'Score': score,
      'TimeSeconds': timeSeconds,
      'Mistakes': mistakes,
    }).catchError((_) => null);

    final myResult = PlayerDuelResult(
      userId: userId,
      username: username,
      timeSeconds: timeSeconds,
      mistakes: mistakes,
      score: score,
      isCompleted: true,
    );

    if (_currentRoom!.hostId == userId) {
      _currentRoom = _currentRoom!.copyWith(
        hostResult: myResult,
        hostScore: score,
        hostTimeSeconds: timeSeconds,
      );
    } else {
      _currentRoom = _currentRoom!.copyWith(
        guestResult: myResult,
        guestScore: score,
        guestTimeSeconds: timeSeconds,
      );
    }

    // Game đối kháng 1v1: Người đầu tiên hoàn thành sẽ chiến thắng và kết thúc ván
    if (_currentRoom!.status != RoomStatus.finished) {
      _currentRoom = _currentRoom!.copyWith(
        status: RoomStatus.finished,
        winnerId: userId,
      );
    }

    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void resetRoomToReady() {
    if (_currentRoom == null) return;
    final newSeed = Random().nextInt(100000);
    _currentRoom = _currentRoom!.copyWith(
      status: RoomStatus.ready,
      hostReady: false,
      guestReady: false,
      seed: newSeed,
      lastMoveJson: null,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);

    ApiClient().post('challenge/ready', {
      'RoomCode': _currentRoom!.roomCode,
      'UserId': _currentRoom!.hostId,
      'IsReady': false,
    }).catchError((_) => null);
    if (_currentRoom!.guestId != null) {
      ApiClient().post('challenge/ready', {
        'RoomCode': _currentRoom!.roomCode,
        'UserId': _currentRoom!.guestId!,
        'IsReady': false,
      }).catchError((_) => null);
    }
  }

  void leaveRoom() {
    _roomSyncTimer?.cancel();
    _currentRoom = null;
    notifyListeners();
  }
}
