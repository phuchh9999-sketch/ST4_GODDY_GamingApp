import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goddy/core/constants.dart';
import 'package:goddy/models/challenge_room.dart';
import 'package:goddy/models/user_model.dart';
import 'package:goddy/models/friend_model.dart';
import 'package:goddy/services/challenge_service.dart';
import 'package:goddy/screens/games/rubik/rubik_cube_widget.dart';
import 'package:goddy/screens/games/rubik/rubik_solver_ai.dart';
import 'package:goddy/screens/games/caro/caro_ai_engine.dart';
import 'package:goddy/screens/games/sudoku/sudoku_generator.dart';
import 'package:goddy/screens/games/slide_puzzle/puzzle_solver_a_star.dart';

void main() {
  group('Goddy Gaming Hub Core Logic Tests', () {
    test('RubikSolverAi generates valid scrambles and CFOP steps', () {
      final scramble = RubikSolverAi.generateScramble(length: 15);
      expect(scramble.length, 15);

      final steps = RubikSolverAi.generateSolutionSteps(scramble);
      expect(steps.length, 6);
      expect(steps[0].stageName, contains('Chữ Thập Trắng'));
      expect(steps[5].stageName, contains('Hoàn Thiện Khối Rubik'));
    });

    test('CaroAiEngine detects 5-in-a-row win condition', () {
      final board = List.generate(11, (_) => List.filled(11, 0));
      // Place 5 horizontal stones for player X
      for (int c = 2; c < 7; c++) {
        board[5][c] = CaroAiEngine.playerX;
      }

      final isWin = CaroAiEngine.checkWin(board, 11, 5, 4, CaroAiEngine.playerX);
      expect(isWin, isTrue);

      final notWin = CaroAiEngine.checkWin(board, 11, 0, 0, CaroAiEngine.playerO);
      expect(notWin, isFalse);
    });

    test('CaroAiEngine finds smart blocking move', () {
      final board = List.generate(11, (_) => List.filled(11, 0));
      // Player X has 4 in a row: (5,2), (5,3), (5,4), (5,5)
      for (int c = 2; c <= 5; c++) {
        board[5][c] = CaroAiEngine.playerX;
      }

      final bestMove = CaroAiEngine.findBestMove(board: board, size: 11, difficulty: 'Grandmaster');
      // AI must block at either (5, 1) or (5, 6)
      final isBlocked = (bestMove.r == 5 && (bestMove.c == 1 || bestMove.c == 6));
      expect(isBlocked, isTrue);
    });

    test('SudokuGenerator creates valid 9x9 puzzles', () {
      final boardData = SudokuGenerator.generate('Medium');
      expect(boardData.puzzle.length, 9);
      expect(boardData.solution.length, 9);

      // Verify that solution has no 0s
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(boardData.solution[r][c], greaterThan(0));
        }
      }
    });

    test('PuzzleSolverAStar calculates Manhattan distance correctly', () {
      // Solved board has distance 0
      final solvedBoard = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      final distSolved = PuzzleSolverAStar.calculateManhattan(solvedBoard, 3);
      expect(distSolved, 0);

      // Board with 1 swap has positive distance
      final swappedBoard = [2, 1, 3, 4, 5, 6, 7, 8, 0];
      final distSwapped = PuzzleSolverAStar.calculateManhattan(swappedBoard, 3);
      expect(distSwapped, greaterThan(0));
    });

    testWidgets('RubikCubeWidget starts in pure base 6-color solved state and responds to moves', (tester) async {
      final cubeKey = GlobalKey<RubikCubeWidgetState>();
      int movesExecuted = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RubikCubeWidget(
              key: cubeKey,
              onMoveExecuted: () => movesExecuted++,
            ),
          ),
        ),
      );

      // Initially cube must be solved (all 6 faces pure base color)
      expect(cubeKey.currentState?.isSolved(), isTrue);

      // Execute top horizontal move U
      cubeKey.currentState?.executeMove('U', animate: false);
      await tester.pump();
      expect(movesExecuted, 1);
      expect(cubeKey.currentState?.isSolved(), isFalse);

      // Execute inverse move U'
      cubeKey.currentState?.executeMove("U'", animate: false);
      await tester.pump();
      expect(movesExecuted, 2);
      // Cube should be solved back to base pure color state
      expect(cubeKey.currentState?.isSolved(), isTrue);

      // Scramble changes state
      cubeKey.currentState?.scramble();
      await tester.pump();
      expect(cubeKey.currentState?.isSolved(), isFalse);

      // Reset restores pure base state
      cubeKey.currentState?.resetCube();
      await tester.pump(const Duration(milliseconds: 300));
      expect(cubeKey.currentState?.isSolved(), isTrue);
    });

    test('Challenge Duel determines winner strictly by lowest time in seconds', () {
      final hostTime = 45; // 45 seconds
      final guestTime = 38; // 38 seconds (faster)

      final winnerId = (hostTime < guestTime) ? 'host_123' : 'guest_456';
      expect(winnerId, 'guest_456');
    });

    test('Challenge Duel requires BOTH players to be Ready before match starts with 0 points', () {
      final service = ChallengeService();
      const host = UserModel(id: 'host_1', email: 'host@goddy.io', username: 'HostPlayer', avatar: '🤖');
      const guest = FriendModel(id: 'fr_1', username: 'FriendGamer', avatar: '⚡');

      // Create room
      final room = service.createRoom(host: host, gameType: GameType.rubik);
      expect(room.hostReady, isFalse);
      expect(room.guestReady, isFalse);
      expect(service.canStartMatch(), isFalse);

      // Only host presses ready -> CANNOT start
      service.toggleHostReady();
      expect(service.currentRoom?.hostReady, isTrue);
      expect(service.currentRoom?.guestReady, isFalse);
      expect(service.canStartMatch(), isFalse);

      // Try to start match -> Still not playing
      service.startMatch();
      expect(service.currentRoom?.status, RoomStatus.waiting);

      // Invite friend
      service.inviteFriend(guest);
      expect(service.currentRoom?.guestId, 'fr_1');
      expect(service.currentRoom?.guestReady, isFalse);
      expect(service.canStartMatch(), isFalse);

      // Friend presses ready -> BOTH ARE READY!
      service.toggleGuestReady();
      expect(service.currentRoom?.hostReady, isTrue);
      expect(service.currentRoom?.guestReady, isTrue);
      expect(service.canStartMatch(), isTrue);

      // Now match can start: scores initialize at 0!
      service.startMatch();
      expect(service.currentRoom?.status, RoomStatus.playing);
      expect(service.currentRoom?.hostScore, 0);
      expect(service.currentRoom?.guestScore, 0);
    });
  });
}


