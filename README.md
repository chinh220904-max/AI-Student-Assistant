# AI Student Assistant – PRM393

> Tài liệu hướng dẫn **xây dựng, cài đặt, chạy và demo** dự án AI Student Assistant từ đầu đến cuối.  
> Dự án minh họa hai nội dung chính: **Database/REST API** và **Chat AI**.

---

## 1. Tổng quan dự án

**AI Student Assistant** là ứng dụng Flutter gồm hai chức năng:

- **Quản lý môn học (Subject Management):** xem, thêm, sửa, xóa môn học.
- **AI Assistant:** gửi câu hỏi tới Google Gemini, nhận câu trả lời, lưu và tải lại lịch sử chat từ SQL Server.

### Kiến trúc

```text
Flutter Mobile App
        |
        | HTTP / REST API / JSON
        v
ASP.NET Core Web API (.NET 8)
        |
        +---- Entity Framework Core ----> SQL Server LocalDB
        |
        +---- GeminiService ------------> Google Gemini API
```

**Nguyên tắc quan trọng:** Flutter không truy cập trực tiếp SQL Server và cũng không giữ Gemini API key. Mọi thao tác đi qua ASP.NET Core Backend.

---

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Mobile | Flutter / Dart |
| Backend | ASP.NET Core Web API (.NET 8) |
| ORM | Entity Framework Core 8 |
| Database | SQL Server LocalDB |
| AI | Google Gemini REST API |
| Giao tiếp | HTTP REST API + JSON |
| Test API | Swagger |
| Source control | Git / GitHub |

Backend sử dụng các package chính:

```text
Microsoft.EntityFrameworkCore.SqlServer 8.0.10
Microsoft.EntityFrameworkCore.Design 8.0.10
Swashbuckle.AspNetCore 6.6.2
```

Flutter sử dụng:

```text
http: ^1.2.2
```

---

## 3. Cấu trúc source code

```text
AI-Student-Assistant/
|
├── StudentAssistant.API/
│   └── StudentAssistant.API/
│       ├── Controllers/
│       │   ├── SubjectsController.cs
│       │   └── ChatMessagesController.cs
│       ├── Data/
│       │   └── AppDbContext.cs
│       ├── Models/
│       │   ├── Subject.cs
│       │   ├── ChatMessage.cs
│       │   └── ChatRequest.cs
│       ├── Services/
│       │   └── GeminiService.cs
│       ├── Migrations/
│       ├── Properties/
│       │   └── launchSettings.json
│       ├── Program.cs
│       ├── appsettings.json
│       └── StudentAssistant.API.csproj
│
└── student_assistant_flutter/
    ├── android/
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   │   ├── subject.dart
    │   │   └── chat_message.dart
    │   ├── services/
    │   │   ├── subject_service.dart
    │   │   └── chat_service.dart
    │   └── screens/
    │       ├── home_screen.dart
    │       ├── subjects_screen.dart
    │       ├── subject_form_screen.dart
    │       └── chat_screen.dart
    └── pubspec.yaml
```

---

# PHẦN A – XÂY DỰNG BACKEND VÀ DATABASE

## 4. Chuẩn bị môi trường

Cần cài:

1. **.NET 8 SDK**
2. **Visual Studio 2022** hoặc IDE hỗ trợ .NET
3. **SQL Server LocalDB**
4. **SQL Server Management Studio (SSMS)** – để xem database trực quan
5. **Flutter SDK**
6. **Android Studio + Android Emulator**
7. Tài khoản Google để tạo Gemini API key

Kiểm tra .NET:

```bash
dotnet --version
```

Kiểm tra Flutter:

```bash
flutter doctor
```

---

## 5. Tạo ASP.NET Core Web API

Có thể tạo bằng Visual Studio hoặc command line:

```bash
dotnet new webapi -n StudentAssistant.API
cd StudentAssistant.API
```

Project hiện tại target:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### Cài Entity Framework Core cho SQL Server

```bash
dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version 8.0.10
dotnet add package Microsoft.EntityFrameworkCore.Design --version 8.0.10
dotnet add package Swashbuckle.AspNetCore --version 6.6.2
```

