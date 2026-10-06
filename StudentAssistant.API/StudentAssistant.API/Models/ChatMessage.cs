namespace StudentAssistant.API.Models;

public class ChatMessage
{
    public int Id { get; set; }
    public string Message { get; set; } = string.Empty; // User's message/question
    public string Response { get; set; } = string.Empty; // AI assistant's response
    public DateTime CreatedAt { get; set; } = DateTime.Now; // Timestamp when message was created
}
