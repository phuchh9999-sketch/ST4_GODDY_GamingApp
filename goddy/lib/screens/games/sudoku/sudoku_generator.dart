import 'dart:math';

// Cấu trúc dữ liệu chứa bảng câu đố Sudoku và đáp án giải hoàn chỉnh
class SudokuBoardData {
  final List<List<int>> puzzle;    // Ma trận câu đố (chứa các ô 0 là ô trống cần điền)
  final List<List<int>> solution;  // Ma trận đáp án chuẩn xác đầy đủ từ 1 đến 9

  SudokuBoardData({required this.puzzle, required this.solution});
}

// Bộ tạo đề Sudoku ngẫu nhiên theo cấp độ khó và tính toán đáp án bằng Backtracking
class SudokuGenerator {
  static const int size = 9; // Kích thước chuẩn của bảng Sudoku: 9x9

  // Sinh đề câu đố Sudoku mới dựa theo độ khó (Easy, Medium, Hard, Nightmare)
  static SudokuBoardData generate(String difficulty, [int? seed]) {
    final rand = seed != null ? Random(seed) : Random();
    
    // 1. Tạo một ma trận kết quả 9x9 hợp lệ hoàn chỉnh
    final solution = List.generate(size, (_) => List.filled(size, 0));
    _fillDiagonalBlocks(solution, rand); // Điền các khối 3x3 độc lập trên đường chéo
    _solveSudoku(solution, rand);        // Sử dụng thuật toán quay lui (Backtracking) để điền kín bảng

    // 2. Sao chép ma trận đáp án và đục lỗ (xóa bớt số) tùy theo độ khó
    final puzzle = List.generate(size, (r) => List<int>.from(solution[r]));

    int cluesToRemove; // Số lượng số cần ẩn đi
    switch (difficulty) {
      case 'Easy':
        cluesToRemove = 38; // Còn lại 43 gợi ý
        break;
      case 'Hard':
        cluesToRemove = 54; // Còn lại 27 gợi ý
        break;
      case 'Nightmare':
        cluesToRemove = 60; // Còn lại 21 gợi ý
        break;
      case 'Medium':
      default:
        cluesToRemove = 48; // Còn lại 33 gợi ý
        break;
    }

    int removed = 0;
    while (removed < cluesToRemove) {
      final r = rand.nextInt(size);
      final c = rand.nextInt(size);
      if (puzzle[r][c] != 0) {
        puzzle[r][c] = 0; // Đặt thành 0 tương đương với ô trống
        removed++;
      }
    }

    return SudokuBoardData(puzzle: puzzle, solution: solution);
  }

  // Điền ngẫu nhiên 3 khối hộp 3x3 nằm trên đường chéo chính (không bao giờ xung đột nhau)
  static void _fillDiagonalBlocks(List<List<int>> board, Random rand) {
    for (int i = 0; i < size; i += 3) {
      _fillBox(board, i, i, rand);
    }
  }

  // Điền ngẫu nhiên các số từ 1 đến 9 vào một khối 3x3
  static void _fillBox(List<List<int>> board, int row, int col, Random rand) {
    final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(rand);
    int idx = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        board[row + r][col + c] = numbers[idx++];
      }
    }
  }

  // Kiểm tra số num có hợp lệ tại vị trí (r, c) không (không trùng trong hàng, cột, hộp 3x3)
  static bool _isValid(List<List<int>> board, int r, int c, int num) {
    // 1. Kiểm tra hàng ngang và cột dọc
    for (int i = 0; i < size; i++) {
      if (board[r][i] == num) return false;
      if (board[i][c] == num) return false;
    }
    // 2. Kiểm tra trong khối hộp 3x3 tương ứng
    final startRow = (r ~/ 3) * 3;
    final startCol = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[startRow + i][startCol + j] == num) return false;
      }
    }
    return true;
  }

  // Thuật toán đệ quy quay lui (Backtracking) để tìm đáp án hợp lệ cho toàn bộ ma trận 9x9
  static bool _solveSudoku(List<List<int>> board, [Random? rand]) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == 0) {
          final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
          if (rand != null) {
            numbers.shuffle(rand);
          } else {
            numbers.shuffle();
          }
          for (final num in numbers) {
            if (_isValid(board, r, c, num)) {
              board[r][c] = num;
              // Gọi đệ quy giải tiếp các ô còn lại
              if (_solveSudoku(board, rand)) return true;
              // Nếu không tìm được lời giải, quay lui đặt lại ô bằng 0
              board[r][c] = 0;
            }
          }
          return false; // Thử hết 1-9 mà không ô nào thỏa mãn
        }
      }
    }
    return true; // Tất cả các ô đã được điền hợp lệ
  }
}