Nếu chưa có EF CLI:

```bash
dotnet tool install --global dotnet-ef
```

---

## 6. Tạo Model `Subject`

Tạo file:

```text
Models/Subject.cs
```

```csharp
namespace StudentAssistant.API.Models;

public class Subject
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
```

Ý nghĩa:

- `Id`: khóa chính.
- `Name`: tên môn học.
- `Description`: mô tả môn học.

---

## 7. Tạo Model cho Chat AI

### `Models/ChatMessage.cs`

```csharp
namespace StudentAssistant.API.Models;

public class ChatMessage
{
    public int Id { get; set; }
    public string Message { get; set; } = string.Empty;
    public string Response { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}
```

Bảng `ChatMessages` lưu cả câu hỏi và câu trả lời AI để có thể tải lại lịch sử.

### `Models/ChatRequest.cs`

```csharp
namespace StudentAssistant.API.Models;

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
}
```

Đây là DTO nhận câu hỏi từ Flutter tại endpoint `/api/ChatMessages/ask`.

---

## 8. Tạo `AppDbContext`

Tạo:

```text
Data/AppDbContext.cs
```

```csharp
using Microsoft.EntityFrameworkCore;
using StudentAssistant.API.Models;

namespace StudentAssistant.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Subject> Subjects { get; set; }
    public DbSet<ChatMessage> ChatMessages { get; set; }
}
```

`AppDbContext` là cầu nối giữa Entity Framework Core và SQL Server.

```text
Subject      <-> Subjects table
ChatMessage  <-> ChatMessages table
```

---

## 9. Cấu hình SQL Server

Trong:

```text
appsettings.json
```

project sử dụng:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=StudentAssistantDb;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

Ý nghĩa:

- Server: `(localdb)\MSSQLLocalDB`
- Database: `StudentAssistantDb`
- Windows Authentication được sử dụng thông qua `Trusted_Connection=True`.

### Đăng ký DbContext trong `Program.cs`

```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")));
```

Luồng:

```text
appsettings.json
       |
       v
Program.cs
       |
       v
AppDbContext
       |
       v
SQL Server
```

---

## 10. Tạo database bằng Migration

Sau khi tạo Models và DbContext:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

EF Core sẽ tạo database:

```text
StudentAssistantDb
```

và các bảng:

```text
dbo.Subjects
dbo.ChatMessages
dbo.__EFMigrationsHistory
```

`__EFMigrationsHistory` là bảng EF Core dùng để theo dõi migration.

### Kiểm tra bằng SSMS

Mở SQL Server Management Studio và kết nối:

```text
Server type:     Database Engine
Server name:     (localdb)\MSSQLLocalDB
Authentication:  Windows Authentication
```

Sau đó:

```text
Databases
└── StudentAssistantDb
    └── Tables
        ├── dbo.Subjects
        ├── dbo.ChatMessages
        └── dbo.__EFMigrationsHistory
```

Có thể chạy:

```sql
USE StudentAssistantDb;

SELECT * FROM Subjects;

SELECT * FROM ChatMessages
ORDER BY CreatedAt DESC;
```

---

## 11. Xây dựng REST API CRUD cho Subject

File:

```text
Controllers/SubjectsController.cs
```

Controller được khai báo:

```csharp
[ApiController]
[Route("api/[controller]")]
public class SubjectsController : ControllerBase
```

Do tên controller là `SubjectsController`, route trở thành:

```text
/api/Subjects
```

### Các endpoint

| Method | Endpoint | Chức năng |
|---|---|---|
| GET | `/api/Subjects` | Lấy toàn bộ môn học |
| GET | `/api/Subjects/{id}` | Lấy môn học theo ID |
| POST | `/api/Subjects` | Thêm môn học |
| PUT | `/api/Subjects/{id}` | Cập nhật môn học |
| DELETE | `/api/Subjects/{id}` | Xóa môn học |

Ví dụ lấy dữ liệu:

```csharp
var subjects = await _context.Subjects.ToListAsync();
return Ok(subjects);
```

