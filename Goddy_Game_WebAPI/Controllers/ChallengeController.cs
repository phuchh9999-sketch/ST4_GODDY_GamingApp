using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Data;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChallengeController : ControllerBase
    {
        private readonly GoddyDbContext _context;

        public ChallengeController(GoddyDbContext context)
        {
            _context = context;
        }

        [HttpPost("create")]
        public async Task<IActionResult> CreateRoom([FromBody] CreateRoomDto dto)
        {
            var code = !string.IsNullOrWhiteSpace(dto.RoomCode)
                ? dto.RoomCode.Trim().ToUpper()
                : "GD" + Random.Shared.Next(1000, 9999).ToString();

            // Nếu phòng đã tồn tại trước đó thì xóa để làm mới
            var existing = await _context.DuelRooms.FindAsync(code);
            if (existing != null)
            {
                _context.DuelRooms.Remove(existing);
                await _context.SaveChangesAsync();
            }

            var room = new DuelRoomRecord
            {
                RoomCode = code,
                HostId = dto.HostId,
                HostName = dto.HostName,
                HostAvatar = string.IsNullOrWhiteSpace(dto.HostAvatar) ? "⚡" : dto.HostAvatar,
                GameType = string.IsNullOrWhiteSpace(dto.GameType) ? "caro" : dto.GameType.ToLower(),
                Difficulty = string.IsNullOrWhiteSpace(dto.Difficulty) ? "Normal" : dto.Difficulty,
                Seed = dto.Seed ?? Random.Shared.Next(10000, 99999),
                Status = "waiting",
                HostReady = false,
                GuestReady = false,
                HostScore = 0,
                GuestScore = 0
            };

            _context.DuelRooms.Add(room);
            await _context.SaveChangesAsync();

            return Ok(room);
        }

        [HttpPost("join")]
        public async Task<IActionResult> JoinRoom([FromBody] JoinRoomDto dto)
        {
            var code = dto.RoomCode.Trim().ToUpper();
            var room = await _context.DuelRooms.FindAsync(code);
            if (room == null)
            {
                return NotFound(new { message = $"Không tìm thấy phòng đấu {code}! Vui lòng kiểm tra lại mã PIN hoặc đợi chủ phòng bấm Tạo phòng." });
            }

            // Nếu người vào chính là chủ phòng thì cho phép quay lại phòng
            if (dto.GuestId == room.HostId)
            {
                return Ok(room);
            }

            // Kiểm tra phòng đã có đối thủ khác chưa
            if (!string.IsNullOrEmpty(room.GuestId) && room.GuestId != dto.GuestId)
            {
                return BadRequest(new { message = "Phòng thách đấu này đã có 2 người chơi!" });
            }

            room.GuestId = dto.GuestId;
            room.GuestName = dto.GuestName;
            room.GuestAvatar = string.IsNullOrWhiteSpace(dto.GuestAvatar) ? "🎮" : dto.GuestAvatar;
            room.Status = "ready";
            room.GuestReady = false;

            await _context.SaveChangesAsync();
            return Ok(room);
        }

        [HttpGet("{roomCode}")]
        public async Task<IActionResult> GetRoom(string roomCode)
        {
            var code = roomCode.Trim().ToUpper();
            var room = await _context.DuelRooms.FindAsync(code);
            if (room == null) return NotFound(new { message = "Không tìm thấy phòng đấu!" });
            return Ok(room);
        }

        [HttpPost("ready")]
        public async Task<IActionResult> ToggleReady([FromBody] ToggleReadyDto dto)
        {
            var code = dto.RoomCode.Trim().ToUpper();
            var room = await _context.DuelRooms.FindAsync(code);
            if (room == null) return NotFound(new { message = "Không tìm thấy phòng đấu!" });

            if (dto.UserId == room.HostId)
            {
                room.HostReady = dto.IsReady;
            }
            else if (dto.UserId == room.GuestId)
            {
                room.GuestReady = dto.IsReady;
            }

            if (room.HostReady && room.GuestReady)
            {
                room.Status = "playing";
            }
            else
            {
                room.Status = "ready";
            }

            await _context.SaveChangesAsync();
            return Ok(room);
        }

        [HttpPost("start")]
        public async Task<IActionResult> StartMatch([FromBody] StartMatchDto dto)
        {
            var code = dto.RoomCode.Trim().ToUpper();
            var room = await _context.DuelRooms.FindAsync(code);
            if (room == null) return NotFound(new { message = "Không tìm thấy phòng đấu!" });

            room.Status = "playing";
            await _context.SaveChangesAsync();
            return Ok(room);
        }

        [HttpPost("move")]
        public async Task<IActionResult> MakeMove([FromBody] CaroMoveDto dto)
        {
            var code = dto.RoomCode.Trim().ToUpper();
            var room = await _context.DuelRooms.FindAsync(code);
            if (room == null) return NotFound(new { message = "Không tìm thấy phòng đấu!" });

            room.LastMoveJson = System.Text.Json.JsonSerializer.Serialize(dto);
            room.CurrentTurn = dto.Player == 1 ? 2 : 1;
            await _context.SaveChangesAsync();

            return Ok(room);
        }

        [HttpPost("submit-result")]
        public async Task<IActionResult> SubmitResult([FromBody] SubmitDuelResultDto dto)
        {
            var code = dto.RoomCode.Trim().ToUpper();
            var room = await _context.DuelRooms.FindAsync(code);
            if (room == null) return NotFound(new { message = "Không tìm thấy phòng đấu!" });

            if (dto.UserId == room.HostId)
            {
                room.HostScore = dto.Score;
                room.HostTimeSeconds = dto.TimeSeconds;
            }
            else if (dto.UserId == room.GuestId)
            {
                room.GuestScore = dto.Score;
                room.GuestTimeSeconds = dto.TimeSeconds;
            }

            // Game đối kháng 1v1: Người đầu tiên hoàn thành ván đấu sẽ chiến thắng và kết thúc trận
            if (room.Status != "finished")
            {
                room.Status = "finished";
                room.WinnerId = dto.UserId;
            }

            await _context.SaveChangesAsync();
            return Ok(room);
        }

        [HttpGet("active")]
        public async Task<IActionResult> GetActiveRooms()
        {
            var rooms = await _context.DuelRooms
                .Where(r => r.Status == "waiting" || r.Status == "ready")
                .OrderByDescending(r => r.CreatedAt)
                .Take(10)
                .ToListAsync();
            return Ok(rooms);
        }
    }
}
