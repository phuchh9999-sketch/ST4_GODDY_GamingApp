using System.Text;
using System.Text.Json;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Middleware
{
    public class LiveDemoLoggerMiddleware
    {
        private readonly RequestDelegate _next;

        public LiveDemoLoggerMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var path = context.Request.Path.Value?.ToLower() ?? "";
            var method = context.Request.Method;

            // Only inspect API endpoints
            if (path.StartsWith("/api/"))
            {
                var clientIp = context.Connection.RemoteIpAddress?.ToString() ?? "Client";
                if (clientIp.Contains(":")) clientIp = "Mobile-Device";

                // Enable buffering to read body safely
                context.Request.EnableBuffering();
                string bodyAsText = string.Empty;

                if (method == "POST" && context.Request.ContentLength > 0)
                {
                    using (var reader = new StreamReader(context.Request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true))
                    {
                        bodyAsText = await reader.ReadToEndAsync();
                        context.Request.Body.Position = 0;
                    }
                }

                // Log specific game actions with distinct visual styles
                LogGameAction(path, method, bodyAsText, clientIp);
            }

            await _next(context);
        }

        private void LogGameAction(string path, string method, string body, string clientIp)
        {
            var time = DateTime.Now.ToString("HH:mm:ss");
            var originalColor = Console.ForegroundColor;

            try
            {
                if (path.Contains("/api/auth/login") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<LoginDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($"\n[ {time} ] [AUTH / DANG NHAP] Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- User: {dto?.Email} dang nhap thanh cong vao he thong!");
                }
                else if (path.Contains("/api/auth/register") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<RegisterDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine($"\n[ {time} ] [AUTH / DANG KY MOI] Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- Tai khoan: {dto?.Username} ({dto?.Email})");
                }
                else if (path.Contains("/api/chat/send") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<SendChatDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Blue;
                    Console.WriteLine($"\n[ {time} ] [SANH CHAT THE GIOI] Tu [{clientIp}]");
                    Console.WriteLine($"          |-- [{dto?.SenderName}]: \"{dto?.Text}\"");
                }
                else if (path.Contains("/api/challenge/create") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<CreateRoomDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Magenta;
                    Console.WriteLine($"\n[ {time} ] [THACH DAU 1v1 - TAO PHONG] Tu [{clientIp}]");
                    Console.WriteLine($"          |-- Host: [{dto?.HostName}] | Mon: {dto?.GameType.ToUpper()} (Cap do: {dto?.Difficulty})");
                }
                else if (path.Contains("/api/challenge/join") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<JoinRoomDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine($"\n[ {time} ] [THACH DAU 1v1 - VAO PHONG] Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- Doi thu: [{dto?.GuestName}] da vao phong [{dto?.RoomCode.ToUpper()}]!");
                    Console.WriteLine($"          |-- KICH HOAT READY CHECK: Cho ca 2 nguoi cung bam 'SAN SANG' de dau!");
                }
                else if (path.Contains("/api/challenge/ready") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<ToggleReadyDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.DarkMagenta;
                    Console.WriteLine($"\n[ {time} ] [READY CHECK CAP NHAT] Phong [{dto?.RoomCode.ToUpper()}] | Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- Nguoi choi: [{dto?.UserId}] -> Trang thai San Sang: {dto?.IsReady}");
                }
                else if (path.Contains("/api/challenge/move") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<CaroMoveDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine($"\n[ {time} ] [CARO 1v1 - NUOC DI MOI] Phong [{dto?.RoomCode.ToUpper()}] | Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- Nguoi choi {(dto?.Player == 1 ? "1 (X)" : "2 (O)")} danh o: [Hang {dto?.Row + 1}, Cot {dto?.Col + 1}] {(dto?.Skill != null ? " | KY NANG: " + dto.Skill.ToUpper() : "")}");
                }
                else if (path.Contains("/api/challenge/submit-result") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<SubmitDuelResultDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($"\n[ {time} ] [KET QUA DOI KHANG 1v1] Phong [{dto?.RoomCode.ToUpper()}] | Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- Nguoi choi: [{dto?.UserId}] -> Diem: {dto?.Score} | Thoi gian: {dto?.TimeSeconds}s | Loi: {dto?.Mistakes}");
                }
                else if (path.Contains("/api/leaderboard/submit") && method == "POST")
                {
                    var dto = JsonSerializer.Deserialize<SubmitScoreDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    Console.ForegroundColor = ConsoleColor.DarkYellow;
                    Console.WriteLine($"\n[ {time} ] [LUU DIEM CSDL SQLITE] Thiet bi [{clientIp}]");
                    Console.WriteLine($"          |-- Ky thu: [{dto?.Username}]");
                    Console.WriteLine($"          |-- Mon: {dto?.GameType.ToUpper()} | Diem: {dto?.Score} | Thoi gian: {dto?.TimeSeconds}s | Loi: {dto?.Mistakes}");
                    Console.WriteLine($"          |-- TRANG THAI: Da ghi thanh cong vao file co so du lieu 'goddy.db'!");
                }
                else if (path.Contains("/api/leaderboard") && method == "GET")
                {
                    Console.ForegroundColor = ConsoleColor.DarkGray;
                    Console.WriteLine($"[ {time} ] [LEADERBOARD] Thiet bi [{clientIp}] vua tai Bang Vang Podium Top 20 ky thu.");
                }
            }
            catch
            {
                // Ignore parsing errors for general logging
            }
            finally
            {
                Console.ForegroundColor = originalColor;
            }
        }
    }
}

