import 'dart:math';

// Lớp biểu diễn tọa độ một nước đi trên bàn cờ Caro
class CaroMove {
  final int r; // Chỉ số hàng (row)
  final int c; // Chỉ số cột (column)
  const CaroMove(this.r, this.c);
}

// Bộ não trí tuệ nhân tạo (AI Engine) cho game Cờ Caro lượng tử
class CaroAiEngine {
  static const int empty = 0;    // Ô trống chưa đánh
  static const int playerX = 1;  // Người chơi cầm quân X
  static const int playerO = 2;  // Máy AI cầm quân O
  static const int frozen = -1;  // Ô bị đóng băng bởi kỹ năng EMP Freeze

  // Bảng trọng số đánh giá thế trận (Heuristic Evaluation Scores)
  static const int winScore = 1000000;    // 5 quân liên tiếp: Thắng tuyệt đối
  static const int fourScore = 50000;     // 4 quân mở (hoặc 4 chặn 1 đầu): Cực kỳ nguy hiểm
  static const int openThreeScore = 5000; // 3 quân mở 2 đầu: Thế cờ công phá mạnh
  static const int threeScore = 800;      // 3 quân bị chặn 1 đầu
  static const int openTwoScore = 200;    // 2 quân mở 2 đầu: Bắt đầu tạo thế cờ

  // Kiểm tra điều kiện thắng: 5 quân cùng loại liên tiếp theo 4 hướng
  static bool checkWin(List<List<int>> board, int size, int r, int c, int player) {
    const directions = [
      [0, 1],  // Hướng ngang (Horizontal)
      [1, 0],  // Hướng dọc (Vertical)
      [1, 1],  // Hướng chéo chính (Diagonal \)
      [1, -1], // Hướng chéo phụ (Diagonal /)
    ];

    for (final dir in directions) {
      int count = 1;
      // Đếm tiến về phía trước theo hướng dir
      int nr = r + dir[0];
      int nc = c + dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr += dir[0];
        nc += dir[1];
      }
      // Đếm lùi về phía sau theo hướng ngược lại
      nr = r - dir[0];
      nc = c - dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr -= dir[0];
        nc -= dir[1];
      }

      // Đạt từ 5 quân liên tiếp trở lên là chiến thắng
      if (count >= 5) return true;
    }
    return false;
  }

  // Thuật toán tìm nước đi tối ưu cho AI dựa trên cấp độ khó
  static CaroMove findBestMove({
    required List<List<int>> board,
    required int size,
    required String difficulty,
  }) {
    final candidateMoves = <CaroMove>[];

    // Thu thập các ô trống nằm xung quanh các quân cờ đã đánh (bán kính 2 ô)
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == empty) {
          if (_hasNeighbor(board, size, r, c)) {
            candidateMoves.add(CaroMove(r, c));
          }
        }
      }
    }

    // Nếu bàn cờ hoàn toàn trống, AI chọn đánh ngay chính giữa tâm bàn cờ
    if (candidateMoves.isEmpty) {
      return CaroMove(size ~/ 2, size ~/ 2);
    }

    // Cấp độ Dễ (Easy): 40% đánh chuẩn xác, 60% chọn ngẫu nhiên để người chơi dễ thắng
    if (difficulty == 'Easy') {
      final rand = Random();
      if (rand.nextDouble() > 0.4) {
        return candidateMoves[rand.nextInt(candidateMoves.length)];
      }
    }

    // Đánh giá thế trận nâng cao theo giải thuật Heuristic (Công & Thủ)
    CaroMove bestMove = candidateMoves[0];
    int maxScore = -99999999;

    for (final move in candidateMoves) {
      // 1. Kiểm tra xem nếu AI đánh vào ô này thì có THẮNG NGAY LẬP TỨC không
      board[move.r][move.c] = playerO;
      if (checkWin(board, size, move.r, move.c, playerO)) {
        board[move.r][move.c] = empty; // Hoàn tác thử nghiệm
        return move;                   // Đánh ngay để kết thúc ván thắng
      }
      board[move.r][move.c] = empty;   // Hoàn tác thử nghiệm

      // 2. Kiểm tra xem nếu Đối thủ đánh vào ô này lượt sau có Thắng không -> BẮT BUỘC PHẢI CHẶN NGAY
      board[move.r][move.c] = playerX;
      if (checkWin(board, size, move.r, move.c, playerX)) {
        board[move.r][move.c] = empty; // Hoàn tác thử nghiệm
        return move;                   // Chặn ngay lập tức đòn thắng của người chơi
      }
      board[move.r][move.c] = empty;   // Hoàn tác thử nghiệm

      // 3. Tính điểm lượng giá thế trận (Tổng hòa giữa Tấn Công O và Phòng Thủ X)
      int scoreO = _evaluatePosition(board, size, move.r, move.c, playerO);
      int scoreX = _evaluatePosition(board, size, move.r, move.c, playerX);

      // Cấp độ Khó (Grandmaster): Tăng trọng số phòng thủ và phản công đa hướng
      int totalScore = (scoreO * 1.2).toInt() + scoreX;
      if (difficulty == 'Grandmaster') {
        totalScore = (scoreO * 1.4).toInt() + (scoreX * 1.3).toInt();
      }

      // Lưu lại nước đi có tổng điểm lợi thế cao nhất
      if (totalScore > maxScore) {
        maxScore = totalScore;
        bestMove = move;
      }
    }

    return bestMove;
  }

  // Hàm kiểm tra ô (r, c) có quân cờ lân cận trong phạm vi 2 ô hay không
  static bool _hasNeighbor(List<List<int>> board, int size, int r, int c) {
    for (int dr = -2; dr <= 2; dr++) {
      for (int dc = -2; dc <= 2; dc++) {
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          if (board[nr][nc] == playerX || board[nr][nc] == playerO) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Hàm lượng giá thế trận cho 1 người chơi tại ô (r, c) theo 4 hướng
  static int _evaluatePosition(List<List<int>> board, int size, int r, int c, int player) {
    board[r][c] = player; // Giả lập đặt quân cờ
    int score = 0;

    const directions = [
      [0, 1],  // Ngang
      [1, 0],  // Dọc
      [1, 1],  // Chéo chính \
      [1, -1], // Chéo phụ /
    ];

    for (final dir in directions) {
      int count = 1;
      int openEnds = 0; // Đếm số đầu mở (chưa bị chặn bởi mép bàn cờ hoặc quân đối thủ)

      // Đếm tiến về phía trước
      int nr = r + dir[0];
      int nc = c + dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr += dir[0];
        nc += dir[1];
      }
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == empty) {
        openEnds++;
      }

      // Đếm lùi về phía sau
      nr = r - dir[0];
      nc = c - dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr -= dir[0];
        nc -= dir[1];
      }
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == empty) {
        openEnds++;
      }

      // Cộng điểm dựa trên cấu hình chuỗi quân cờ tạo được
      if (count >= 5) {
        score += winScore;          // 5 quân: Thắng tuyệt đối
      } else if (count == 4 && openEnds >= 1) {
        score += fourScore;         // 4 quân mở đầu: Cực kỳ nguy hiểm
      } else if (count == 3 && openEnds == 2) {
        score += openThreeScore;    // 3 quân mở cả 2 đầu: Thế cờ công phá mạnh
      } else if (count == 3 && openEnds == 1) {
        score += threeScore;        // 3 quân chặn 1 đầu
      } else if (count == 2 && openEnds == 2) {
        score += openTwoScore;      // 2 quân mở 2 đầu
      }
    }

    board[r][c] = empty; // Hoàn trả ô cờ về trạng thái ban đầu
    return score;
  }
}
