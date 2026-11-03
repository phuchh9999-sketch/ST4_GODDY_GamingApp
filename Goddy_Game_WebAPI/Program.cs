using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Data;
using Goddy_Game_WebAPI.Models;
using Goddy_Game_WebAPI.Middleware;

try
{
    Console.OutputEncoding = System.Text.Encoding.UTF8;
}
catch { }

var builder = WebApplication.CreateBuilder(args);

// Tắt các câu lệnh SQL nội bộ của Entity Framework Core để giữ Terminal sạch đẹp cho Live Demo
builder.Logging.AddFilter("Microsoft.EntityFrameworkCore", LogLevel.Warning);
builder.Logging.AddFilter("Microsoft.EntityFrameworkCore.Database.Command", LogLevel.Warning);

// 1. Add Services & DbContext (SQLite Database - Chuẩn tiêu chí giảng viên)
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Goddy Gaming Hub WebAPI",
        Version = "v1",
        Description = "Hệ thống WebAPI quản lý tài khoản, lưu tiến độ, bảng xếp hạng, thách đấu và chat cho ứng dụng Goddy Gaming (CSDL SQLite)"
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=goddy.db";
builder.Services.AddDbContext<GoddyDbContext>(options =>
{
    options.UseSqlite(connectionString);
});

// 2. Enable CORS for all clients (Emulator 10.0.2.2, LAN, Web, BlueStacks, Mobile)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// 3. Configure HTTP pipeline
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Goddy Gaming API v1");
    c.RoutePrefix = string.Empty; // Swagger at root URL
});

app.UseCors("AllowAll");

// Kích hoạt Live Demo Logger Middleware để hiện thông tin thao tác của 3 thành viên trên màn hình HDMI
app.UseMiddleware<LiveDemoLoggerMiddleware>();

app.UseAuthorization();
app.MapControllers();
app.MapGet("/api/health", () => Results.Ok(new { status = "healthy", server = "Goddy Gaming Hub WebAPI", db = "SQLite" }));

// 4. Tự động khởi tạo Database SQLite (goddy.db) & Seed dữ liệu mẫu nếu chưa có
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<GoddyDbContext>();
    context.Database.EnsureCreated();

    if (!context.Users.Any())
    {
        context.Users.AddRange(
            new AppUser { Email = "player@goddy.io", Username = "CyberPlayer", PasswordHash = "123456", Avatar = "⚡", Exp = 2800, GamesPlayed = 15, WinsCount = 11, RubikBestSeconds = 24, CaroBestScore = 1850, SudokuBestSeconds = 145, PuzzleBestSeconds = 29 },
            new AppUser { Email = "admin@goddy.io", Username = "GoddyAdmin", PasswordHash = "123456", Avatar = "👑", Exp = 12500, GamesPlayed = 80, WinsCount = 72, RubikBestSeconds = 18, CaroBestScore = 3200, SudokuBestSeconds = 95, PuzzleBestSeconds = 21 },
            new AppUser { Email = "viper@goddy.io", Username = "ViperCyber", PasswordHash = "123456", Avatar = "🥷", Exp = 8400, GamesPlayed = 40, WinsCount = 33, RubikBestSeconds = 22, CaroBestScore = 2400, SudokuBestSeconds = 115, PuzzleBestSeconds = 25 }
        );

        context.Scores.AddRange(
            new GameScoreRecord { UserId = "viper", Username = "ViperCyber", Avatar = "🥷", GameType = "rubik", Score = 2450, TimeSeconds = 22, Mistakes = 0, IsWin = true },
            new GameScoreRecord { UserId = "speed", Username = "SpeedCuber_VN", Avatar = "🧩", GameType = "rubik", Score = 2100, TimeSeconds = 26, Mistakes = 1, IsWin = true },
            new GameScoreRecord { UserId = "caroking", Username = "GrandmasterCaro", Avatar = "🧠", GameType = "caro", Score = 3200, TimeSeconds = 140, Mistakes = 1, IsWin = true },
            new GameScoreRecord { UserId = "sudokugod", Username = "HologramBrain", Avatar = "🔮", GameType = "sudoku", Score = 2950, TimeSeconds = 95, Mistakes = 0, IsWin = true },
            new GameScoreRecord { UserId = "tiltking", Username = "GyroSensoryKing", Avatar = "📱", GameType = "slide_puzzle", Score = 2800, TimeSeconds = 21, Mistakes = 0, IsWin = true }
        );

        context.ChatMessages.AddRange(
            new ChatMessageRecord { SenderId = "sys", SenderName = "GoddySystem 🤖", SenderAvatar = "🛡️", Text = "Chào mừng bạn đến với Goddy Gaming Hub! Đua top nhận danh hiệu Huyền Thoại!" },
            new ChatMessageRecord { SenderId = "viper", SenderName = "ViperCyber", SenderAvatar = "⚡", Text = "Có ai solo Caro cược rank không?" }
        );

        context.SaveChanges();
    }
}

app.Run();
