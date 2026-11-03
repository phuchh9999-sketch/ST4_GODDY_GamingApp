using System.ComponentModel.DataAnnotations;

namespace Goddy_Game_WebAPI.Models
{
    public class AppUser
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Avatar { get; set; } = "🤖";
        public int Exp { get; set; } = 100;
        public int GamesPlayed { get; set; } = 0;
        public int WinsCount { get; set; } = 0;
        public int RubikBestSeconds { get; set; } = 0;
        public int CaroBestScore { get; set; } = 0;
        public int SudokuBestSeconds { get; set; } = 0;
        public int PuzzleBestSeconds { get; set; } = 0;
        public string BadgesJson { get; set; } = "[\"Tân Thủ Goddy\",\"Cyber Rookie\"]";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class GameScoreRecord
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string UserId { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Avatar { get; set; } = "🎮";
        public string GameType { get; set; } = string.Empty; // rubik, caro, sudoku, slide_puzzle
        public int Score { get; set; } = 0;
        public int TimeSeconds { get; set; } = 0;
        public int Mistakes { get; set; } = 0;
        public bool IsWin { get; set; } = true;
        public string Difficulty { get; set; } = "Normal";
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    public class DuelRoomRecord
    {
        [Key]
        public string RoomCode { get; set; } = string.Empty;
        public string HostId { get; set; } = string.Empty;
        public string HostName { get; set; } = string.Empty;
        public string HostAvatar { get; set; } = "⚡";
        public string? GuestId { get; set; }
        public string? GuestName { get; set; }
        public string? GuestAvatar { get; set; }
        public string GameType { get; set; } = "caro";
        public string Difficulty { get; set; } = "Normal";
        public int Seed { get; set; } = 4242;
        public string Status { get; set; } = "waiting"; // waiting, ready, playing, finished
        public bool HostReady { get; set; } = false;
        public bool GuestReady { get; set; } = false;
        public int HostScore { get; set; } = 0;
        public int HostTimeSeconds { get; set; } = 0;
        public int GuestScore { get; set; } = 0;
        public int GuestTimeSeconds { get; set; } = 0;
        public string? WinnerId { get; set; }
        public string LastMoveJson { get; set; } = string.Empty;
        public int CurrentTurn { get; set; } = 1; // 1: Host (X), 2: Guest (O)
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class ChatMessageRecord
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string RoomId { get; set; } = "global";
        public string SenderId { get; set; } = string.Empty;
        public string SenderName { get; set; } = string.Empty;
        public string SenderAvatar { get; set; } = "👾";
        public string Text { get; set; } = string.Empty;
        public bool IsSticker { get; set; } = false;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    public class SavedGameProgress
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string UserId { get; set; } = string.Empty;
        public string GameType { get; set; } = string.Empty; // sudoku, slide_puzzle, caro, rubik
        public string StateJson { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