Ví dụ thêm:

```csharp
_context.Subjects.Add(subject);
await _context.SaveChangesAsync();
```

Ví dụ xóa:

```csharp
_context.Subjects.Remove(subject);
await _context.SaveChangesAsync();
```

`SaveChangesAsync()` là bước ghi thay đổi xuống SQL Server.

---

## 12. Cấu hình Backend trong `Program.cs`

Các phần chính của project:

```csharp
builder.Services.AddDbContext<AppDbContext>(...);
builder.Services.AddHttpClient<GeminiService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
```

Project cũng cấu hình CORS cho demo Flutter:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});
```

và:

```csharp
app.UseCors("AllowFlutter");
app.MapControllers();
```

> `AllowAnyOrigin()` phù hợp cho bài demo/lớp học. Với production nên giới hạn origin cụ thể.

---

## 13. Chạy và test Backend

Project hiện tại có HTTP profile:

```text
http://localhost:5177
```

Chạy:

```bash
dotnet run
```

Khi thành công sẽ thấy:

```text
Now listening on: http://localhost:5177
Application started.
```

Swagger được bật trong Development. Có thể dùng Swagger để test API trước khi kết nối Flutter.

Ví dụ:

```text
GET /api/Subjects
POST /api/Subjects
PUT /api/Subjects/{id}
DELETE /api/Subjects/{id}
```

---

# PHẦN B – XÂY DỰNG FLUTTER VÀ KẾT NỐI DATABASE QUA API

## 14. Tạo Flutter project

```bash
flutter create student_assistant_flutter
cd student_assistant_flutter
```

Cài package HTTP:

```bash
flutter pub add http
```

Project hiện tại sử dụng:

```yaml
http: ^1.2.2
```

---

## 15. Tạo Flutter Models

### `lib/models/subject.dart`

Model Flutter tương ứng JSON của backend:

```dart
class Subject {
  final int id;
  final String name;
  final String description;

