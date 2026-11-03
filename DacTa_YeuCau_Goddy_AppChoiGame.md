# TÀI LIỆU ĐẶC TẢ YÊU CẦU KỸ THUẬT VÀ THIẾT KẾ PHẦN MỀM (SRS)
## ĐỒ ÁN CUỐI KỲ: CỔNG GAME TRÍ TUỆ ĐỐI KHÁNG ĐA NỀN TẢNG "GODDY GAMING HUB"
---

* **Môn học**: Lập trình thiết bị di động (Mobile Application Development)
* **Sinh viên thực hiện**: Huỳnh Nguyễn Vĩnh Phúc
* **Mã số sinh viên (MSSV)**: 2380614923
* **Lớp học phần**: Lập trình thiết bị di động - Tuần 7 (Final Project)
* **Mobile Frontend**: Flutter SDK 3.x (Dart Language)
* **Backend WebAPI**: ASP.NET Core Web API (.NET 9) - `Goddy_Game_WebAPI`
* **Cơ sở dữ liệu**: Entity Framework Core (In-Memory Database / JSON State Storage)
* **Công cụ kết nối mạng**: Conveyor by Keyoti (Free), Microsoft Dev Tunnels, Ngrok
* **Sản phẩm bàn giao**: 
  - File cài đặt APK Release tối ưu AOT: `Goddy_Gaming_App_Release.apk` (~52.4MB)
  - Solution Visual Studio: `Goddy_Game_WebAPI.sln` (Port 5271 & Conveyor 45455)
  - Toàn bộ mã nguồn Frontend Flutter & Backend WebAPI

---

