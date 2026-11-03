  # KỊCH BẢN THUYẾT TRÌNH & DÀN Ý SLIDE POWERPOINT
## ĐỒ ÁN: CỔNG GAME TRÍ TUỆ ĐỐI KHÁNG "GODDY GAMING HUB"
* **Sinh viên**: Huỳnh Nguyễn Vĩnh Phúc - **MSSV**: 2380614923
* **File PowerPoint chính thức**: `Goddy_Gaming_Hub_ThuyetTrinh.pptx` (đã tạo sẵn tại thư mục gốc)
* **Tổng thời gian thuyết trình lý tưởng**: 3 - 5 phút (ngắn gọn, xúc tích trước khi vào phần Demo trực tiếp)

---

### SLIDE 1: TRANG TIÊU ĐỀ
* **Tiêu đề**: CỔNG GAME TRÍ TUỆ ĐỐI KHÁNG ĐA NỀN TẢNG "GODDY GAMING HUB"
* **Nội dung hiển thị**:
  - Sinh viên thực hiện: Huỳnh Nguyễn Vĩnh Phúc (MSSV: 2380614923)
  - Công nghệ: Flutter SDK (Dart) + ASP.NET Core Web API (.NET 9) + Conveyor by Keyoti (Free)
  - Sản phẩm: Bản cài đặt APK Release AOT (~52.4MB)
* **Lời thoại bạn nên nói (30 giây)**:
  > *"Em xin kính chào Thầy/Cô và các bạn. Hôm nay em xin phép được trình bày đồ án cuối kỳ môn Lập trình thiết bị di động với đề tài: **Cổng Game Trí Tuệ Đối Kháng Goddy Gaming Hub**. Đây là một nền tảng game di động tích hợp 4 trò chơi trí tuệ giải đố thế hệ mới, vận dụng cảm biến phần cứng, trí tuệ nhân tạo và hệ thống thi đấu đối kháng trực tuyến thời gian thực."*

---

### SLIDE 2: LÝ DO CHỌN ĐỀ TÀI & TÍNH ĐỘT PHÁ
* **Nội dung hiển thị**:
  - **Hạn chế game hiện nay**: Các app game giải đố thường rời rạc (mỗi game 1 tài khoản); Rubik di động khó điều khiển; Caro người đi trước luôn thắng 90%; Sudoku chỉ báo đúng/sai; Slide Puzzle chỉ bấm nút ảo thông thường.
  - **Giải pháp của Goddy**: Cổng game All-in-One dùng chung 1 tài khoản duy nhất (SSO); Cải tiến luật chơi và áp dụng công nghệ mới cho từng game; Cơ chế Thách Đấu 1v1 công bằng tuyệt đối.
* **Lời thoại bạn nên nói (45 giây)**:
  > *"Thay vì chỉ làm một trò chơi đơn lẻ thông thường, em chọn xây dựng **Goddy** thành một cổng game 'Tất cả trong một' dùng chung duy nhất một tài khoản. Điểm đặc biệt của đồ án là đã giải quyết triệt để các hạn chế của game truyền thống: Rubik được mô phỏng 3D xoay chuẩn thực tế WCA, cờ Caro được bổ sung thẻ kỹ năng lượng tử để cân bằng thế cờ, Sudoku có AI phân tích suy luận ô số, và game Xếp hình trượt được điều khiển trực tiếp bằng cách nghiêng điện thoại nhờ cảm biến gia tốc."*

---

### SLIDE 3: KIẾN TRÚC KỸ THUẬT & CÔNG NGHỆ
* **Nội dung hiển thị (3 Cột)**:
  1. **Mobile Frontend**: Flutter Native, 60 FPS mượt mà, tối ưu AOT dung lượng chỉ ~52.4MB, quản lý trạng thái bằng Provider.
  2. **Network & Tunnel**: Conveyor by Keyoti (Free) cấp link Cloud `conveyor.cloud`, giúp điện thoại kết nối WebAPI qua 4G hoặc khác mạng Wi-Fi không cần cấu hình Router.
  3. **Backend & Database**: ASP.NET Core Web API (.NET 9), CSDL SQLite lưu trữ chuẩn (`goddy.db`) qua Entity Framework Core, bảo mật JWT.
* **Lời thoại bạn nên nói (45 giây)**:
  > *"Về mặt kiến trúc kỹ thuật: Phía Client được xây dựng hoàn toàn bằng **Flutter SDK**, biên dịch bản Release tối ưu dung lượng nhỏ gọn chỉ 52MB. Phía Server là **ASP.NET Core Web API** trên .NET 9 kết hợp cơ sở dữ liệu **SQLite** lưu trữ dữ liệu tài khoản, điểm số và lịch sử đấu độc lập theo đúng chuẩn quy định của môn học. Đặc biệt, để giải quyết bài toán kiểm thử trên điện thoại thật khác mạng Wi-Fi hoặc dùng 4G, em đã tích hợp giải pháp **Conveyor by Keyoti** - tự động public API qua Internet miễn phí giúp ứng dụng kết nối thông suốt ở bất cứ đâu."*