  Subject({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
```

`fromJson()`:

```text
JSON từ Backend -> Dart Object
```

`toJson()`:

```text
Dart Object -> JSON gửi Backend
```

---

## 16. Tạo `SubjectService`

File:

```text
lib/services/subject_service.dart
```

Base URL:

```dart
static const String baseUrl =
    'http://10.0.2.2:5177/api/Subjects';
```

### Tại sao dùng `10.0.2.2`?

Backend chạy trên Windows:

```text
http://localhost:5177
```

Nhưng `localhost` bên trong Android Emulator chính là máy Android ảo.

Android Emulator dùng địa chỉ đặc biệt:

```text
10.0.2.2
```

để truy cập localhost của máy host.

Do đó:

```text
Windows:          http://localhost:5177
Android Emulator: http://10.0.2.2:5177
```

### GET

```dart
final response = await http.get(Uri.parse(baseUrl));
```

### POST

```dart
final response = await http.post(
  Uri.parse(baseUrl),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(subject.toJson()),
);
```

### PUT

```dart
final response = await http.put(
  Uri.parse('$baseUrl/${subject.id}'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(subject.toJson()),
);
```

### DELETE

```dart
final response = await http.delete(
  Uri.parse('$baseUrl/$id'),
);
```

Luồng CRUD:

```text
Flutter UI
   |
   v
SubjectService
   |
   v
SubjectsController
   |
   v
AppDbContext / EF Core
   |
   v
SQL Server
```

---

## 17. Cho phép Android truy cập Internet/HTTP

File:

```text
android/app/src/main/AndroidManifest.xml
```

Project có:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

và trong `<application>`:

```xml
android:usesCleartextTraffic="true"
```

`INTERNET` cho phép app gọi API.

`usesCleartextTraffic="true"` cho phép HTTP trong môi trường demo hiện tại.

---

## 18. Xây dựng màn hình Subject

Project chia UI thành:

```text
home_screen.dart
subjects_screen.dart
subject_form_screen.dart
```

- `home_screen.dart`: màn hình chính.
- `subjects_screen.dart`: hiển thị danh sách và thao tác CRUD.
- `subject_form_screen.dart`: form thêm/sửa môn học.

Khi UI cần dữ liệu, nó gọi `SubjectService`, không truy cập SQL Server trực tiếp.

---

# PHẦN C – TÍCH HỢP GOOGLE GEMINI AI

## 19. Tạo Gemini API key

Tạo API key từ Google AI Studio.

**Không đưa API key thật vào:**

- source code;
- Flutter;
- `appsettings.json`;
- GitHub;
- slide;
- ảnh demo.

Project dùng biến môi trường Windows:

```text
GEMINI_API_KEY
```

### Thiết lập bằng giao diện Windows

1. Search **Environment Variables**.
2. Chọn **Edit the system environment variables**.
3. Chọn **Environment Variables...**
4. Trong **User variables**, chọn **New...**
5. Variable name:

```text
GEMINI_API_KEY
```

6. Variable value: API key thật của bạn.
7. OK và mở lại terminal/IDE nếu cần.

Kiểm tra mà không in key ra màn hình:

```bat
if defined GEMINI_API_KEY (echo Gemini Key: OK) else (echo Gemini Key: NOT FOUND)
```

Kết quả mong đợi:

```text
Gemini Key: OK
```

---

## 20. Đăng ký `GeminiService`

Trong `Program.cs`:

```csharp
builder.Services.AddHttpClient<GeminiService>();
```

ASP.NET Core Dependency Injection sẽ tạo `HttpClient` và truyền vào `GeminiService`.

---

## 21. `GeminiService.cs` hoạt động thế nào?

File:

```text
Services/GeminiService.cs
```

### Đọc API key

```csharp
_apiKey =
    Environment.GetEnvironmentVariable("GEMINI_API_KEY")
    ?? string.Empty;
```

Nếu không có key:

```csharp
throw new InvalidOperationException(
    "GEMINI_API_KEY chưa được cấu hình.");
```

### Model và endpoint trong source hiện tại

```csharp
private const string ModelName = "gemini-3.5-flash-lite";
private const string BaseUrl =
    "https://generativelanguage.googleapis.com/v1beta/models";
```

URL request được tạo theo dạng:

```text
{BaseUrl}/{ModelName}:generateContent?key={GEMINI_API_KEY}
```

> Model/API có thể thay đổi theo thời gian. Nếu Google ngừng hỗ trợ model hiện tại, thay `ModelName` bằng model tương thích với tài khoản/API đang sử dụng.

### Request body

Service gửi nội dung theo cấu trúc:

```json
{
  "contents": [
    {
      "parts": [
        {
          "text": "Câu hỏi của người dùng"
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 2048
  }
}
```

### Gửi request

```csharp
var response =
    await _httpClient.PostAsync(url, httpContent);
```

### Đọc câu trả lời

Project lấy text từ cấu trúc:

```text
candidates[0]
  -> content
      -> parts[0]
          -> text
```

GeminiService sau đó trả chuỗi text về Controller.

---

## 22. Tạo API Chat AI

File:

```text
Controllers/ChatMessagesController.cs
```

Controller nhận cả:

```csharp
AppDbContext
GeminiService
```

qua Dependency Injection.

### Lấy lịch sử

```text
GET /api/ChatMessages
```

Dữ liệu được sắp theo `CreatedAt`:

```csharp
var messages = await _context.ChatMessages
    .OrderBy(m => m.CreatedAt)
    .ToListAsync();
```

### Hỏi AI

```text
POST /api/ChatMessages/ask
```

Flutter gửi:

```json
{
  "message": "Giải thích StatefulWidget trong Flutter là gì?"
}
```

Controller:

1. kiểm tra câu hỏi;
2. gọi `GeminiService`;
3. nhận AI response;
4. tạo `ChatMessage`;
5. lưu vào SQL Server;
6. trả JSON về Flutter.

Phần quan trọng:

```csharp
var aiResponse =
    await _geminiService.GetResponseAsync(request.Message);

var chatMessage = new ChatMessage
{
    Message = request.Message,
    Response = aiResponse,
    CreatedAt = DateTime.Now
};

_context.ChatMessages.Add(chatMessage);
await _context.SaveChangesAsync();

return Ok(chatMessage);
```

### Xóa lịch sử

```text
DELETE /api/ChatMessages
```

Controller dùng:

```csharp
_context.ChatMessages.RemoveRange(messages);
await _context.SaveChangesAsync();
```

---

## 23. Tạo Flutter `ChatMessage`

File:

```text
lib/models/chat_message.dart
```

```dart
class ChatMessage {
  final int id;
  final String message;
  final String response;
  final DateTime createdAt;

  // ...
}
```

Model này tương ứng entity `ChatMessage` của Backend.

---

## 24. Tạo `ChatService`

File:

```text
lib/services/chat_service.dart
```

Base URL:

```dart
static const String baseUrl =
    'http://10.0.2.2:5177/api/ChatMessages';
```

### Load lịch sử

```dart
http.get(Uri.parse(baseUrl))
```

### Hỏi Gemini thông qua Backend

```dart
final response = await http.post(
  Uri.parse('$baseUrl/ask'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'message': message}),
);
```

Điểm quan trọng:

```text
Flutter KHÔNG gọi Gemini trực tiếp.
```

Flutter chỉ biết Backend:

```text
Flutter
   |
   v
POST /api/ChatMessages/ask
   |
   v
ASP.NET Core
   |
   v
GeminiService
   |
   v
Gemini API
```

### Xóa lịch sử

```dart
http.delete(Uri.parse(baseUrl))
```

---

## 25. Toàn bộ flow Chat AI

Ví dụ người dùng hỏi:

```text
Giải thích StatefulWidget trong Flutter là gì?
```

Luồng:

```text
1. User nhập câu hỏi
          |
          v
2. chat_screen.dart
          |
          v
3. ChatService.askAI()
          |
          v
4. POST /api/ChatMessages/ask
          |
          v
5. ChatMessagesController
          |
          v
6. GeminiService.GetResponseAsync()
          |
          v
7. Google Gemini API
          |
          v
8. Gemini trả AI response
          |
          v
9. Controller tạo ChatMessage
          |
          v
10. EF Core lưu ChatMessage vào SQL Server
          |
          v
11. Backend trả JSON
          |
          v
12. Flutter hiển thị câu trả lời
```

Đây là flow quan trọng nhất khi giải thích phần Chat AI.

---

# PHẦN D – CHẠY TOÀN BỘ DỰ ÁN

## 26. Clone source

```bash
git clone https://github.com/chinh220904-max/AI-Student-Assistant.git
cd AI-Student-Assistant
```

---

## 27. Chạy Backend

Di chuyển tới thư mục chứa `.csproj`, ví dụ:

```bat
cd StudentAssistant.API\StudentAssistant.API
```

Restore/build:

```bash
dotnet restore
dotnet build
```

Đảm bảo database đã được tạo:

```bash
dotnet ef database update
```

Kiểm tra API key:

```bat
if defined GEMINI_API_KEY (echo Gemini Key: OK) else (echo Gemini Key: NOT FOUND)
```

Chạy:

```bash
dotnet run
```

Mong đợi:

```text
Now listening on: http://localhost:5177
```

**Giữ cửa sổ backend đang chạy trong lúc dùng Flutter.**

---

## 28. Chạy Flutter

Mở terminal khác:

```bat
cd student_assistant_flutter
flutter pub get
flutter analyze
flutter run
```

Chọn Android Emulator.

Flutter service đã cấu hình:

```text
http://10.0.2.2:5177
```

nên Backend phải chạy ở port `5177`.

---

# PHẦN E – KIỂM THỬ

## 29. Test Subject CRUD

### READ

Mở **Quản lý môn học**.

App gọi:

```text
GET /api/Subjects
```

### CREATE

Thêm ví dụ:

```text
Name: PRM394
Description: Cross Platform Mobile Development
```

App gọi:

```text
POST /api/Subjects
```

### UPDATE

Sửa description.

App gọi:

```text
PUT /api/Subjects/{id}
```

### DELETE

Xóa môn vừa tạo.

App gọi:

```text
DELETE /api/Subjects/{id}
```

Có thể mở SSMS và chạy:

```sql
SELECT * FROM Subjects;
```

để chứng minh dữ liệu thật đã thay đổi trong SQL Server.

---

## 30. Test Chat AI

Mở **AI Assistant** và hỏi:

```text
Giải thích StatefulWidget trong Flutter là gì?
```

Khi thành công:

```text
Flutter
✓
Backend
✓
Gemini
✓
SQL Server
✓
```

Thoát màn Chat rồi vào lại. Lịch sử vẫn xuất hiện vì:

```text
GET /api/ChatMessages
```

đọc dữ liệu từ SQL Server.

Kiểm tra bằng SSMS:

```sql
SELECT * FROM ChatMessages
ORDER BY CreatedAt DESC;
```

Sau đó bấm icon thùng rác để test:

```text
DELETE /api/ChatMessages
```

---

# PHẦN F – GIẢI THÍCH NHỮNG ĐIỂM QUAN TRỌNG

## 31. Tại sao Flutter không kết nối SQL Server trực tiếp?

Kiến trúc đúng của project:

```text
Flutter -> REST API -> ASP.NET Core -> EF Core -> SQL Server
```

Backend chịu trách nhiệm nghiệp vụ và database. Điều này giúp tách frontend/backend và tránh để thông tin kết nối database trong ứng dụng client.

---

## 32. Tại sao không gọi Gemini trực tiếp từ Flutter?

Nếu gọi trực tiếp:

```text
Flutter -> Gemini
```

API key có nguy cơ phải nằm trong ứng dụng client.

Project sử dụng:

```text
Flutter -> ASP.NET Core -> Gemini
```

Key chỉ được Backend đọc từ:

```text
GEMINI_API_KEY
```

trên máy chạy Backend.

---

## 33. REST API đóng vai trò gì?

REST API là lớp giao tiếp giữa Flutter và ASP.NET Core.

```text
GET     -> đọc dữ liệu
POST    -> tạo/gửi dữ liệu
PUT     -> cập nhật
DELETE  -> xóa
```

Dữ liệu trao đổi ở dạng JSON.

---

## 34. Entity Framework Core đóng vai trò gì?

EF Core là ORM giúp Backend thao tác với SQL Server thông qua C# entity và `DbContext`.

Ví dụ:

```csharp
_context.Subjects.Add(subject);
await _context.SaveChangesAsync();
```

thay vì Flutter hoặc Controller phải tự quản lý kết nối database trực tiếp.

---

## 35. Dependency Injection trong project

ASP.NET Core đăng ký:

```csharp
builder.Services.AddDbContext<AppDbContext>(...);
builder.Services.AddHttpClient<GeminiService>();
```

Sau đó Controller nhận dependency:

```text
SubjectsController
    -> AppDbContext

ChatMessagesController
    -> AppDbContext
    -> GeminiService
```

Điều này giúp các thành phần có trách nhiệm rõ ràng.

---

# PHẦN G – LỖI THƯỜNG GẶP

## 36. Flutter không kết nối Backend

### Kiểm tra Backend

Phải thấy:

```text
Now listening on: http://localhost:5177
```

### Kiểm tra URL Flutter

Android Emulator phải dùng:

```text
http://10.0.2.2:5177
```

không dùng:

```text
http://localhost:5177
```

---

## 37. `GEMINI_API_KEY chưa được cấu hình`

Kiểm tra:

```bat
if defined GEMINI_API_KEY (echo Gemini Key: OK) else (echo Gemini Key: NOT FOUND)
```

Nếu vừa tạo Environment Variable, đóng và mở lại terminal/IDE rồi chạy Backend lại.

---

## 38. Database chưa xuất hiện

Chạy trong Backend:

```bash
dotnet ef database update
```

Sau đó refresh **Databases** trong SSMS.

Kết nối SSMS:

```text
(localdb)\MSSQLLocalDB
```

---

## 39. Android chặn HTTP

Kiểm tra `AndroidManifest.xml` có:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

và:

```xml
android:usesCleartextTraffic="true"
```

---

## 40. Emulator bị đen hoặc không ổn định

Thử theo thứ tự:

```text
1. Stop Flutter
2. Kiểm tra Android Home
3. Run Flutter lại
4. Cold Boot emulator nếu cần
```

Kiểm tra ADB:

```bat
E:\Android\platform-tools\adb.exe devices
```

Thiết bị phải ở trạng thái:

```text
device
```

Đường dẫn ADB có thể khác tùy máy.

---

## 41. Warning HTTPS redirect

Nếu chạy HTTP profile `5177`, có thể gặp warning liên quan HTTPS redirect.

Trong bài demo hiện tại, Flutter đang chủ động gọi:

```text
http://10.0.2.2:5177
```

Nếu API vẫn hoạt động bình thường, warning này không ngăn luồng demo HTTP. Với production cần cấu hình HTTPS đúng cách.

---

# PHẦN H – KỊCH BẢN DEMO

## 42. Chuẩn bị trước khi demo

1. Mở SQL Server/SSMS.
2. Mở Backend terminal.
3. Kiểm tra `GEMINI_API_KEY`.
4. Chạy `dotnet run`.
5. Mở Android Emulator.
6. Chạy Flutter.
7. Mở sẵn GitHub/README nếu cần QR.

---

## 43. Demo Database

Trình tự:

```text
1. Mở Quản lý môn học
2. Hiển thị danh sách
3. Thêm một Subject
4. Sửa Subject
5. Mở SSMS -> SELECT * FROM Subjects
6. Chứng minh dữ liệu được lưu thật
7. Xóa Subject
```

Giải thích:

> Flutter gửi HTTP request tới ASP.NET Core REST API. Backend dùng Entity Framework Core thao tác với SQL Server và trả JSON về Flutter.

---

## 44. Demo Chat AI

Trình tự:

```text
1. Mở AI Assistant
2. Nhập câu hỏi
3. Gemini trả lời
4. Mở SSMS -> ChatMessages
5. Cho thấy Message + Response đã được lưu
6. Thoát/vào lại Chat để chứng minh history
7. Clear Chat nếu cần
```

Giải thích:

> Flutter không gọi Gemini trực tiếp. Câu hỏi được gửi tới Backend. GeminiService đọc API key từ Environment Variable, gọi Gemini REST API, sau đó Backend lưu câu hỏi và câu trả lời vào SQL Server rồi trả kết quả về Flutter.

---

# PHẦN I – CHECKLIST KẾT QUẢ DỰ ÁN

Dự án đã được kiểm thử với các luồng chính:

- [x] ASP.NET Core Backend chạy
- [x] SQL Server LocalDB kết nối
- [x] Entity Framework Core Migration
- [x] GET Subject
- [x] POST Subject
- [x] PUT Subject
- [x] DELETE Subject
- [x] Flutter kết nối Backend
- [x] Backend kết nối Gemini
- [x] Gemini trả response
- [x] ChatMessage lưu SQL Server
- [x] Load lại lịch sử chat
- [x] Xóa lịch sử chat
- [x] End-to-end Flutter -> Backend -> Gemini/SQL Server -> Flutter

---

## 45. Source code

GitHub Repository:

https://github.com/chinh220904-max/AI-Student-Assistant

---

## 46. Tóm tắt để ghi nhớ

### Database

```text
Flutter
-> SubjectService
-> SubjectsController
-> AppDbContext / EF Core
-> SQL Server
```

### Chat AI

```text
Flutter
-> ChatService
-> ChatMessagesController
-> GeminiService
-> Google Gemini API
-> ChatMessagesController
-> SQL Server
-> Flutter
```

### API key

```text
Windows Environment Variable
-> GEMINI_API_KEY
-> GeminiService
```

### Android Emulator

```text
Windows Backend:
localhost:5177

Flutter Android Emulator:
10.0.2.2:5177
```

---

**AI Student Assistant – PRM393**
