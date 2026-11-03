using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Data;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private readonly GoddyDbContext _context;

        public ChatController(GoddyDbContext context)
        {
            _context = context;
        }

        [HttpGet("messages")]
        public async Task<IActionResult> GetMessages([FromQuery] string roomId = "global")
        {
            var msgs = await _context.ChatMessages
                .Where(m => m.RoomId == roomId)
                .OrderBy(m => m.Timestamp)
                .Take(50)
                .ToListAsync();

            return Ok(msgs);
        }

        [HttpPost("send")]
        public async Task<IActionResult> SendMessage([FromBody] SendChatDto dto)
        {
            var msg = new ChatMessageRecord
            {
                Id = !string.IsNullOrEmpty(dto.Id) ? dto.Id : Guid.NewGuid().ToString(),
                RoomId = dto.RoomId,
                SenderId = dto.SenderId,
                SenderName = dto.SenderName,
                SenderAvatar = dto.SenderAvatar,
                Text = dto.Text,
                IsSticker = dto.IsSticker,
                Timestamp = dto.Timestamp ?? DateTime.UtcNow
            };

            _context.ChatMessages.Add(msg);
            await _context.SaveChangesAsync();

            return Ok(msg);
        }
    }
}