## MỤC LỤC
1. [GIỚI THIỆU TỔNG QUAN & TÍNH ĐỘT PHÁ CỦA ĐỀ TÀI](#1-giới-thiệu-tổng-quan--tính-đột-phá-của-đề-tài)
2. [KIẾN TRÚC HỆ THỐNG & CÔNG NGHỆ ÁP DỤNG](#2-kiến-trúc-hệ-thống--công-nghệ-áp-dụng)
3. [MÔ HÌNH THỰC THỂ DỮ LIỆU (DATA MODEL)](#3-mô-hình-thực-thể-dữ-liệu-data-model)
4. [ĐẶC TẢ YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS)](#4-đặc-tả-yêu-cầu-chức-năng-functional-requirements)
   - [FR-01: Hệ thống Quản trị Người dùng & Single Sign-On (SSO)](#fr-01-hệ-thống-quản-trị-người-dùng--single-sign-on-sso)
   - [FR-02: Bộ 4 Game Trí Tuệ Thế Hệ Mới & Điểm Khác Biệt Vượt Trội](#fr-02-bộ-4-game-trí-tuệ-thế-hệ-mới--điểm-khác-biệt-vượt-trội)
     - [Game 1: Rubik 3D AI Speedcube](#game-1-rubik-3d-ai-speedcube-giả-lập-3d-thực-tế)
     - [Game 2: Quantum Caro (Cờ Caro Chiến Thuật Lượng Tử)](#game-2-quantum-caro-chiến-thuật-đấu-ai-minimax)
     - [Game 3: Sudoku Hologram Spectrum & AI Deduction](#game-3-sudoku-hologram-spectrum--ai-deduction)
     - [Game 4: Gyro Tilt Slide Puzzle (Cảm biến gia tốc di động)](#game-4-gyro-tilt-slide-puzzle-xếp-hình-trượt-vật-lý)
   - [FR-03: Hệ thống Chọn Chế Độ Chơi (Mode Selector Modal)](#fr-03-hệ-thống-chọn-chế-độ-chơi-mode-selector-modal)
   - [FR-04: Hệ thống Thách Đấu Đối Kháng 1v1 & Cơ Chế Ready Check](#fr-04-hệ-thống-thách-đấu-đối-kháng-1v1--cơ-chế-ready-check)
   - [FR-05: Hệ thống Tính Điểm, Cấp Bậc Rank & Bảng Xếp Hạng Podium](#fr-05-hệ-thống-tính-điểm-cấp-bậc-rank--bảng-xếp-hạng-podium)
   - [FR-06: Sảnh Chat Cộng Đồng & Quick Stickers](#fr-06-sảnh-chat-cộng-đồng--quick-stickers)
5. [ĐẶC TẢ YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS)](#5-đặc-tả-yêu-cầu-phi-chức-năng-non-functional-requirements)
6. [ĐẶC TẢ HỆ THỐNG RESTful WEB API](#6-đặc-tả-hệ-thống-restful-web-api)
7. [MA TRẬN KIỂM THỬ CHẤT LƯỢNG (TEST MATRIX)](#7-ma-trận-kiểm-thử-chất-lượng-test-matrix)
8. [HƯỚNG DẪN TRIỂN KHAI & CÀI ĐẶT](#8-hướng-dẫn-triển-khai--cài-đặt)

---

## 1. GIỚI THIỆU TỔNG QUAN & TÍNH ĐỘT PHÁ CỦA ĐỀ TÀI

### 1.1. Bối cảnh & Mục tiêu
Các tựa game giải đố trí tuệ trên thị trường di động hiện nay (Rubik, Caro, Sudoku, Slide Puzzle) thường gặp các hạn chế lớn:
- Tồn tại dưới dạng các ứng dụng rời rạc, mỗi game bắt người chơi đăng ký một tài khoản riêng.
- Cơ chế chơi cũ kỹ: Rubik chỉ là ảnh 2D tĩnh hoặc thao tác vuốt khó kiểm soát; Caro người đi trước luôn thắng 90%; Sudoku chỉ báo đúng/sai mà không chỉ ra bản chất logic suy luận; Slide Puzzle chỉ dùng phím bấm thô sơ mà không khai thác phần cứng cảm biến điện thoại.
- Thiếu cơ chế kết nối đối kháng thời gian thực công bằng giữa 2 người chơi.

### 1.2. Giải pháp đột phá của "Goddy Gaming Hub"
**Goddy Gaming Hub** được xây dựng như một nền tảng Cổng Game Trí Tuệ All-in-One:
1. **Dùng chung 1 tài khoản (Single Sign-On - SSO)**: Một tài khoản duy nhất đồng bộ hồ sơ, rank, điểm kinh nghiệm, lịch sử trận đấu và thành tích cho tất cả các game.
2. **Cải tiến vượt bậc về công nghệ & luật chơi**:
   - Khối Rubik 3D 360 độ xoay đa chiều với bộ nút trực quan mô phỏng thao tác chuẩn WCA ngoài đời thực.
   - Caro tích hợp Thẻ Kỹ Năng Lượng Tử (*Quantum Swap*, *EMP Freeze*) đảo ngược tình thế và AI Minimax 3 cấp độ.
   - Sudoku tích hợp Quang Phổ Xung Đột (Holographic Conflict Spectrum) và AI giải thích bước giải (*Naked Single*).
   - Slide Puzzle kết nối trực tiếp cảm biến phần cứng gia tốc kế di động (`sensors_plus`) để trượt gạch bằng cách nghiêng điện thoại.
3. **Cơ chế Thách Đấu 1v1 công bằng tuyệt đối**: Kiểm tra sẵn sàng (Ready Check - cả 2 người cùng bấm Sẵn Sàng thì trận đấu mới bắt đầu, điểm số xuất phát chuẩn 0 điểm, cùng hạt giống đề bài).
4. **Kết nối đa mạng không giới hạn**: Tích hợp sẵn bộ giải pháp **Conveyor by Keyoti (Free)**, Dev Tunnels và Ngrok giúp kết nối WebAPI qua mạng 4G hoặc khác mạng Wi-Fi dễ dàng.

---

## 2. KIẾN TRÚC HỆ THỐNG & CÔNG NGHỆ ÁP DỤNG

### 2.1. Sơ đồ kiến trúc 3 tầng (3-Tier Architecture)

```
┌────────────────────────────────────────────────────────┐
│                   MOBILE FRONTEND                      │
│             (Flutter SDK 3.x - Dart)                   │
│  - Cyberpunk Futuristic Dark Theme                     │
│  - 3D Cube Canvas, Sensors Acceleration Physics        │
│  - State Management: Provider + Custom Stream Service  │
└──────────────────────────┬─────────────────────────────┘
                           │ HTTPS / HTTP REST API
                           │ (Json Web Token Authentication)
┌──────────────────────────▼─────────────────────────────┐
│          NETWORK TUNNELING / REVERSE PROXY             │
│  - Conveyor by Keyoti (Free Cloud URL: conveyor.cloud) │
│  - Microsoft Dev Tunnels / Ngrok Tunnel                │
│  - Hỗ trợ kết nối điện thoại qua 4G & Khác Wi-Fi       │
└──────────────────────────┬─────────────────────────────┘
                           │ Local Port Forwarding (:5271 / :45455)
┌──────────────────────────▼─────────────────────────────┐
│                   BACKEND WEBAPI                       │
│             (ASP.NET Core Web API - .NET 9)            │
│  - AuthController, LeaderboardController               │
│  - ChallengeController, ChatController                 │
│  - Swagger UI Documentation (/swagger)                 │
└──────────────────────────┬─────────────────────────────┘
                           │ Entity Framework Core
┌──────────────────────────▼─────────────────────────────┐
│                    DATABASE TIER                       │
│  - EF Core In-Memory Database (GoddyGameDbContext)     │
│  - Offline Cache: SharedPreferences Persistence        │
└────────────────────────────────────────────────────────┘
```

### 2.2. Danh mục công nghệ và thư viện
| Phân hệ | Công nghệ / Thư viện | Vai trò |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter SDK 3.38+ | Xây dựng giao diện di động native đa nền tảng |
| **Ngôn ngữ** | Dart 3.10+ | Lập trình logic, bất đồng bộ Async/Await |
| **Typography & UI** | `google_fonts` (Orbitron, Rajdhani) | Font chữ phong cách Cyberpunk Sci-Fi cao cấp |
| **State Management** | `provider: ^6.1.2` | Quản lý trạng thái Auth, Theme, Game State |
| **Networking** | `http: ^1.2.2` | Gọi RESTful API với fallback host tự động |
| **Phần cứng Di động** | `sensors_plus: ^6.1.1` | Đọc dữ liệu gia tốc kế (Accelerometer) nghiêng máy |
| **Lưu trữ Cục bộ** | `shared_preferences: ^2.5.3` | Lưu Token JWT, cấu hình Server Host, Profile Cache |
| **Backend Framework** | ASP.NET Core Web API (.NET 9) | Cung cấp REST API hiệu năng cao |
| **ORM Database** | Entity Framework Core In-Memory | Lưu trữ dữ liệu game thủ, điểm số, phòng đấu |
| **Mạng Tunnel** | Conveyor by Keyoti (Free Extension) | Expose cổng WebAPI ra Internet cho máy thật kết nối |

---

## 3. MÔ HÌNH THỰC THỂ DỮ LIỆU (DATA MODEL)

### 3.1. Thực thể Người dùng (`UserAccount`)
* `Id` (string, GUID): Định danh duy nhất người chơi.
* `Username` (string): Tên game thủ (Gamer Tag).
* `Email` (string): Địa chỉ email đăng nhập.
* `PasswordHash` (string): Mật khẩu băm an toàn.
* `Avatar` (string): Biểu tượng Avatar Cyberpunk đặc trưng (🤖, ⚡, 🥷, 👑, 👻, 👾, 🚀, 🎯...).
* `RankTitle` (string): Cấp bậc danh hiệu (Tân Thủ, Chiến Binh, Cao Thủ, Huyền Thoại Goddy).
* `TotalExp` (int): Điểm kinh nghiệm tích lũy từ các game.
* `Wins` (int): Tổng số trận thắng ở các chế độ đối kháng.
* `TotalMatches` (int): Tổng số trận đã tham gia.

### 3.2. Thực thể Kết quả Game (`GameResult`)
* `Id` (string, GUID): Mã lượt chơi.
* `UserId` (string): Người chơi thực hiện.
* `GameType` (string): Loại trò chơi (`rubik`, `caro`, `sudoku`, `slide_puzzle`).
* `Mode` (string): Chế độ (`solo`, `duel`).
* `Score` (int): Điểm số đạt được theo công thức chuẩn.
* `ElapsedSeconds` (int): Thời gian hoàn thành tính bằng giây.
* `Mistakes` (int): Số lỗi vi phạm trong ván đấu.
* `Difficulty` (string): Độ khó (`easy`, `medium`, `hard`, `nightmare`).
* `Seed` (string): Hạt giống đề bài (để kiểm tra công bằng trong đấu đối kháng).
* `CompletedAt` (DateTime): Thời điểm ghi nhận kỷ lục.

### 3.3. Thực thể Phòng Thách Đấu (`ChallengeRoom`)
* `RoomId` (string): Mã phòng thi đấu.
* `PinCode` (string): Mã PIN 4 chữ số để vào phòng nhanh.
* `GameType` (string): Loại game thách đấu.
* `Seed` (string): Hạt giống đề bài chung cho cả 2 người chơi.
* `HostUserId` (string): ID người tạo phòng (Chủ phòng).
* `GuestUserId` (string): ID người tham gia (Đối thủ).
* `HostReady` (bool): Trạng thái sẵn sàng của chủ phòng.
* `GuestReady` (bool): Trạng thái sẵn sàng của đối thủ.
* `HostScore` (int): Điểm số chủ phòng (khởi tạo bắt buộc = 0).
* `GuestScore` (int): Điểm số đối thủ (khởi tạo bắt buộc = 0).
* `Status` (enum): `waiting`, `ready`, `in_progress`, `completed`.

### 3.4. Thực thể Bạn bè & Trò chuyện (`FriendModel`, `ChatMessage`)
* `FriendModel`: `id`, `username`, `avatar`, `status`, `winRate`, `isOnline`.
* `ChatMessage`: `id`, `senderName`, `senderAvatar`, `message`, `timestamp`, `isQuickSticker`.

---

## 4. ĐẶC TẢ YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS)

### FR-01: Hệ thống Quản trị Người dùng & Single Sign-On (SSO)
* **FR-01.1 Đăng ký tài khoản**: Cho phép người dùng tạo tài khoản mới với Gamer Tag, Email, Mật khẩu và chọn Avatar Cyberpunk đặc sắc.
* **FR-01.2 Đăng nhập bảo mật**: Xác thực thông tin, cấp phát JWT Token và duy trì phiên đăng nhập (Session Persistence) thông qua `SharedPreferences`.
* **FR-01.3 Đăng nhập nhanh Demo 1-Chạm**: Nút *"Đăng Nhập Nhanh Tân Thủ"* trên màn hình Login giúp giảng viên hoặc người chấm bài bấm trực tiếp để truy cập ngay mà không cần tạo tài khoản thủ công.
* **FR-01.4 Cấu hình WebAPI Host linh hoạt**: Nút bấm icon 🌐 trên góc màn hình đăng nhập cho phép chuyển đổi máy chủ: Localhost (:5271), Máy ảo Android (10.0.2.2), Conveyor Cloud (conveyor.cloud), Conveyor LAN (:45455), Dev Tunnels hoặc Ngrok.
* **FR-01.5 Quản lý hồ sơ & Chuyển đổi tài khoản**: Màn hình Profile và Account Switcher Modal cho phép xem cấp bậc Rank, điểm EXP, huy hiệu danh hiệu và chuyển đổi nhanh giữa các tài khoản thử nghiệm.

---

### FR-02: Bộ 4 Game Trí Tuệ Thế Hệ Mới & Điểm Khác Biệt Vượt Trội

#### Game 1: Rubik 3D AI Speedcube (Giả lập 3D thực tế)
* **Trạng thái khởi tạo (Base State)**: Ban đầu khối Rubik 3x3 xuất hiện ở dạng thuần 1 màu ở cả 6 mặt (Trắng, Vàng, Xanh lá, Xanh dương, Đỏ, Cam) và có thể tương tác xoay góc nhìn 360 độ trong không gian 3 chiều.
* **Quy trình tương tác chuẩn WCA**:
  1. Nút **"1. XÁO TRỘN"**: Tự động xáo trộn logic ngẫu nhiên theo thuật toán Rubik quốc tế WCA (World Cube Association).
  2. Nút **"2. BẮT ĐẦU TÍNH GIỜ"**: Sau khi xáo trộn xong, người chơi bấm nút này để kích hoạt đồng hồ đếm giờ miligiây và bộ đếm số lượt xoay (Move Counter).
  3. **Bảng điều khiển xoay chuẩn ngoài đời**:
     - Hàng ngang trên: ⬅️ *Ngang Trái* | *Ngang Phải* ➡️
     - Hàng ngang dưới: ⬅️ *Ngang Trái* | *Ngang Phải* ➡️
     - Cột dọc trái: ⬆️ *Dọc Lên* | *Dọc Xuống* ⬇️
     - Cột dọc phải: ⬆️ *Dọc Lên* | *Dọc Xuống* ⬇️
     - Mặt trước: 🔄 *Xoay Thuận* | ↩️ *Xoay Nghịch*
  4. **Tự động nhận diện chiến thắng**: Tự động phát hiện khi người chơi xoay thành công 6 mặt trở về trạng thái thuần 1 màu ban đầu, ghi nhận thành tích thời gian và hiển thị bảng thông báo chiến thắng.
  5. **Nút "Bắt Đầu Lại"**: Luôn khả dụng cả khi đang chơi hoặc sau khi kết thúc để người chơi reset về trạng thái khối sạch ban đầu.
  6. **Bộ giải AI Step-by-Step**: Gợi ý thuật toán Layer-by-Layer khi người chơi bị bí đường đi.

#### Game 2: Quantum Caro (Chiến thuật đấu AI Minimax)
* **Bàn cờ ma trận 12x12**: Đấu với máy tính thông minh Minimax Alpha-Beta Heuristic với 3 cấp độ (Tập sự, Chiến thuật, Đại kiện tướng AI). AI tự động phát hiện và triệt tiêu các thế cờ 3-in-a-row và 4-in-a-row ngay lập tức.
* **Thẻ Kỹ Năng Lượng Tử Độc Quyền** *(Khắc phục hoàn toàn nhược điểm người đi trước thắng 90% của cờ Caro truyền thống)*:
  - *Quantum Swap (Hoán Đổi Lượng Tử)*: Cho phép hoán đổi vị trí giữa 1 quân cờ của mình và 1 quân cờ của đối thủ trong cự ly gần.
  - *EMP Freeze (Phong Ấn Ô Năng Lượng)*: Đóng băng 1 ô bàn cờ trong 2 lượt không cho đối phương đặt cờ vào vị trí hiểm hóc.
* **Turn Timer 15s**: Đồng hồ đếm ngược 15 giây mỗi lượt đi, quá thời gian bị trừ điểm và tính 1 lỗi phạm (Mistake).

#### Game 3: Sudoku Hologram Spectrum & AI Deduction
* **Ma trận 9x9 với 4 cấp độ**: Dễ, Vừa, Khó, Ác Mộng (Nightmare).
* **Quang phổ xung đột thời gian thực (Holographic Conflict Spectrum)**: Khi chạm vào bất kỳ ô nào, toàn bộ hàng ngang, cột dọc, khối 3x3 và các ô cùng giá trị sẽ phát sáng huỳnh quang Neon; báo đỏ tức thì khi phát hiện xung đột quy tắc Sudoku.
* **AI Logic Deduction Hint**: Giải thích chi tiết *VÌ SAO* ô đó phải điền số đó dựa trên kỹ thuật suy luận loại trừ duy nhất (*Naked Single*), giúp người chơi nâng cao tư duy giải đố thay vì chỉ cung cấp đáp án thô.
* **Hệ thống 3 Mạng (Lives) & Chuỗi Combo**: Điền đúng liên tiếp được nhân điểm thưởng cấp số nhân; điền sai 3 lần sẽ Game Over.

#### Game 4: Gyro Tilt Slide Puzzle (Xếp hình trượt vật lý)
* **Tận dụng cảm biến phần cứng điện thoại di động (`sensors_plus`)**: Người chơi có thể **NGHIÊNG ĐIỆN THOẠI THEO 4 HƯỚNG** (trên, dưới, trái, phải) để các khối gạch tự động trượt theo trọng lực quán tính thực tế của gia tốc kế.
* **Hỗ trợ D-Pad ảo**: Cho phép chơi mượt mà trên cả trình giả lập BlueStacks hoặc máy tính.
* **Thuật toán giải tối ưu A* (A-Star Manhattan Solver)**: Tự động tính khoảng cách Manhattan Distance và đề xuất bước trượt tiếp theo ngắn nhất đưa bàn cờ về trạng thái đích `[1, 2, 3, 4, 5, 6, 7, 8, Empty]`.

---

### FR-03: Hệ thống Chọn Chế Độ Chơi (Mode Selector Modal)
Mỗi khi người dùng chọn bất kỳ trò chơi nào trên Dashboard, một Modal tuyển chọn chế độ sẽ xuất hiện với 3 tùy chọn:
1. **Chế độ 1 Người Chơi (Solo Mode)**: Luyện tập cá nhân, tính giờ miligiây, đếm lỗi phạm và lưu kỷ lục vào bảng xếp hạng.
2. **Chế độ 2 Người Chơi (Thách Đấu 1v1 - Duel Mode)**: Mở phòng thi đấu đối kháng trực tiếp.
3. **Xem Bảng Xếp Hạng Game Này**: Xem danh sách Top kỷ lục riêng biệt cho tựa game đó.

---

### FR-04: Hệ thống Thách Đấu Đối Kháng 1v1 & Cơ Chế Ready Check
* **Mời bạn bè trực tuyến**: Chủ phòng có thể nhấn nút "Mời Bạn Bè" để chọn từ danh sách bạn bè đang online, hoặc chia sẻ mã PIN phòng đấu gồm 4 ký tự.
* **Quy tắc Kiểm Tra Sẵn Sàng (Ready Check) nghiêm ngặt**:
  - Cả 2 người chơi (Chủ phòng và Đối thủ) phải **CÙNG BẤM "SẴN SÀNG"** thì trận đấu mới được phép bắt đầu.
  - Nếu 1 trong 2 người CHƯA bấm sẵn sàng $\rightarrow$ Trận đấu chưa thể xảy ra (nút "BẮT ĐẦU TRẬN ĐẤU" bị khóa để bảo đảm tính công bằng).
* **Quy tắc Điểm Khởi Đầu = 0**:
  - Khi trận đấu bắt đầu, điểm số của cả hai người chơi bắt buộc xuất phát ở mức **0 điểm** (`HostScore = 0`, `GuestScore = 0`, `Timer = 00:00`).
* **Đề bài đồng nhất (Synced Seed)**: Cả 2 người chơi cùng giải một đề bài (cùng khối rubik xáo trộn, cùng ma trận số Sudoku, cùng thế gạch trượt).
* **Phân định thắng bại**: Người chơi nào giải xong với số giây ít hơn hoặc điểm số cao hơn sẽ giành chiến thắng, được cộng thêm 150 EXP vào Rank.

---

### FR-05: Hệ thống Tính Điểm, Cấp Bậc Rank & Bảng Xếp Hạng Podium
* **Công thức tính điểm Rank chuẩn**:
  $$\text{Score} = \max\Big(0, \ \big[\text{Base (1000 - 1500)} - (\text{Thời gian giây} \times 2) - (\text{Lỗi vi phạm} \times 60)\big] \times \text{Hệ số độ khó}\Big)$$
* **Hệ thống cấp bậc Rank Game Thủ**:
  - Đồng (Bronze): 0 - 499 EXP
  - Bạc (Silver): 500 - 1499 EXP
  - Vàng (Gold): 1500 - 2999 EXP
  - Bạch Kim (Platinum): 3000 - 4999 EXP
  - Kim Cương (Diamond): 5000 - 7999 EXP
  - Cao Thủ (Master): 8000 - 11999 EXP
  - Huyền Thoại Goddy (Grandmaster): $\ge$ 12000 EXP
* **Bảng Xếp Hạng (Leaderboard)**:
  - Bục vinh danh Podium Top 3 (Huy chương Vàng, Bạc, Đồng) với avatar phát sáng Cyberpunk.
  - 5 Tab phân loại: Bảng Tổng Hợp, Rubik 3D, Quantum Caro, Sudoku Master, Slide Puzzle.

---

### FR-06: Sảnh Chat Cộng Đồng & Quick Stickers
* **Sảnh Chat Thế Giới (Global Gaming Lounge)**: Cho phép cộng đồng game thủ giao lưu, thảo luận kinh nghiệm giải đố và rủ nhau solo.
* **Bộ Quick Stickers / Phản hồi nhanh**: Tích hợp các nút bấm gửi tin nhắn nhanh: *"Solo Caro không?"*, *"Quá đỉnh!"*, *"Cần gợi ý Rubik!"*, *"GG! Trận hay lắm!"*.

---

## 5. ĐẶC TẢ YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS)

| Tiêu chuẩn | Yêu cầu kỹ thuật | Kết quả kiểm chứng thực tế |
| :--- | :--- | :--- |
| **Hiệu năng (Performance)** | - Tốc độ phản hồi đạt 60 FPS.<br>- Thời gian khởi động app < 2 giây. | Bản build Release AOT tối ưu hóa bộ nhớ, không có hiện tượng giật lag khi xoay Rubik 3D hoặc nghiêng điện thoại. |
| **Dung lượng (Storage)** | - Gọn nhẹ, dễ dàng tải qua mạng di động. | File APK Release chỉ **~52.4MB** (giảm 70% so với bản debug 180MB nhờ Tree-shaking). |
| **Giao diện (UI/UX)** | - Chủ đề Cyberpunk Neon đồng nhất.<br>- Tuyệt đối không tràn màn hình (Overflow-Free). | 100% các màn hình sử dụng `SingleChildScrollView`, `Flexible`, `LayoutBuilder` co giãn thích ứng từ màn hình 4.7 inch đến tablet. |
| **Kết nối mạng (Network)** | - Chạy được qua 4G, Internet khác mạng Wi-Fi.<br>- Fallback host tự động khi mất kết nối. | Hỗ trợ Conveyor by Keyoti (conveyor.cloud), Dev Tunnels, Ngrok và tự động lưu host gần nhất. |
| **Độ tin cậy (Reliability)** | - Không văng ứng dụng (Zero Crash).<br>- Dữ liệu điểm số không bị mất khi thoát đột ngột. | Cache đồng bộ SharedPreferences và EF Core In-Memory. |

---

## 6. ĐẶC TẢ HỆ THỐNG RESTful WEB API

Backend WebAPI cung cấp các Endpoint chuẩn RESTful JSON:

```
BASE URL: 
- Localhost: http://localhost:5271/api/
- Android Emulator: http://10.0.2.2:5271/api/
- Conveyor Cloud (Free): https://<subdomain>.conveyor.cloud/api/
- Conveyor LAN: https://192.168.50.80:45455/api/
```

### Danh mục API Endpoints:

#### 1. Nhóm Xác thực & Người dùng (`/api/auth`, `/api/profile`)
* `POST /api/auth/register`: Đăng ký tài khoản game thủ mới.
  - Body: `{ "username": "string", "email": "string", "password": "string", "avatar": "string" }`
* `POST /api/auth/login`: Đăng nhập hệ thống, trả về JWT Token và thông tin User.
  - Body: `{ "email": "string", "password": "string" }`
* `POST /api/auth/guest`: Đăng nhập nhanh tài khoản khách/demo 1-chạm.
* `GET /api/profile`: Lấy thông tin hồ sơ, cấp rank, EXP và lịch sử của tài khoản hiện tại.
* `PUT /api/profile`: Cập nhật Avatar và tên hiển thị Gamer Tag.

#### 2. Nhóm Bảng Xếp Hạng & Điểm Số (`/api/leaderboard`)
* `GET /api/leaderboard?gameType={type}&limit=50`: Lấy danh sách bảng xếp hạng theo game (`all`, `rubik`, `caro`, `sudoku`, `slide_puzzle`).
* `POST /api/leaderboard/submit`: Gửi kết quả ván đấu lên máy chủ để tính điểm và thăng hạng.
  - Body: `{ "gameType": "string", "mode": "solo|duel", "score": 1250, "elapsedSeconds": 45, "mistakes": 0 }`

#### 3. Nhóm Thách Đấu Phòng Đấu (`/api/challenge`)
* `POST /api/challenge/create`: Tạo phòng thi đấu mới với loại game và mã PIN ngẫu nhiên.
* `POST /api/challenge/join`: Tham gia vào phòng thi đấu bằng mã PIN.
* `POST /api/challenge/ready`: Chuyển đổi trạng thái sẵn sàng (Ready Check) của người chơi.
* `POST /api/challenge/start`: Bắt đầu trận đấu khi và chỉ khi CẢ HAI người chơi đã sẵn sàng, đặt điểm số cả 2 về 0.
* `GET /api/challenge/friends`: Lấy danh sách bạn bè trực tuyến sẵn sàng thách đấu.

#### 4. Nhóm Trò Chuyện Cộng Đồng (`/api/chat`)
* `GET /api/chat/messages?limit=30`: Tải các tin nhắn mới nhất trong Sảnh Thế Giới.
* `POST /api/chat/send`: Gửi tin nhắn văn bản hoặc nhãn dán Quick Sticker.

---

## 7. MA TRẬN KIỂM THỬ CHẤT LƯỢNG (TEST MATRIX)

| Mã kiểm thử | Thành phần kiểm thử | Điều kiện & Kịch bản | Kết quả mong đợi | Trạng thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC-01** | Static Code Analysis | Chạy `flutter analyze` trên toàn bộ mã nguồn `goddy`. | 0 lỗi cú pháp, 0 cảnh báo (0 issues found). | **ĐẠT (PASS)** |
| **TC-02** | Unit Tests Logic | Chạy bộ kiểm thử tự động `flutter test` (8 ca kiểm thử). | 8/8 tests passed (Kiểm tra Rubik, Caro AI, Sudoku, A* Solver, Ready Check). | **ĐẠT (PASS)** |
| **TC-03** | Rubik 3D Base State | Mở game Rubik 3D lần đầu tiên. | Khối Rubik 3x3 hiển thị thuần 1 màu ở cả 6 mặt, xoay góc nhìn 360 độ mượt mà. | **ĐẠT (PASS)** |
| **TC-04** | Rubik 3D Shuffle & Start | Nhấn "1. Xáo Trộn" rồi nhấn "2. Bắt Đầu Tính Giờ". | Khối rubik bị xáo trộn logic; đồng hồ tính giờ miligiây và bộ đếm lượt xoay bắt đầu chạy. | **ĐẠT (PASS)** |
| **TC-05** | Rubik Win Detection | Xoay các hàng/cột đưa khối Rubik về lại dạng 6 mặt 1 màu. | Hệ thống tự động nhận diện chiến thắng, dừng đồng hồ và hiện bảng vinh danh. | **ĐẠT (PASS)** |
| **TC-06** | Ready Check Lock | 1 người bấm "SẴN SÀNG", người kia chưa bấm. | Nút "BẮT ĐẦU TRẬN ĐẤU" vẫn bị khóa xám, trận đấu chưa thể diễn ra. | **ĐẠT (PASS)** |
| **TC-07** | Ready Check Unlock & Start 0 | Cả 2 người chơi cùng bấm "SẴN SÀNG". | Nút bắt đầu mở khóa; khi bấm bắt đầu điểm của cả 2 xuất phát ở mức 0 điểm. | **ĐẠT (PASS)** |
| **TC-08** | Gyro Hardware Tilt | Nghiêng điện thoại sang trái/phải/lên/xuống trên máy thật. | Cảm biến `sensors_plus` nhận diện góc nghiêng và làm khối gạch trượt tự động. | **ĐẠT (PASS)** |
| **TC-09** | Sudoku Hologram Spectrum | Nhấp vào 1 ô số trên bàn cờ Sudoku. | Toàn bộ hàng, cột, khối 3x3 và số trùng phát sáng Neon; báo đỏ khi có xung đột. | **ĐẠT (PASS)** |
| **TC-10** | Caro Minimax AI & Skill | Đấu Caro với AI Kiện Tướng và kích hoạt thẻ *Quantum Swap*. | AI tính toán chặn nước đi; thẻ kỹ năng hoán đổi vị trí quân cờ thành công. | **ĐẠT (PASS)** |
| **TC-11** | Cross-Network WebAPI | Kết nối app qua mạng di động 4G bằng link Conveyor Cloud. | Đăng nhập, gửi điểm và xem bảng xếp hạng thành công không cần chung Wi-Fi. | **ĐẠT (PASS)** |

---

## 8. HƯỚNG DẪN TRIỂN KHAI & CÀI ĐẶT

### 8.1. Cài đặt App di động trên Điện thoại Android
1. Chép file **`Goddy_Gaming_App_Release.apk`** (nằm tại thư mục gốc `LTDD_Tuan7`) vào điện thoại Android.
2. Mở file APK trên điện thoại và chọn **Cài đặt** *(Bật "Cho phép cài đặt ứng dụng từ nguồn không xác định" nếu máy có thông báo)*.
3. Mở ứng dụng **Goddy Gaming Hub** từ màn hình chính điện thoại.
4. Bấm **"Đăng Nhập Nhanh Tân Thủ"** để vào thẳng trải nghiệm ngay lập tức.

### 8.2. Khởi chạy Backend WebAPI với Conveyor by Keyoti (Visual Studio)
1. Nhấp đúp chuột vào file **`Goddy_Game_WebAPI.sln`** để mở Visual Studio 2022.
2. Nhấn phím **F5 (hoặc nút Run ▶️ `https`)**:
   - Backend WebAPI sẽ khởi động và lắng nghe kết nối.
   - Extension **Conveyor by Keyoti** tự động hiển thị cửa sổ cổng mạng.
3. Bấm nút **`🌐 Access Over Internet`** trong cửa sổ Conveyor để lấy đường link miễn phí `https://xxxx.conveyor.cloud`.
4. Trên ứng dụng điện thoại, bấm icon **🌐** ở màn hình Đăng Nhập, dán đường link vào và nhấn **"Lưu & Kết Nối"**.

---
*Tài liệu được xây dựng hoàn chỉnh phục vụ báo cáo và nghiệm thu đồ án môn học Lập trình thiết bị di động.*
