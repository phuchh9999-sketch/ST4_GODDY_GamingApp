# GODDY GAMING HUB - CỔNG GAME TRÍ TUỆ ĐỐI KHÁNG ĐA NỀN TẢNG
> **Đồ án cuối kỳ môn Lập trình thiết bị di động (Mobile Application Development)**  
> **Sinh viên thực hiện**: Huỳnh Nguyễn Vĩnh Phúc - **MSSV**: 2380614923

---

## 1. Tải Về và Cài Đặt Ứng Dụng (Release APK)
* **[Tải file cài đặt: Goddy_Gaming_App_Release.apk (52.4 MB)](./Goddy_Gaming_App_Release.apk)**
* Bản build tối ưu Ahead-of-Time (AOT), không giật lag, hỗ trợ cài đặt trực tiếp trên tất cả thiết bị Android.
* Tài liệu đặc tả kỹ thuật phần mềm: **[DacTa_YeuCau_Goddy_AppChoiGame.md](./DacTa_YeuCau_Goddy_AppChoiGame.md)** | **[DacTa_YeuCau_Goddy_AppChoiGame.txt](./DacTa_YeuCau_Goddy_AppChoiGame.txt)**
* Báo cáo đồ án: **[BaoCao_Goddy_AppChoiGame.txt](./BaoCao_Goddy_AppChoiGame.txt)**

---

## 2. Điểm Đột Phá và Bộ 4 Game Trí Tuệ Thế Hệ Mới

### 2.1. Dùng Chung 1 Tài Khoản Duy Nhất (Single Sign-On - SSO)
* Đăng ký, đăng nhập bảo mật hoặc bấm **"Đăng Nhập Nhanh Tân Thủ" (1-Chạm Demo)**.
* Đồng bộ điểm số, cấp bậc Rank (Đồng -> Huyền Thoại Goddy), EXP, tỷ lệ thắng và lịch sử đấu trên toàn bộ 4 game.

### 2.2. Bộ 4 Game Đột Phá So Với Thị Trường
1. **Rubik 3D AI Speedcube**:
   * Khối Rubik 3x3 3D tương tác 360 độ chân thực.
   * Ban đầu ở trạng thái gốc (Base state) thuần 1 màu ở cả 6 mặt.
   * Nút **"1. Xáo Trộn"** ngẫu nhiên hóa vị trí theo chuẩn Rubik WCA.
   * Nút **"2. Bắt Đầu Tính Giờ"** kích hoạt đồng hồ miligiây và đếm lượt xoay.
   * Bảng nút xoay chuẩn thực tế: Ngang trên (Trái/Phải), Ngang dưới (Trái/Phải), Dọc trái (Lên/Xuống), Dọc phải (Lên/Xuống), Mặt trước (Thuận/Nghịch).
   * Tự động phát hiện chiến thắng khi 6 mặt đồng nhất màu và có nút **"Bắt Đầu Lại"** bất cứ lúc nào.
2. **Quantum Caro (Cờ Caro Lượng Tử Đấu AI Minimax)**:
   * Bàn cờ 12x12 đấu AI Heuristic Minimax 3 cấp độ.
   * Thẻ kỹ năng độc quyền: Quantum Swap (hoán đổi quân cờ) và EMP Freeze (đóng băng ô).
   * Đếm ngược suy nghĩ 15s mỗi lượt.
3. **Sudoku Hologram Spectrum và AI Deduction**:
   * 4 cấp độ tạo đề (Easy, Medium, Hard, Nightmare).
   * Quang phổ xung đột màu Neon thời gian thực.
   * AI giải thích bản chất suy luận loại trừ duy nhất (Naked Single).
4. **Gyro Tilt Slide Puzzle (Xếp hình trượt cảm biến gia tốc di động)**:
   * Khai thác trực tiếp cảm biến phần cứng gia tốc kế di động (sensors_plus): **nghiêng điện thoại để gạch tự trôi theo trọng lực**.
   * Hỗ trợ D-Pad ảo và thuật toán giải tối ưu A* Manhattan.

### 2.3. Hệ Thống Thách Đấu Đối Kháng 1v1 và Cơ Chế Ready Check
* Mời bạn bè trực tuyến từ danh sách bạn bè hoặc chia sẻ mã PIN phòng đấu.
* **Cơ chế Ready Check nghiêm ngặt**: Cả 2 người chơi cùng bấm **"SẴN SÀNG"** thì trận đấu mới bắt đầu.
* **Điểm khởi đầu = 0**: Điểm số của cả hai xuất phát từ 0 điểm và giải cùng một hạt giống đề bài (Seed).

---

## 3. Cấu Trúc Mã Nguồn Trong Kho Lưu Trữ

```
DACC_LTDD_GODDY/
|-- goddy/                          # Mã nguồn ứng dụng di động Flutter (Dart)
|   |-- lib/
|   |   |-- config/api_config.dart  # Cấu hình đa host WebAPI & Conveyor
|   |   |-- core/theme.dart         # Cyberpunk Futuristic Dark Theme
|   |   |-- models/                 # Models dữ liệu User, Challenge, Room...
|   |   |-- screens/                # Giao diện 4 Game, Auth, Leaderboard, Duel
|   |   `-- services/               # ApiClient, AuthService, ChallengeService...
|   |-- test/                       # 8/8 Unit tests kiểm thử tự động
|   `-- pubspec.yaml
|
|-- Goddy_Game_WebAPI/              # Mã nguồn Backend ASP.NET Core Web API (.NET 9)
|   |-- Controllers/                # Auth, Leaderboard, Challenge, Chat Controllers
|   |-- Models/                     # Entity Framework Data Models
|   |-- Data/                       # GoddyGameDbContext
|   |-- goddy.db                    # CSDL SQLite lưu trữ dữ liệu người dùng & điểm số
|   `-- Program.cs
|
|-- Goddy_Game_WebAPI.sln           # Solution mở trong Visual Studio 2022
|-- Goddy_Gaming_App_Release.apk    # File cài đặt APK Release tối ưu AOT (~52.4MB)
|-- DacTa_YeuCau_Goddy_AppChoiGame.md # Hồ sơ đặc tả yêu cầu kỹ thuật phần mềm (SRS)
|-- DacTa_YeuCau_Goddy_AppChoiGame.txt
`-- BaoCao_Goddy_AppChoiGame.txt    # Báo cáo tổng hợp đồ án
```

---

## 4. Hướng Dẫn Chạy Dự Án

### 4.1. Khởi chạy WebAPI với Conveyor by Keyoti (Visual Studio)
1. Mở file `Goddy_Game_WebAPI.sln` bằng **Visual Studio 2022**.
2. Nhấn nút **Run (F5)**. Cửa sổ extension **Conveyor by Keyoti** sẽ hiện lên.
3. Bấm **"Access Over Internet"** để lấy link miễn phí `https://xxxx.conveyor.cloud`.

### 4.2. Chạy Ứng Dụng Di Động
1. Cài đặt file `Goddy_Gaming_App_Release.apk` lên điện thoại Android hoặc BlueStacks.
2. Mở app, tại màn hình Đăng Nhập bấm nút cấu hình Host (icon DNS) ở góc trên để dán link Conveyor.
3. Bấm **"Đăng Nhập Nhanh Tân Thủ"** để vào trải nghiệm ngay lập tức.