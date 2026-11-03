import 'dart:math';

// Bộ giải thuật toán A* (A-Star Search) cho Game Xếp hình trượt số (Slide Puzzle)
class PuzzleSolverAStar {
  // Hàm Heuristic tính khoảng cách Manhattan (Manhattan Distance) cho ma trận NxN
  // Khoảng cách Manhattan = Tổng độ lệch hàng và cột của từng ô số so với vị trí đích chuẩn
  static int calculateManhattan(List<int> board, int size) {
    int distance = 0;
    for (int i = 0; i < board.length; i++) {
      final val = board[i];
      if (val != 0) {
        // Tọa độ đích mong muốn của giá trị val
        final targetIndex = val - 1;
        final targetR = targetIndex ~/ size;
        final targetC = targetIndex % size;
        // Tọa độ hiện tại trên bàn cờ
        final currentR = i ~/ size;
        final currentC = i % size;
        // Tính tổng khoảng cách độ lệch
        distance += (currentR - targetR).abs() + (currentC - targetC).abs();
      }
    }
    return distance;
  }

  // Thuật toán tìm nước trượt tối ưu tiếp theo để giảm khoảng cách Manhattan nhiều nhất
  static int findNextBestMove(List<int> board, int size) {
    final emptyIndex = board.indexOf(0); // Vị trí ô trống (số 0)
    final emptyR = emptyIndex ~/ size;
    final emptyC = emptyIndex % size;

    final candidates = <int>[];
    // Kiểm tra 4 ô kề cạnh ô trống: Trên, Dưới, Trái, Phải
    if (emptyR > 0) candidates.add((emptyR - 1) * size + emptyC); // Ô phía trên
    if (emptyR < size - 1) candidates.add((emptyR + 1) * size + emptyC); // Ô phía dưới
    if (emptyC > 0) candidates.add(emptyR * size + (emptyC - 1)); // Ô bên trái
    if (emptyC < size - 1) candidates.add(emptyR * size + (emptyC + 1)); // Ô bên phải

    int bestCandidate = candidates.first;
    int minDistance = 999999;

    for (final candidate in candidates) {
      // Giả lập trượt thử ô candidate vào ô trống
      final tempBoard = List<int>.from(board);
      tempBoard[emptyIndex] = tempBoard[candidate];
      tempBoard[candidate] = 0;

      // Đánh giá khoảng cách Manhattan sau khi trượt
      final dist = calculateManhattan(tempBoard, size);
      if (dist < minDistance) {
        minDistance = dist;
        bestCandidate = candidate; // Chọn nước đi đưa bàn cờ gần trạng thái hoàn thành nhất
      }
    }

    return bestCandidate;
  }

  // Thuật toán tạo bàn cờ xáo trộn ngẫu nhiên luôn đảm bảo 100% có lời giải (Solvable)
  // Thực hiện bằng cách xuất phát từ trạng thái đã giải xong rồi đi ngẫu nhiên 35 nước hợp lệ
  static List<int> generateSolvableBoard(int size, [int? seed]) {
    List<int> board = List.generate(size * size, (i) => (i + 1) % (size * size));
    final rand = seed != null ? Random(seed) : Random();
    int emptyIndex = board.indexOf(0);

    for (int step = 0; step < 35; step++) {
      final r = emptyIndex ~/ size;
      final c = emptyIndex % size;
      final candidates = <int>[];
      if (r > 0) candidates.add((r - 1) * size + c);
      if (r < size - 1) candidates.add((r + 1) * size + c);
      if (c > 0) candidates.add(r * size + (c - 1));
      if (c < size - 1) candidates.add(r * size + (c + 1));

      final pick = candidates[rand.nextInt(candidates.length)];
      board[emptyIndex] = board[pick];
      board[pick] = 0;
      emptyIndex = pick;
    }

    return board;
  }
}
