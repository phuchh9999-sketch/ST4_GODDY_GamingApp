using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Data;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly GoddyDbContext _context;

        public AuthController(GoddyDbContext context)
        {
            _context = context;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            if (await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower()))
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            var user = new AppUser
            {
                Email = dto.Email,
                Username = dto.Username,
                PasswordHash = dto.Password, // Simple hash/pwd for coursework demo
                Avatar = string.IsNullOrEmpty(dto.Avatar) ? "🤖" : dto.Avatar,
                Exp = 100,
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                user.Id,
                user.Email,
                user.Username,
                user.Avatar,
                user.Exp,
                user.GamesPlayed,
                user.WinsCount,
                user.RubikBestSeconds,
                user.CaroBestScore,
                user.SudokuBestSeconds,
                user.PuzzleBestSeconds,
                Token = "goddy_jwt_token_" + user.Id
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => 
                u.Email.ToLower() == dto.Email.ToLower() && u.PasswordHash == dto.Password);

            if (user == null)
            {
                // Fallback demo user for instructor quick testing
                if (dto.Email == "player@goddy.io" || dto.Email == "admin@goddy.io")
                {
                    user = new AppUser
                    {
                        Email = dto.Email,
                        Username = dto.Email.StartsWith("admin") ? "GoddyAdmin" : "CyberPlayer",
                        Avatar = "⚡",
                        Exp = 3200,
                        GamesPlayed = 15,
                        WinsCount = 12,
                        RubikBestSeconds = 24,
                        CaroBestScore = 1950,
                        SudokuBestSeconds = 145,
                        PuzzleBestSeconds = 28,
                    };
                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();
                }
                else
                {
                    return Unauthorized(new { message = "Email hoặc mật khẩu không chính xác!" });
                }
            }

            return Ok(new
            {
                user.Id,
                user.Email,
                user.Username,
                user.Avatar,
                user.Exp,
                user.GamesPlayed,
                user.WinsCount,
                user.RubikBestSeconds,
                user.CaroBestScore,
                user.SudokuBestSeconds,
                user.PuzzleBestSeconds,
                Token = "goddy_jwt_token_" + user.Id
            });
        }

        [HttpGet("profile/{id}")]
        public async Task<IActionResult> GetProfile(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound(new { message = "Không tìm thấy người chơi" });
            return Ok(user);
        }
    }
}
