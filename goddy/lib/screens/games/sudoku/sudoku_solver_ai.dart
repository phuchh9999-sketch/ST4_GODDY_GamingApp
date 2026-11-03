// Cấu trúc dữ liệu chứa gợi ý nước đi thông minh cho Sudoku
class SudokuHint {
  final int row;                // Vị trí hàng (0-8)
  final int col;                // Vị trí cột (0-8)
  final int number;             // Con số gợi ý điền vào (1-9)
  final String logicReasonVi;   // Lời giải thích logic suy luận bằng tiếng Việt

  SudokuHint({
    required this.row,
    required this.col,
    required this.number,
    required this.logicReasonVi,
  });
}

// Bộ não AI suy luận logic giải đố Sudoku Hologram
class SudokuSolverAi {
  // Tìm gợi ý logic tiếp theo cho người chơi
  static SudokuHint? findNextLogicHint(List<List<int>> currentBoard, List<List<int>> solution) {
    // 1. Kỹ thuật Naked Single (Số duy nhất hợp lệ): Ô chỉ còn duy nhất 1 số có thể điền
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (currentBoard[r][c] == 0) {
          final candidates = _getCandidates(currentBoard, r, c);
          if (candidates.length == 1) {
            final num = candidates.first;
            return SudokuHint(
              row: r,
              col: c,
              number: num,
              logicReasonVi: 'Tại ô [Hàng ${r + 1}, Cột ${c + 1}]: Các số khác đã xuất hiện trong cùng hàng, cột và khối 3x3. Do đó chỉ có duy nhất số $num là hợp lệ!',
            );
          }
        }
      }
    }

    // 2. Nếu không có ô đơn lẻ, sử dụng phương pháp đối chiếu ma trận chuẩn để giải thích
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (currentBoard[r][c] == 0) {
          final solNum = solution[r][c];
          return SudokuHint(
            row: r,
            col: c,
            number: solNum,
            logicReasonVi: 'Gợi ý AI nâng cao: Tại ô [Hàng ${r + 1}, Cột ${c + 1}], số chính xác là $solNum theo cấu trúc ma trận chuẩn.',
          );
        }
      }
    }
    return null;
  }

  // Hàm loại trừ và tìm tập hợp các số hợp lệ (1-9) có thể điền vào ô (r, c)
  static Set<int> _getCandidates(List<List<int>> board, int r, int c) {
    final possible = {1, 2, 3, 4, 5, 6, 7, 8, 9};

    // Loại bỏ các số đã có trong cùng hàng r và cùng cột c
    for (int i = 0; i < 9; i++) {
      possible.remove(board[r][i]);
      possible.remove(board[i][c]);
    }

    // Loại bỏ các số đã có trong khối vuông 3x3 chứa ô (r, c)
    final boxR = (r ~/ 3) * 3;
    final boxC = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        possible.remove(board[boxR + i][boxC + j]);
      }
    }

    return possible;
  }
}
