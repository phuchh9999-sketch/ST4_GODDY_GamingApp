using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Data;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProgressController : ControllerBase
    {
        private readonly GoddyDbContext _context;

        public ProgressController(GoddyDbContext context)
        {
            _context = context;
        }

        [HttpPost("save")]
        public async Task<IActionResult> SaveProgress([FromBody] SaveProgressDto dto)
        {
            var existing = await _context.GameProgresses
                .FirstOrDefaultAsync(p => p.UserId == dto.UserId && p.GameType == dto.GameType);

            if (existing != null)
            {
                existing.StateJson = dto.StateJson;
                existing.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                _context.GameProgresses.Add(new SavedGameProgress
                {
                    UserId = dto.UserId,
                    GameType = dto.GameType,
                    StateJson = dto.StateJson
                });
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã lưu tiến độ ván chơi lên máy chủ thành công!" });
        }

        [HttpGet("{userId}/{gameType}")]
        public async Task<IActionResult> GetProgress(string userId, string gameType)
        {
            var record = await _context.GameProgresses
                .FirstOrDefaultAsync(p => p.UserId == userId && p.GameType == gameType);

            if (record == null) return NotFound(new { message = "Chưa có tiến độ lưu cho game này" });
            return Ok(record);
        }

        [HttpDelete("{userId}/{gameType}")]
        public async Task<IActionResult> ClearProgress(string userId, string gameType)
        {
            var record = await _context.GameProgresses
                .FirstOrDefaultAsync(p => p.UserId == userId && p.GameType == gameType);

            if (record != null)
            {
                _context.GameProgresses.Remove(record);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Đã xóa tiến độ ván chơi!" });
        }
    }
}