---

### SLIDE 4 & 5: BỘ 4 GAME TRÍ TUỆ THẾ HỆ MỚI
* **Nội dung hiển thị**:
  - **1. Rubik 3D AI Speedcube**: Trạng thái gốc 6 mặt thuần 1 màu -> Bấm "Xáo Trộn" -> Bấm "Bắt Đầu Tính Giờ" -> Bảng nút xoay chuẩn thực tế (Ngang, Dọc, Xoay mặt) -> Tự động nhận diện chiến thắng -> Nút "Bắt Đầu Lại".
  - **2. Quantum Caro**: Đấu AI Minimax Heuristic 3 cấp độ + 2 Thẻ Kỹ Năng Lượng Tử (*Quantum Swap* hoán đổi cờ & *EMP Freeze* phong ấn ô) + Giới hạn suy nghĩ 15s/lượt.
  - **3. Sudoku Hologram Spectrum**: Quang phổ màu Neon phát hiện xung đột tức thì + AI gợi ý suy luận loại trừ (*Naked Single*) + 3 Mạng chơi.
  - **4. Gyro Tilt Slide Puzzle**: Cảm biến gia tốc di động (`sensors_plus`) **nghiêng máy để gạch tự trôi** + Thuật toán tối ưu A* Manhattan.
* **Lời thoại bạn nên nói (60 giây)**:
  > *"Đi vào chi tiết 4 trò chơi: Thứ nhất là **Rubik 3D**, ban đầu khối ở dạng thuần màu chuẩn, người chơi bấm 'Xáo trộn' theo giải thuật ngẫu nhiên rồi bấm 'Bắt đầu tính giờ', hệ thống có bảng nút xoay trực quan y như cầm cục rubik ngoài đời và tự động báo thắng khi giải xong. Thứ hai là **Quantum Caro**, khắc phục nhược điểm người đi trước quá mạnh bằng AI Minimax thông minh và 2 kỹ năng hoán đổi vị trí cờ hoặc phong ấn ô cờ hiểm. Thứ ba là **Sudoku Quang Phổ**, khi chạm vào ô nào hệ thống sẽ chiếu sáng hàng cột và giải thích lý do vì sao ô đó phải điền số đó. Và thứ tư là **Xếp hình trượt vật lý**, người chơi chỉ cần nghiêng điện thoại là các ô gạch sẽ trượt theo trọng lực quán tính phần cứng của máy."*

---

### SLIDE 6: THÁCH ĐẤU 1v1 & CƠ CHẾ READY CHECK
* **Nội dung hiển thị**:
  - Mời bạn bè trực tuyến từ danh sách bạn bè hoặc chia sẻ mã PIN.
  - **Quy tắc Ready Check nghiêm ngặt**: Cả 2 người chơi (Host & Guest) phải **CÙNG BẤM "SẴN SÀNG"** thì trận đấu mới bắt đầu. Nếu 1 trong 2 chưa sẵn sàng, nút Bắt đầu sẽ bị khóa.
  - **Điểm khởi đầu = 0**: Điểm của cả 2 xuất phát chuẩn từ 0 điểm.
  - Chung hạt giống đề bài (Seed): Đảm bảo tính công bằng tuyệt đối.
* **Lời thoại bạn nên nói (30 giây)**:
  > *"Ngoài chơi đơn, tất cả các game đều hỗ trợ chế độ **Thách Đấu 1v1**. Để đảm bảo công bằng trong thi đấu, em áp dụng cơ chế Ready Check: Cả hai người chơi phải cùng xác nhận 'Sẵn Sàng' thì ván đấu mới được phép bắt đầu. Khi ván đấu bắt đầu, điểm số của cả hai người đều xuất phát chuẩn từ 0 điểm và giải cùng một đề bài chung."*

---

### SLIDE 7: BẢNG XẾP HẠNG & SẢNH CHAT
* **Nội dung hiển thị**:
  - Bục vinh danh Podium Top 3 (Vàng, Bạc, Đồng) với avatar Cyberpunk.
  - 5 Tab phân loại: Tổng hợp, Rubik 3D, Caro, Sudoku, Slide Puzzle.
  - 7 Cấp bậc Rank từ Đồng đến Huyền Thoại Goddy.
  - Sảnh Chat Thế Giới kết nối cộng đồng với bộ Quick Stickers nhanh.
* **Lời thoại bạn nên nói (20 giây)**:
  > *"Sau mỗi ván đấu, điểm số và thành tích thời gian sẽ được tính toán theo công thức chuẩn và tự động gửi lên Backend WebAPI để xếp hạng trên bục Podium Top 3, đồng thời tích lũy điểm EXP thăng cấp Rank game thủ."*

---

