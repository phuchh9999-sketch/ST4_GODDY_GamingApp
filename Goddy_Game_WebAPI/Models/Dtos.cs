namespace Goddy_Game_WebAPI.Models
{
    public class RegisterDto
    {
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Avatar { get; set; } = "🤖";
    }

    public class LoginDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class SubmitScoreDto
    {
        public string UserId { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Avatar { get; set; } = "🎮";
        public string GameType { get; set; } = string.Empty;
        public int Score { get; set; } = 0;
        public int TimeSeconds { get; set; } = 0;
        public int Mistakes { get; set; } = 0;
        public bool IsWin { get; set; } = true;
        public string Difficulty { get; set; } = "Normal";
    }

    public class CreateRoomDto
    {
        public string? RoomCode { get; set; }
        public string HostId { get; set; } = string.Empty;
        public string HostName { get; set; } = string.Empty;
        public string HostAvatar { get; set; } = "⚡";
        public string GameType { get; set; } = "caro";
        public string Difficulty { get; set; } = "Normal";
        public int? Seed { get; set; }
    }

    public class JoinRoomDto
    {
        public string RoomCode { get; set; } = string.Empty;
        public string GuestId { get; set; } = string.Empty;
        public string GuestName { get; set; } = string.Empty;
        public string GuestAvatar { get; set; } = "🎮";
    }

    public class ToggleReadyDto
    {
        public string RoomCode { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public bool IsReady { get; set; }
    }

    public class StartMatchDto
    {
        public string RoomCode { get; set; } = string.Empty;
    }

    public class SubmitDuelResultDto
    {
        public string RoomCode { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public int Score { get; set; }
        public int TimeSeconds { get; set; }
        public int Mistakes { get; set; }
    }

    public class SendChatDto
    {
        public string? Id { get; set; }
        public string RoomId { get; set; } = "global";
        public string SenderId { get; set; } = string.Empty;
        public string SenderName { get; set; } = string.Empty;
        public string SenderAvatar { get; set; } = "👾";
        public string Text { get; set; } = string.Empty;
        public bool IsSticker { get; set; } = false;
        public DateTime? Timestamp { get; set; }
    }

    public class CaroMoveDto
    {
        public string RoomCode { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public int Row { get; set; }
        public int Col { get; set; }
        public int Player { get; set; } // 1: X (Host), 2: O (Guest)
        public string? Skill { get; set; } // null, "swap", "emp"
        public int? SwapR1 { get; set; }
        public int? SwapC1 { get; set; }
        public int? SwapR2 { get; set; }
        public int? SwapC2 { get; set; }
    }

    public class SaveProgressDto
    {
        public string UserId { get; set; } = string.Empty;
        public string GameType { get; set; } = string.Empty;
        public string StateJson { get; set; } = string.Empty;
    }
}
