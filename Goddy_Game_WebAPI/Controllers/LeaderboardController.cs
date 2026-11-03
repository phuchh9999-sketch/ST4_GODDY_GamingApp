using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Data;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LeaderboardController : ControllerBase
    {
        private readonly GoddyDbContext _context;

        public LeaderboardController(GoddyDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetLeaderboard([FromQuery] string? gameType)
        {
            var query = _context.Scores.AsQueryable();
            if (!string.IsNullOrEmpty(gameType))
            {
                query = query.Where(s => s.GameType == gameType);
            }

            var entries = await query
                .OrderByDescending(s => s.Score)
                .Take(20)
                .ToListAsync();

            var ranked = entries.Select((s, index) => new
            {
                Rank = index + 1,
                UserId = s.UserId,
                Username = s.Username,
                Avatar = s.Avatar,
                Score = s.Score,
                TimeSeconds = s.TimeSeconds,
                Mistakes = s.Mistakes,
                GameType = s.GameType
            });

            return Ok(ranked);
        }

        [HttpPost("submit")]
        public async Task<IActionResult> SubmitScore([FromBody] SubmitScoreDto dto)
        {
            var record = new GameScoreRecord
            {
                UserId = dto.UserId,
                Username = dto.Username,
                Avatar = dto.Avatar,
                GameType = dto.GameType,
                Score = dto.Score,
                TimeSeconds = dto.TimeSeconds,
                Mistakes = dto.Mistakes,
                IsWin = dto.IsWin,
                Difficulty = dto.Difficulty
            };

            _context.Scores.Add(record);

            // Update user bests and exp
            var user = await _context.Users.FindAsync(dto.UserId);
            if (user != null)
            {
                user.GamesPlayed += 1;
                if (dto.IsWin) user.WinsCount += 1;
                user.Exp += (int)(dto.Score * 0.15);

                if (dto.GameType == "rubik")
                {
                    user.RubikBestSeconds = user.RubikBestSeconds == 0 
                        ? dto.TimeSeconds 
                        : Math.Min(user.RubikBestSeconds, dto.TimeSeconds);
                }
                else if (dto.GameType == "caro")
                {
                    user.CaroBestScore = Math.Max(user.CaroBestScore, dto.Score);
                }
                else if (dto.GameType == "sudoku")
                {
                    user.SudokuBestSeconds = user.SudokuBestSeconds == 0 
                        ? dto.TimeSeconds 
                        : Math.Min(user.SudokuBestSeconds, dto.TimeSeconds);
                }
                else if (dto.GameType == "slide_puzzle")
                {
                    user.PuzzleBestSeconds = user.PuzzleBestSeconds == 0 
                        ? dto.TimeSeconds 
                        : Math.Min(user.PuzzleBestSeconds, dto.TimeSeconds);
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã lưu kết quả thành công!", recordId = record.Id });
        }

        [HttpGet("history/{userId}")]
        public async Task<IActionResult> GetUserHistory(string userId)
        {
            var history = await _context.Scores
                .Where(s => s.UserId == userId)
                .OrderByDescending(s => s.Timestamp)
                .Take(30)
                .ToListAsync();

            return Ok(history);
        }
    }
}
