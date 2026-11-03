import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class GameSaveService {
  static const String _keySudokuSave = 'goddy_saved_sudoku';
  static const String _keyPuzzleSave = 'goddy_saved_puzzle';
  static const String _keyRubikSave = 'goddy_saved_rubik';
  static const String _keyCaroSave = 'goddy_saved_caro';

  // --- SUDOKU SAVE & RESUME ---
  static Future<void> saveSudokuProgress({
    required List<List<int>> initialBoard,
    required List<List<int>> currentBoard,
    required List<List<int>> solution,
    required String difficulty,
    required int secondsElapsed,
    required int mistakes,
    required int lives,
  }) async {
    final data = {
      'initialBoard': initialBoard,
      'currentBoard': currentBoard,
      'solution': solution,
      'difficulty': difficulty,
      'secondsElapsed': secondsElapsed,
      'mistakes': mistakes,
      'lives': lives,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await StorageService.setString(_keySudokuSave, jsonEncode(data));
  }

  static Map<String, dynamic>? getSavedSudoku() {
    final raw = StorageService.getString(_keySudokuSave);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading saved sudoku: $e');
      return null;
    }
  }

  static Future<void> clearSudokuSave() async {
    await StorageService.remove(_keySudokuSave);
  }

  // --- SLIDE PUZZLE SAVE & RESUME ---
  static Future<void> savePuzzleProgress({
    required List<int> board,
    required int size,
    required int moves,
    required int mistakes,
    required int secondsElapsed,
  }) async {
    final data = {
      'board': board,
      'size': size,
      'moves': moves,
      'mistakes': mistakes,
      'secondsElapsed': secondsElapsed,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await StorageService.setString(_keyPuzzleSave, jsonEncode(data));
  }

  static Map<String, dynamic>? getSavedPuzzle() {
    final raw = StorageService.getString(_keyPuzzleSave);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading saved puzzle: $e');
      return null;
    }
  }

  static Future<void> clearPuzzleSave() async {
    await StorageService.remove(_keyPuzzleSave);
  }

  // --- RUBIK SAVE & RESUME ---
  static Future<void> saveRubikProgress({
    required List<List<int>> faceColors,
    required int secondsElapsed,
    required int movesCount,
    required int mistakes,
  }) async {
    final data = {
      'faceColors': faceColors,
      'secondsElapsed': secondsElapsed,
      'movesCount': movesCount,
      'mistakes': mistakes,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await StorageService.setString(_keyRubikSave, jsonEncode(data));
  }

  static Map<String, dynamic>? getSavedRubik() {
    final raw = StorageService.getString(_keyRubikSave);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading saved rubik: $e');
      return null;
    }
  }

  static Future<void> clearRubikSave() async {
    await StorageService.remove(_keyRubikSave);
  }

  // --- CARO SAVE & RESUME ---
  static Future<void> saveCaroProgress({
    required List<List<int>> board,
    required String difficulty,
    required int movesCount,
    required int mistakes,
    required int totalSeconds,
    required int quantumSwapCharges,
    required int empFreezeCharges,
  }) async {
    final data = {
      'board': board,
      'difficulty': difficulty,
      'movesCount': movesCount,
      'mistakes': mistakes,
      'totalSeconds': totalSeconds,
      'quantumSwapCharges': quantumSwapCharges,
      'empFreezeCharges': empFreezeCharges,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await StorageService.setString(_keyCaroSave, jsonEncode(data));
  }

  static Map<String, dynamic>? getSavedCaro() {
    final raw = StorageService.getString(_keyCaroSave);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading saved caro: $e');
      return null;
    }
  }

  static Future<void> clearCaroSave() async {
    await StorageService.remove(_keyCaroSave);
  }
}
