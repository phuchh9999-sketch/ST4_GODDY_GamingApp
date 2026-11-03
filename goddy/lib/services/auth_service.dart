import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static const String _keyCurrentUser = 'goddy_current_user';
  static const String _keyAllUsers = 'goddy_registered_users';

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    await StorageService.init();
    final userJson = StorageService.getString(_keyCurrentUser);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('Error parsing user session: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String avatar = '🤖',
  }) async {
    // 1. Try WebAPI first
    try {
      final res = await ApiClient().post('auth/register', {
        'email': email,
        'username': username,
        'password': password,
        'avatar': avatar,
      });
      if (res != null) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data['token'] != null) {
            await StorageService.setString('jwt_token', data['token'].toString());
          }
          final newUser = UserModel.fromJson(data);
          _currentUser = newUser;
          await StorageService.setString(_keyCurrentUser, jsonEncode(newUser.toJson()));
          notifyListeners();
          return true;
        } else if (res.statusCode == 400) {
          return false; // Email đã tồn tại trên WebAPI CSDL
        }
      }
    } catch (e) {
      debugPrint('WebAPI register fallback: $e');
    }

    final allUsersRaw = StorageService.getStringList(_keyAllUsers) ?? [];
    
    // Check if email already registered
    for (final raw in allUsersRaw) {
      final data = jsonDecode(raw);
      if (data['email'] == email) {
        return false; // Email already in use
      }
    }

    final newUser = UserModel(
      id: 'goddy_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      username: username,
      avatar: avatar,
      exp: 100, // Welcome EXP
      badges: ['Tân Thủ Goddy', 'Cyber Rookie'],
    );

    // Save to all users
    final userMap = newUser.toJson();
    userMap['password'] = password;
    allUsersRaw.add(jsonEncode(userMap));
    await StorageService.setStringList(_keyAllUsers, allUsersRaw);

    // Set as current session
    _currentUser = newUser;
    await StorageService.setString(_keyCurrentUser, jsonEncode(newUser.toJson()));
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    // 1. Try WebAPI first
    try {
      final res = await ApiClient().post('auth/login', {
        'email': email,
        'password': password,
      });
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentUser = UserModel.fromJson(data);
        if (data['token'] != null) {
          await StorageService.setString('jwt_token', data['token'].toString());
        }
        await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('WebAPI login fallback: $e');
    }

    final allUsersRaw = StorageService.getStringList(_keyAllUsers) ?? [];

    for (final raw in allUsersRaw) {
      final data = jsonDecode(raw);
      if (data['email'] == email && data['password'] == password) {
        _currentUser = UserModel.fromJson(data);
        await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return true;
      }
    }

    // If no user exists yet, allow demo guest login
    if (email == 'player@goddy.io' || email == 'admin@goddy.io') {
      _currentUser = UserModel(
        id: 'goddy_pro_1',
        email: email,
        username: email.startsWith('admin') ? 'GoddyAdmin' : 'CyberPhuc',
        avatar: '⚡',
        exp: 3200,
        gamesPlayed: 14,
        winsCount: 11,
        rubikBestSeconds: 42,
        caroBestScore: 1850,
        sudokuBestSeconds: 165,
        puzzleBestSeconds: 28,
        badges: ['Bậc Thầy Rubik', 'Bất Bại Caro', 'Đại Kiện Tướng'],
      );
      await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> demoQuickLogin() async {
    // 1. Thử đăng nhập qua WebAPI để lưu và đồng bộ CSDL SQLite goddy.db
    try {
      final res = await ApiClient().post('auth/login', {
        'email': 'player@goddy.io',
        'password': 'password123',
      });
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        _currentUser = UserModel.fromJson(data);
        if (data['token'] != null) {
          await StorageService.setString('jwt_token', data['token'].toString());
        }
        await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('WebAPI quick login fallback: $e');
    }

    // 2. Dự phòng ngoại tuyến nếu chưa kết nối tới máy chủ
    _currentUser = const UserModel(
      id: 'fc8c08b9-e9d5-482b-a3f9-0a47535e08e1',
      email: 'player@goddy.io',
      username: 'CyberPlayer',
      avatar: '🚀',
      exp: 1250,
      gamesPlayed: 8,
      winsCount: 6,
      rubikBestSeconds: 58,
      caroBestScore: 1420,
      sudokuBestSeconds: 210,
      puzzleBestSeconds: 35,
      badges: ['Chiến Binh Cyber', 'Giải Đố Siêu Tốc'],
    );
    await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? avatar}) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      username: username,
      avatar: avatar,
    );
    await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> addExp(int expAmount) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      exp: _currentUser!.exp + expAmount,
    );
    await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> recordGameWin({
    required bool isWin,
    int expGained = 100,
    int? rubikSecs,
    int? caroScore,
    int? sudokuSecs,
    int? puzzleSecs,
  }) async {
    if (_currentUser == null) return;

    int newRubik = _currentUser!.rubikBestSeconds;
    if (rubikSecs != null && rubikSecs > 0) {
      newRubik = newRubik == 0 ? rubikSecs : (rubikSecs < newRubik ? rubikSecs : newRubik);
    }

    int newCaro = _currentUser!.caroBestScore;
    if (caroScore != null && caroScore > newCaro) {
      newCaro = caroScore;
    }

    int newSudoku = _currentUser!.sudokuBestSeconds;
    if (sudokuSecs != null && sudokuSecs > 0) {
      newSudoku = newSudoku == 0 ? sudokuSecs : (sudokuSecs < newSudoku ? sudokuSecs : newSudoku);
    }

    int newPuzzle = _currentUser!.puzzleBestSeconds;
    if (puzzleSecs != null && puzzleSecs > 0) {
      newPuzzle = newPuzzle == 0 ? puzzleSecs : (puzzleSecs < newPuzzle ? puzzleSecs : newPuzzle);
    }

    _currentUser = _currentUser!.copyWith(
      exp: _currentUser!.exp + expGained,
      gamesPlayed: _currentUser!.gamesPlayed + 1,
      winsCount: _currentUser!.winsCount + (isWin ? 1 : 0),
      rubikBestSeconds: newRubik,
      caroBestScore: newCaro,
      sudokuBestSeconds: newSudoku,
      puzzleBestSeconds: newPuzzle,
    );

    await StorageService.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    await StorageService.remove(_keyCurrentUser);
    notifyListeners();
  }
}
