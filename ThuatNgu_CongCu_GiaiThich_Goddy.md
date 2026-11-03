# 📘 TỔNG HỢP TOÀN BỘ CÔNG CỤ, TỪ VIẾT TẮT, THUẬT TOÁN & KHÁI NIỆM KỸ THUẬT
## DỰ ÁN: GODDY GAMING HUB - CỔNG GAME TRÍ TUỆ & ĐỐI KHÁNG THỜI GIAN THỰC
**Môn học:** Lập trình thiết bị di động (Mobile Application Development)  
**Nhóm:** ST4 | **Nền tảng:** Flutter Mobile (Dart) + ASP.NET Core WebAPI (.NET 9) + CSDL SQLite

---

Tài liệu này được biên soạn chi tiết nhằm giúp thành viên nhóm nắm vững bản chất kỹ thuật, tự tin trả lời bất kỳ câu hỏi phản biện nào của Giảng viên và Hội đồng chấm đồ án. Mọi khái niệm đều được giải thích theo cấu trúc chuẩn:
1. **Nó là cái gì?** (Định nghĩa bản chất).
2. **Công dụng là gì?** (Tại sao phải dùng, ưu điểm vượt trội).
3. **Đã thực hiện cụ thể thế nào trong bài?** (Vị trí file code và chức năng tương ứng).

---