### SLIDE 8: KỊCH BẢN LIVE DEMO ĐỒNG THỜI 3 THÀNH VIÊN (KẾT NỐI MÁY CHIẾU HDMI)
> **Mục tiêu đặc biệt**: Thỏa mãn 100% yêu cầu của Giảng viên - Cả 3 thành viên cùng trực tiếp thao tác demo. Máy chính gắn HDMI chiếu màn hình Terminal WebAPI, khi 2 thành viên còn lại thao tác trên điện thoại thì Terminal sẽ nổ log màu real-time tức thì!

* **Bố trí thiết bị**:
  - **Máy chính (Laptop)**: Gắn dây HDMI nối máy chiếu trường. Chạy cửa sổ Terminal `Goddy_Game_WebAPI` với giao diện Cyberpunk Monitor.
  - **Điện thoại 1 (Thành viên 1 - Thuyết trình trưởng)**: Cài app Goddy, mở phòng Thách đấu và demo Rubik 3D.
  - **Điện thoại 2 (Thành viên 2)**: Cài app Goddy, tham gia Thách đấu 1v1, demo thẻ kỹ năng Caro và Ready Check.
  - **Điện thoại 3 (Thành viên 3)**: Cài app Goddy, demo Sudoku Hologram, nghiêng máy Gyro Slide Puzzle, gửi Chat và Lưu điểm vào SQLite.

* **Trình tự phối hợp Demo 3 người (Tổng 3 phút)**:
  1. **Bước 1 (30s) - Khởi động máy chính & Đăng nhập**:
     - Thành viên 1 mở Terminal máy chính trên máy chiếu, thấy dòng chữ: `⚡ GODDY GAMING HUB - LIVE REALTIME TERMINAL MONITOR ⚡` và CSDL SQLite `goddy.db`.
     - Thành viên 2 và 3 bấm "Đăng nhập nhanh tân thủ" trên điện thoại -> **Terminal trên máy chiếu lập tức nổ log xanh lá xác nhận 2 thiết bị mobile đã đăng nhập thành công!**
  2. **Bước 2 (60s) - Thành viên 1 demo Rubik 3D & Thành viên 3 demo Gyro Tilt**:
     - Thành viên 1: Demo Rubik 3D xoay 360 độ, bấm Xáo trộn WCA -> Bấm Bắt đầu tính giờ -> Bấm xoay theo các phím chuẩn.
     - Thành viên 3: Cầm điện thoại 3 giơ cao trước mặt Thầy, **nghiêng máy qua lại để các ô gạch trượt tự động bằng cảm biến gia tốc `sensors_plus`**, sau đó bấm Lưu điểm -> **Terminal trên máy chiếu nổ log vàng kim: `🏆 [LƯU ĐIỂM CSDL SQLITE] Thành viên 3 - 2900 điểm -> Đã lưu vào goddy.db!`**
  3. **Bước 3 (60s) - Đỉnh cao đối kháng 1v1 giữa Thành viên 1 & Thành viên 2**:
     - Thành viên 1 bấm Tạo phòng Thách Đấu môn Caro -> Nhận mã PIN (VD: `GD4250`).
     - Thành viên 2 nhập mã `GD4250` trên điện thoại mình -> **Terminal trên máy chiếu hiện ngay: `⚔️ [THÁCH ĐẤU 1v1] Thành viên 2 đã vào phòng GD4250! Kích hoạt Ready Check!`**
     - Cả 2 cùng bấm **"SẴN SÀNG"** -> Nút Bắt Đầu mở khóa, cả 2 bắt đầu từ 0 điểm và giải chung đề bài.
     - Thành viên 2 biểu diễn thẻ kỹ năng Lượng tử *Quantum Swap* hoán đổi quân cờ.
  4. **Bước 4 (30s) - Tương tác Sảnh Chat & Bảng Xếp Hạng**:
     - Thành viên 3 gửi tin nhắn: *"Chúc mừng nhóm hoàn thành đồ án!"* -> **Terminal máy chiếu hiện ngay: `💬 [SẢNH CHAT THẾ GIỚI] [Thành viên 3]: "Chúc mừng nhóm hoàn thành đồ án!"`**
     - Thành viên 1 mở màn hình Leaderboard trên app cho Thầy thấy điểm số của Thành viên 3 đã xuất hiện trên bục Top Podium.

---

### SLIDE 9: TỔNG KẾT
* **Nội dung hiển thị**:
  - Đạt 100% barem điểm môn học.
  - Mã nguồn: `flutter analyze` 0 lỗi, `flutter test` 8/8 tests passed.
  - Bản build APK Release AOT ~52.4MB hoàn chỉnh.
* **Lời thoại kết thúc**:
  > *"Dạ, phần trình bày lý thuyết của em đến đây là hết. Sau đây em xin phép được mở ứng dụng trên điện thoại để Thầy/Cô trực tiếp trải nghiệm bản Demo ạ!"*
