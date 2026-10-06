using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentAssistant.API.Data;
using StudentAssistant.API.Models;
using StudentAssistant.API.Services;

namespace StudentAssistant.API.Controllers;

/// <summary>
/// Controller for managing chat messages
/// Handles CRUD operations for AI chat history
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ChatMessagesController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly GeminiService _geminiService;

    public ChatMessagesController(AppDbContext context, GeminiService geminiService)
    {
        _context = context;
        _geminiService = geminiService;
    }

    // GET: api/ChatMessages
    // Returns all chat messages ordered by CreatedAt ascending
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ChatMessage>>> GetMessages()
    {
        var messages = await _context.ChatMessages
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();
        return Ok(messages);
    }

    // POST: api/ChatMessages
    // Creates a new chat message (manual/sync mode - không dùng AI)
    [HttpPost]
    public async Task<ActionResult<ChatMessage>> PostMessage(ChatMessage message)
    {
        // Set CreatedAt if not provided
        if (message.CreatedAt == default)
        {
            message.CreatedAt = DateTime.Now;
        }

        _context.ChatMessages.Add(message);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetMessages), new { id = message.Id }, message);
    }

    // POST: api/ChatMessages/ask
    // Nhận câu hỏi từ user, gọi Gemini AI, lưu và trả về ChatMessage
    [HttpPost("ask")]
    public async Task<ActionResult<ChatMessage>> AskAI([FromBody] ChatRequest request)
    {
        // Kiểm tra message không rỗng
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { message = "Câu hỏi không được rỗng." });
        }

        // Gọi Gemini để lấy câu trả lời
        var aiResponse = await _geminiService.GetResponseAsync(request.Message);

        // Tạo ChatMessage với dữ liệu thật từ AI
        var chatMessage = new ChatMessage
        {
            Message = request.Message,
            Response = aiResponse,
            CreatedAt = DateTime.Now
        };

        // Lưu vào SQL Server
        _context.ChatMessages.Add(chatMessage);
        await _context.SaveChangesAsync();

        // Trả về ChatMessage đã tạo
        return Ok(chatMessage);
    }

    // DELETE: api/ChatMessages
    // Deletes all chat messages (Clear Chat)
    [HttpDelete]
    public async Task<IActionResult> DeleteAllMessages()
    {
        var messages = await _context.ChatMessages.ToListAsync();
        
        if (messages.Count == 0)
        {
            return NoContent();
        }

        _context.ChatMessages.RemoveRange(messages);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
