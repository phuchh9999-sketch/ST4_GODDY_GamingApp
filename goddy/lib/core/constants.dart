enum GameType {
  rubik,
  caro,
  sudoku,
  slidePuzzle,
}

extension GameTypeExtension on GameType {
  String get title {
    switch (this) {
      case GameType.rubik:
        return 'Rubik 3D Solver';
      case GameType.caro:
        return 'Quantum Caro';
      case GameType.sudoku:
        return 'Sudoku Hologram';
      case GameType.slidePuzzle:
        return 'Gyro Tilt Puzzle';
    }
  }

  String get subtitle {
    switch (this) {
      case GameType.rubik:
        return 'Khối Rubik 3D & AI Hướng Dẫn Giải';
      case GameType.caro:
        return 'Cờ Caro Đấu AI & Kỹ Năng Chiến Thuật';
      case GameType.sudoku:
        return 'Ma Trận Quang Học & Gợi Ý Logic';
      case GameType.slidePuzzle:
        return 'Xếp Hình Trượt Cảm Biến Nghiêng Máy';
    }
  }

  String get id {
    switch (this) {
      case GameType.rubik:
        return 'rubik';
      case GameType.caro:
        return 'caro';
      case GameType.sudoku:
        return 'sudoku';
      case GameType.slidePuzzle:
        return 'slide_puzzle';
    }
  }
}

enum RankTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
}

extension RankTierExtension on RankTier {
  String get nameVi {
    switch (this) {
      case RankTier.bronze:
        return 'Đồng';
      case RankTier.silver:
        return 'Bạc';
      case RankTier.gold:
        return 'Vàng';
      case RankTier.platinum:
        return 'Bạch Kim';
      case RankTier.diamond:
        return 'Kim Cương';
      case RankTier.master:
        return 'Cao Thủ';
      case RankTier.grandmaster:
        return 'Huyền Thoại Goddy';
    }
  }

  int get minExp {
    switch (this) {
      case RankTier.bronze:
        return 0;
      case RankTier.silver:
        return 500;
      case RankTier.gold:
        return 1500;
      case RankTier.platinum:
        return 3000;
      case RankTier.diamond:
        return 5500;
      case RankTier.master:
        return 9000;
      case RankTier.grandmaster:
        return 15000;
    }
  }

  static RankTier fromExp(int exp) {
    if (exp >= 15000) return RankTier.grandmaster;
    if (exp >= 9000) return RankTier.master;
    if (exp >= 5500) return RankTier.diamond;
    if (exp >= 3000) return RankTier.platinum;
    if (exp >= 1500) return RankTier.gold;
    if (exp >= 500) return RankTier.silver;
    return RankTier.bronze;
  }
}