## MỤC LỤC
1. [Nhóm 1: Toán học, Đồ họa & Không gian 3D (Graphics & Math)](#1-nhóm-1-toán-học-đồ-họa--không-gian-3d)
2. [Nhóm 2: Thuật toán Trí tuệ Nhân tạo & Giải đố (AI & Solvers)](#2-nhóm-2-thuật-toán-trí-tuệ-nhân-tạo--giải-đố)
3. [Nhóm 3: Cảm biến Phần cứng Di động (Mobile Hardware & Sensors)](#3-nhóm-3-cảm-biến-phần-cứng-di-động)
4. [Nhóm 4: Mạng, Điện toán Đám mây & Đồng bộ Thời gian thực (Networking & Tunnel)](#4-nhóm-4-mạng-điện-toán-đám-mây--đồng-bộ-thời-gian-thực)
5. [Nhóm 5: Backend WebAPI & Cơ sở Dữ liệu (Backend & Database)](#5-nhóm-5-backend-webapi--cơ-sở-dữ-liệu)
6. [Nhóm 6: Công cụ Phát triển & Tối ưu Biên dịch (Mobile Framework & Build)](#6-nhóm-6-công-cụ-phát-triển--tối-ưu-biên-dịch)
7. [Bảng Tra Cứu Nhanh Tất Cả Các Từ Viết Tắt (Acronyms Quick Reference)](#7-bảng-tra-cứu-nhanh-tất-cả-các-từ-viết-tắt)

---

## 1. Nhóm 1: Toán học, Đồ họa & Không gian 3D

### 1.1. Isometric 3D Projection (Phép chiếu trục đo đẳng cự)
* **Nó là cái gì?**  
  Là một phương pháp biểu diễn đồ họa 3 chiều (3D) trên bề mặt phẳng 2 chiều (màn hình điện thoại). Trong phép chiếu này, cả 3 trục tọa độ không gian ($X, Y, Z$) đều có tỉ lệ biến dạng như nhau và tạo với nhau các góc bằng nhau là $120^\circ$.
* **Công dụng:**  
  Tạo cảm giác chiều sâu 3D chân thực, giúp mắt người nhìn thấy đồng thời 3 mặt của vật thể (Mặt trên - Up, Mặt trước - Front, Mặt bên phải - Right) mà **không cần nhúng các Game Engine 3D cồng kềnh** như Unity, Unreal hay OpenGL phức tạp, giúp ứng dụng siêu nhẹ và đạt tốc độ khung hình 60-120fps.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/rubik/rubik_cube_widget.dart`.
  - Sử dụng đối tượng `CustomPainter` của Flutter để tự vẽ ma trận các khối lập phương con (stickers). Áp dụng công thức biến đổi Affine lượng giác ($\cos 30^\circ, \sin 30^\circ$) để dựng khối Rubik 3x3 Isometric sắc nét, phủ màu Cyberpunk và viền phát sáng neon.

### 1.2. WCA Scramble (World Cube Association Scramble Logic)
* **Nó là cái gì?**  
  Là quy chuẩn xáo trộn của Hiệp hội Rubik Thế giới (WCA). Khối Rubik không được tô màu ngẫu nhiên một cách tùy tiện mà phải được xáo trộn từ trạng thái gốc bằng một chuỗi các phép quay hợp lệ ($R, L, U, D, F, B$ - Right, Left, Up, Down, Front, Back).
* **Công dụng:**  
  Đảm bảo khối Rubik luôn có nghiệm giải toán học khả thi, không bao giờ bị rơi vào "trạng thái bất khả thi" (như lệch 1 góc hay đảo 1 cạnh mà ngoài đời không thể xoay về được).
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/rubik/rubik_screen.dart`.
  - Nút **"1. Xáo Trộn"** tự động chạy thuật toán sinh ngẫu nhiên 20 bước xoay hợp lệ theo đúng cơ chế WCA trước khi mở đồng hồ tính giờ cho người chơi.

### 1.3. CFOP / Layer-by-Layer Rubik Solver
* **Nó là cái gì?**  
  CFOP là phương pháp giải Rubik tốc độ (Speedcubing) nổi tiếng nhất thế giới gồm 4 bước: **C**ross (Dấu cộng), **F**2L (Giải đồng thời 2 tầng đầu), **O**LL (Định hướng tầng cuối), **P**LL (Hoán vị tầng cuối). Bản rút gọn của nó là Layer-by-Layer (Giải từng tầng từ dưới lên trên).
* **Công dụng:**  
  Cung cấp bộ não Trí tuệ Nhân tạo hỗ trợ người chơi khi gặp bế tắc, đưa ra hướng dẫn bước đi tiếp theo thay vì người chơi phải bỏ cuộc.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/rubik/rubik_solver_ai.dart`.
  - Phân tích màu sắc của 6 mặt và tính toán chuỗi xoay tiếp theo, hiển thị nút "Gợi ý AI" ngay trên màn hình game.

---

## 2. Nhóm 2: Thuật toán Trí tuệ Nhân tạo & Giải đố

### 2.1. Minimax Algorithm & Alpha-Beta Pruning (Cực đại Cực tiểu & Cắt tỉa Alpha-Beta)
* **Nó là cái gì?**  
  - **Minimax:** Thuật toán đệ quy trong lý thuyết trò chơi đối kháng 2 người có tổng điểm bằng 0 (Zero-sum game). Máy tính giả định người chơi sẽ luôn chọn nước đi tốt nhất của họ (Minimizing player) và máy sẽ chọn nước đi mang lại lợi thế cao nhất cho máy (Maximizing player).
  - **Alpha-Beta Pruning:** Kỹ thuật tối ưu hóa đi kèm Minimax. Khi phát hiện một nhánh đi chắc chắn tồi hơn nhánh đã tìm thấy trước đó, thuật toán sẽ "cắt tỉa" (bỏ qua không duyệt tiếp nhánh con đó).
* **Công dụng:**  
  Giúp máy tính đưa ra nước cờ Caro thông minh như đại kiện tướng, phản xạ tức thì dưới 0.1 giây mà không bị đơ giật điện thoại nhờ giảm thiểu hàng triệu trạng thái duyệt thừa.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/caro/caro_ai_engine.dart`.
  - Xây dựng ma trận bàn cờ 10x10 với hệ thống chấm điểm thế cờ: `winScore = 1,000,000`, `fourScore = 50,000` (4 con liền), `openThreeScore = 5,000` (3 con mở hai đầu)... Hỗ trợ 3 cấp độ: Tập Sự, Chiến Thuật Gia, Đại Kiện Tướng.

### 2.2. A* Search Algorithm (Thuật toán tìm kiếm A-Star)
* **Nó là cái gì?**  
  Là một trong những thuật toán tìm kiếm đường đi ngắn nhất tốt nhất trong khoa học máy tính. A* đánh giá mỗi bước đi bằng hàm chi phí:
  $$f(n) = g(n) + h(n)$$
  Trong đó:
  - $g(n)$: Chi phí thực tế đã đi từ trạng thái bắt đầu đến trạng thái hiện tại $n$.
  - $h(n)$: Hàm ước lượng Heuristic (khoảng cách dự đoán từ $n$ đến đích).
* **Công dụng:**  
  Tự động giải bài toán Xếp hình trượt (Slide Puzzle 3x3 / 4x4) với số bước trượt ít nhất và thời gian tính toán nhanh nhất.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/slide_puzzle/puzzle_solver_a_star.dart`.
  - Kết hợp với cấu trúc hàng đợi ưu tiên (Priority Queue) để tìm đường về đích cho người chơi khi bấm nút "Gợi Ý A*".

### 2.3. Manhattan Distance (Khoảng cách Manhattan)
* **Nó là cái gì?**  
  Là khoảng cách giữa hai điểm trong hệ tọa độ lưới hình chữ nhật, chỉ được phép di chuyển theo phương thẳng đứng và phương ngang (giống như xe taxi chạy qua các dãy phố Manhattan ở New York):
  $$d = |x_1 - x_2| + |y_1 - y_2|$$
* **Công dụng:**  
  Được dùng làm hàm ước lượng Heuristic $h(n)$ cho thuật toán A*. Với mỗi ô số, tính xem nó đang lệch bao nhiêu bước so với vị trí chuẩn của nó. Tổng khoảng cách Manhattan càng nhỏ thì trạng thái bàn cờ càng gần với chiến thắng.
* **Đã thực hiện gì trong bài?**  
  - Hàm `_calculateManhattanDistance` trong `puzzle_solver_a_star.dart`.

### 2.4. Backtracking Algorithm (Thuật toán Quay lui)
* **Nó là cái gì?**  
  Phương pháp tìm kiếm lời giải bằng cách thử từng bước một. Nếu phát hiện một bước đi vi phạm luật (gặp ngõ cụt), thuật toán sẽ quay lui (backtrack) lại bước trước đó, hủy bỏ giá trị đã chọn và thử nhánh tiếp theo.
* **Công dụng:**  
  Dùng để sinh đề bài Sudoku chuẩn 9x9 ngẫu nhiên và giải bàn cờ Sudoku tự động để đảm bảo bàn cờ luôn có duy nhất một nghiệm chuẩn.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/sudoku/sudoku_generator.dart` và `sudoku_solver_ai.dart`.

### 2.5. Naked Single Deduction (Kỹ thuật suy luận số độc nhất)
* **Nó là cái gì?**  
  Kỹ thuật giải đố Sudoku ở cấp độ suy luận: Một ô trống được gọi là "Naked Single" nếu sau khi quét toàn bộ hàng ngang, cột dọc và khối vuông 3x3 bao quanh nó, 8 số từ 1-9 đã xuất hiện, khiến cho ô đó **chỉ còn duy nhất 1 số khả dĩ**.
* **Công dụng:**  
  Khác với các app thông thường chỉ điền đại số đáp án (Cheat), AI của Goddy **giải thích được lý do logic VÌ SAO** ô đó phải điền số đó cho người chơi học hỏi.
* **Đã thực hiện gì trong bài?**  
  - Tích hợp trong `sudoku_solver_ai.dart`, hiển thị thông điệp gợi ý trực quan: *"Hàng, cột và khối 3x3 đã có đủ các số khác, ô này bắt buộc là số X!"*.

---

## 3. Nhóm 3: Cảm biến Phần cứng Di động

### 3.1. Accelerometer & Gyroscope (Cảm biến gia tốc & Con quay hồi chuyển)
* **Nó là cái gì?**  
  - **Accelerometer (Gia tốc kế):** Cảm biến phần cứng tích hợp trong bo mạch điện thoại, đo lực gia tốc trọng trường tác động lên máy theo 3 trục không gian ($X$: nghiêng trái/phải, $Y$: nghiêng lên/xuống, $Z$: nâng máy).
  - **Gyroscope (Con quay hồi chuyển):** Đo vận tốc góc quay của thiết bị trong không gian.
* **Công dụng:**  
  Tạo ra lối chơi đột phá (Tilt Gameplay) độc quyền của ứng dụng di động: Người chơi không cần chạm tay vào màn hình mà chỉ cần **nghiêng điện thoại sang trái, phải, trên, dưới** để các khối gạch trượt theo quán tính vật lý thực tế.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/games/slide_puzzle/slide_puzzle_screen.dart`.
  - Sử dụng package `sensors_plus` lắng nghe luồng sự kiện `accelerometerEventStream()`. Xử lý ngưỡng gia tốc (Threshold > 3.0 m/s²) để chuyển động tác nghiêng điện thoại thành lệnh trượt gạch.

---

## 4. Nhóm 4: Mạng, Điện toán Đám mây & Đồng bộ Thời gian thực

### 4.1. PRNG & Seed Synchronization (Đồng bộ hạt giống ngẫu nhiên)
* **Nó là cái gì?**  
  - **PRNG (Pseudo-Random Number Generator):** Thuật toán sinh số giả ngẫu nhiên toán học từ một con số mầm mống ban đầu gọi là `Seed`. Với cùng một số `Seed`, thuật toán ở mọi máy tính trên thế giới sẽ luôn tạo ra một chuỗi số ngẫu nhiên **giống hệt nhau 100%**.
* **Công dụng:**  
  Giải quyết bài toán công bằng trong thi đấu đối kháng Online 1v1: Khi hai người chơi ở hai đầu đất nước cùng vào một phòng thi đấu Sudoku, Rubik hay Xếp hình, máy chủ chỉ cần phát một con số `Seed` chung (ví dụ: `Seed = 827419`). Cả 2 máy điện thoại sẽ tự động sinh ra bàn cờ **có các vị trí đảo màu/xáo trộn giống hệt nhau từng chi tiết**.
* **Đã thực hiện gì trong bài?**  
  - Máy chủ `DuelRooms` trên WebAPI lưu trường `Seed`.
  - Tọa lạc tại: `goddy/lib/services/challenge_service.dart`. Khi bắt đầu ván mới hoặc tái đấu (Rematch), hệ thống tự tạo một `Random().nextInt(1000000)` mới để cả 2 máy nhận đề thi mới cùng lúc.

### 4.2. Cloud Tunnel (Cloudflare Tunnel / Conveyor by Keyoti)
* **Nó là cái gì?**  
  Là kỹ thuật thiết lập đường hầm mạng đảo chiều (Reverse Proxy Tunnel) từ máy tính cá nhân nội bộ ra mạng Internet công cộng qua cổng bảo mật HTTPS 443.
* **Công dụng:**  
  Vượt qua rào cản mạng nội bộ (NAT / Router Firewall): Giúp các điện thoại di động dù đang ở ngoài đường dùng mạng 4G/5G Viettel, VinaPhone hay Wi-Fi ở nhà bạn bè đều có thể kết nối thẳng vào WebAPI ASP.NET Core đang chạy trên laptop mà không cần thuê máy chủ đắt đỏ hay cấu hình mở cổng mạng phức tạp.
* **Đã thực hiện gì trong bài?**  
  - Tích hợp tiện ích [Chay_Online_API.bat](file:///c:/Users/phuco/LTDD_Tuan7/Chay_Online_API.bat) sử dụng Cloudflare Tunnel, mở đường link Public toàn cầu:
    `https://oven-eggs-millennium-start.trycloudflare.com/api/`.

### 4.3. HTTP Polling (Truy vấn vòng lặp định kỳ)
* **Nó là cái gì?**  
  Cơ chế truyền thông mạng trong đó ứng dụng di động (Client) định kỳ gửi yêu cầu HTTP GET lên máy chủ (Server) mỗi khoảng thời gian ngắn (ví dụ: 1.0 - 1.5 giây) để kiểm tra xem có dữ liệu mới hay không.
* **Công dụng:**  
  Đồng bộ trạng thái phòng thi đấu 1v1 (đối thủ đã bấm Sẵn sàng chưa, đối thủ đã giải xong chưa, nước cờ Caro mới của đối thủ) và tin nhắn phòng Chat mà không bị đứt kết nối như Socket khi sóng 4G chập chờn.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/screens/challenge/duel_room_screen.dart` và `goddy/lib/screens/chat/chat_screen.dart`.
  - Tích hợp cơ chế phát hiện đối thủ hoàn thành trước: Ngay khi máy chủ báo trạng thái phòng kết thúc, màn hình lập tức hiện thông báo: *"Đối thủ đã hoàn thành! Bạn muốn tiếp tục giải hay quay về sảnh?"*.

### 4.4. CORS (Cross-Origin Resource Sharing)
* **Nó là cái gì?**  
  Cơ chế bảo mật của trình duyệt và giao thức HTTP, quy định xem ứng dụng từ một nguồn (Origin/IP/Port) này có được phép yêu cầu tài nguyên từ một nguồn khác hay không.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `Goddy_Game_WebAPI/Program.cs`. Cấu hình `policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()` để đảm bảo điện thoại thật, máy ảo Android Emulator (`10.0.2.2`), BlueStacks hay trình duyệt web đều kết nối WebAPI thông suốt.

---

## 5. Nhóm 5: Backend WebAPI & Cơ sở Dữ liệu

### 5.1. ASP.NET Core WebAPI (.NET 9)
* **Nó là cái gì?**  
  Là nền tảng phát triển ứng dụng WebAPI hiệu năng cao, hiện đại nhất của Microsoft chạy trên nền tảng .NET 9 LTS.
* **Công dụng:**  
  Đóng vai trò máy chủ xử lý toàn bộ nghiệp vụ (Business Logic): xác thực tài khoản, kiểm tra phòng thách đấu, ghi nhận kỷ lục bảng xếp hạng và trung chuyển tin nhắn trò chuyện.
* **Đã thực hiện gì trong bài?**  
  - Xây dựng 6 cụm Controller chuẩn RESTful tại thư mục `Goddy_Game_WebAPI/Controllers/`:
    + `AuthController.cs`: Đăng ký, Đăng nhập, thông tin Profile.
    + `ChallengeController.cs`: Tạo phòng, vào phòng, sẵn sàng, gửi nước cờ, kết thúc ván.
    + `LeaderboardController.cs`: Bảng xếp hạng Top điểm số cho từng game.
    + `ChatController.cs`: Tin nhắn cộng đồng và sticker cảm xúc.
    + `ProgressController.cs`: Lưu trạng thái bàn cờ đang chơi dở.

### 5.2. SQLite & EF Core (Entity Framework Core)
* **Nó là cái gì?**  
  - **SQLite (`goddy.db`):** Hệ quản trị cơ sở dữ liệu quan hệ (RDBMS) không cần cài đặt máy chủ dịch vụ cồng kềnh, toàn bộ cơ sở dữ liệu được gói gọn trong 1 file vật lý duy nhất, đạt độ tin cậy và tốc độ đọc/ghi cực nhanh.
  - **EF Core:** Bộ ánh xạ quan hệ đối tượng (ORM - Object-Relational Mapper) của .NET, giúp lập trình viên thao tác với cơ sở dữ liệu thông qua các đối tượng C# (Entities) và câu lệnh LINQ thay vì viết mã SQL thô.
* **Công dụng:**  
  Lưu trữ dữ liệu bền vững (Persistence). Dù tắt máy, khởi động lại server hay người dùng xóa app cài lại trên điện thoại, toàn bộ tài khoản và thành tích vẫn nguyên vẹn 100%.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `Goddy_Game_WebAPI/Data/GoddyDbContext.cs`.
  - Quản trị 5 bảng quan hệ: `Users` (Người dùng), `Scores` (Điểm số), `DuelRooms` (Phòng thách đấu), `ChatMessages` (Tin nhắn), `GameProgresses` (Tiến độ game).

### 5.3. DTO (Data Transfer Object)
* **Nó là cái gì?**  
  Mẫu thiết kế (Design Pattern) tạo ra các lớp đối tượng chỉ dùng riêng cho việc đóng gói và vận chuyển dữ liệu qua mạng giữa Client và Server.
* **Công dụng:**  
  Bảo mật dữ liệu nội bộ: Client không thể thấy các trường nhạy cảm trong Database (như mật khẩu băm, ID hệ thống nội bộ).
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `Goddy_Game_WebAPI/Models/Dtos.cs` (`LoginDto`, `RegisterDto`, `SubmitScoreDto`, `MoveCaroDto`...).

---

## 6. Nhóm 6: Công cụ Phát triển & Tối ưu Biên dịch

### 6.1. Flutter SDK & Dart Language
* **Nó là cái gì?**  
  Bộ công cụ phát triển giao diện người dùng (UI Toolkit) đa nền tảng mã nguồn mở do Google phát triển, sử dụng ngôn ngữ lập trình Dart hiện đại hướng đối tượng.
* **Công dụng:**  
  Biên dịch ra mã máy gốc (Native Machine Code) cho Android và iOS từ một cơ sở mã nguồn duy nhất (Single Codebase), mang lại trải nghiệm cảm ứng siêu nhạy và giao diện đồ họa thống nhất.

### 6.2. AOT Compilation (Ahead-Of-Time)
* **Nó là cái gì?**  
  Kỹ thuật biên dịch mã nguồn Dart trực tiếp thành mã nhị phân máy tính (ARM64 Machine Code) trước khi xuất file cài đặt, thay vì vừa chạy vừa thông dịch (JIT - Just-In-Time) như lúc debug.
* **Công dụng:**  
  Giúp ứng dụng mở lên tức thì (Instant Startup), tối ưu hóa bộ nhớ RAM và chạy mượt mà không bao giờ bị hiện tượng khựng khung hình (Jank).
* **Đã thực hiện gì trong bài?**  
  - Sử dụng lệnh `flutter build apk --release` để tạo ra bản phân phối thương mại tối ưu [Goddy_Gaming_App_Release.apk](file:///c:/Users/phuco/LTDD_Tuan7/Goddy_Gaming_App_Release.apk).

### 6.3. Tree-shaking (Rũ cây loại bỏ mã thừa)
* **Nó là cái gì?**  
  Cơ chế tối ưu hóa trong quá trình build của Flutter/Dart: Trình biên dịch phân tích cú pháp toàn bộ dự án, tìm ra những hàm, lớp, hình ảnh hoặc ký tự icon nào không bao giờ được gọi đến và loại bỏ hoàn toàn chúng khỏi gói cài đặt.
* **Công dụng:**  
  Giảm dung lượng file APK từ hàng trăm MB xuống kích thước siêu gọn nhẹ (~52MB), giúp người dùng tải nhanh và tiết kiệm dung lượng mạng di động.
* **Đã thực hiện trong bài:**  
  - Tự động nén font `MaterialIcons-Regular.otf` giảm 99.3% dung lượng khi đóng gói APK.

### 6.4. Session Persistence (Lưu trữ phiên qua SharedPreferences)
* **Nó là cái gì?**  
  Cơ chế lưu trữ cặp khóa - giá trị (Key-Value) vào bộ nhớ bất biến của hệ điều hành Android (dưới dạng XML trong thư mục riêng của app).
* **Công dụng:**  
  Ghi nhớ trạng thái đăng nhập: Người dùng đăng nhập 1 lần là lần sau mở app tự động vào thẳng trang chủ mà không bắt đăng nhập lại.
* **Đã thực hiện gì trong bài?**  
  - Tọa lạc tại: `goddy/lib/services/storage_service.dart`. Lưu trữ `user_id`, `username`, `avatar` và địa chỉ `custom_base_url`.

---

## 7. Bảng Tra Cứu Nhanh Tất Cả Các Từ Viết Tắt (Acronyms)

| Từ viết tắt | Tên tiếng Anh đầy đủ | Ý nghĩa & Vai trò trong dự án Goddy |
| :--- | :--- | :--- |
| **API** | Application Programming Interface | Giao diện lập trình ứng dụng, cầu nối dữ liệu giữa App Mobile và Máy chủ. |
| **REST** | Representational State Transfer | Kiến trúc tiêu chuẩn cho các dịch vụ web giao tiếp qua HTTP. |
| **EF Core** | Entity Framework Core | Bộ công cụ ORM quản lý cơ sở dữ liệu SQLite trong C# .NET. |
| **ORM** | Object-Relational Mapping | Kỹ thuật ánh xạ bảng CSDL thành các đối tượng C#. |
| **DTO** | Data Transfer Object | Đối tượng vận chuyển dữ liệu an toàn giữa Client và WebAPI. |
| **CRUD** | Create - Read - Update - Delete | 4 thao tác cơ bản trên CSDL: Thêm, Đọc, Sửa, Xóa dữ liệu. |
| **CORS** | Cross-Origin Resource Sharing | Cơ chế cho phép thiết bị bên ngoài gọi vào WebAPI mà không bị chặn. |
| **PRNG** | Pseudo-Random Number Generator | Bộ sinh số giả ngẫu nhiên toán học dùng để đồng bộ hạt giống bàn cờ. |
| **WCA** | World Cube Association | Hiệp hội Rubik Thế giới, cung cấp chuẩn xáo trộn cho game Rubik. |
| **CFOP** | Cross - F2L - OLL - PLL | Phương pháp giải Rubik 4 giai đoạn dùng cho thuật toán AI Rubik Solver. |
| **A\*** | A-Star Search Algorithm | Thuật toán tìm đường đi và số bước giải tối ưu cho game Xếp hình trượt. |
| **LINQ** | Language Integrated Query | Cú pháp truy vấn dữ liệu mạnh mẽ tích hợp sẵn trong C#. |
| **APK** | Android Package Kit | Định dạng file gói cài đặt ứng dụng trên hệ điều hành Android. |
| **AOT** | Ahead-Of-Time | Trình biên dịch mã máy trước khi chạy, giúp app khởi động nhanh và mượt. |
| **SDK** | Software Development Kit | Bộ công cụ phát triển phần mềm (Flutter SDK .NET 9 SDK). |
| **LAN** | Local Area Network | Mạng cục bộ nội bộ (cùng mạng Wi-Fi). |
| **PIN** | Personal Identification Number | Mã số định danh 6 chữ số dùng để tham gia phòng thách đấu 1v1. |
| **EMP** | Electro-Magnetic Pulse | Tên thẻ kỹ năng "Phong ấn ô năng lượng" trong cờ Caro chiến thuật. |
| **UI / UX** | User Interface / User Experience | Giao diện người dùng và Trải nghiệm người dùng của app. |

---
*Tài liệu được lưu trữ trực tiếp tại file: `ThuatNgu_CongCu_GiaiThich_Goddy.md` trong thư mục gốc của dự án.*
