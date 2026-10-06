using System.Text;
using System.Text.Json;

namespace StudentAssistant.API.Services;

/// <summary>
/// Service để giao tiếp với Google Gemini API
/// Sử dụng REST API + HttpClient - không cần SDK bên thứ ba
/// </summary>
public class GeminiService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    
    // Model Gemini - dễ dàng thay đổi model name ở đây
    // gemini-3.5-flash-lite: model mới, nhanh, chi phí thấp, phù hợp cho demo
    private const string ModelName = "gemini-3.5-flash-lite";
    private const string BaseUrl = "https://generativelanguage.googleapis.com/v1beta/models";

    public GeminiService(HttpClient httpClient)
    {
        _httpClient = httpClient;
        
        // Đọc API key từ environment variable
        _apiKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY") ?? string.Empty;
        
        // Nếu không có API key, throw exception rõ ràng
        if (string.IsNullOrWhiteSpace(_apiKey))
        {
            throw new InvalidOperationException(
                "GEMINI_API_KEY chưa được cấu hình. " +
                "Vui lòng đặt biến môi trường GEMINI_API_KEY trên Windows."
            );
        }
    }

    /// <summary>
    /// Gửi câu hỏi tới Gemini và nhận câu trả lời dạng text
    /// </summary>
    /// <param name="prompt">Câu hỏi của user</param>
    /// <returns>Câu trả lời từ Gemini</returns>
    public async Task<string> GetResponseAsync(string prompt)
    {
        // Validate input
        if (string.IsNullOrWhiteSpace(prompt))
        {
            throw new ArgumentException("Prompt không được rỗng.", nameof(prompt));
        }

        // Build URL với API key (không log URL chứa key)
        var url = $"{BaseUrl}/{ModelName}:generateContent?key={_apiKey}";

        // Build request body theo format Gemini API
        var requestBody = new
        {
            contents = new[]
            {
                new
                {
                    parts = new[]
                    {
                        new { text = prompt }
                    }
                }
            },
            generationConfig = new
            {
                temperature = 0.7,
                maxOutputTokens = 2048
            }
        };

        // Serialize request body
        var jsonContent = JsonSerializer.Serialize(requestBody);
        var httpContent = new StringContent(jsonContent, Encoding.UTF8, "application/json");

        try
        {
            // Gửi POST request tới Gemini API
            var response = await _httpClient.PostAsync(url, httpContent);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                
                // Log error nhưng KHÔNG log API key
                Console.WriteLine($"[GeminiService] API returned error: {response.StatusCode}");
                
                throw new Exception($"Gemini API gặp lỗi: {response.StatusCode}");
            }

            // Parse response
            var responseContent = await response.Content.ReadAsStringAsync();
            var jsonResponse = JsonDocument.Parse(responseContent);
            var root = jsonResponse.RootElement;

            // Trích xuất text từ response
            // Cấu trúc: response.candidates[0].content.parts[0].text
            if (root.TryGetProperty("candidates", out var candidates) &&
                candidates.ValueKind == JsonValueKind.Array &&
                candidates.GetArrayLength() > 0)
            {
                var firstCandidate = candidates[0];
                if (firstCandidate.TryGetProperty("content", out var content) &&
                    content.TryGetProperty("parts", out var parts) &&
                    parts.ValueKind == JsonValueKind.Array &&
                    parts.GetArrayLength() > 0)
                {
                    var text = parts[0].GetProperty("text").GetString();
                    
                    if (!string.IsNullOrWhiteSpace(text))
                    {
                        return text;
                    }
                }
            }

            throw new Exception("Gemini không trả về nội dung hợp lệ.");
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"[GeminiService] HTTP Error: {ex.Message}");
            throw new Exception("Không thể kết nối tới Gemini API. Vui lòng kiểm tra kết nối internet.");
        }
    }
}
