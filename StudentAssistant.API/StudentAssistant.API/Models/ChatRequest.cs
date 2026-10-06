namespace StudentAssistant.API.Models;

/// <summary>
/// DTO for receiving chat message from Flutter app
/// </summary>
public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
}
