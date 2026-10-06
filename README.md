# AI Student Assistant – PRM393

## Tổng quan

**AI Student Assistant** là ứng dụng di động Flutter được phát triển cho môn **PRM393**. Dự án minh họa hai nội dung chính:

1. **Tích hợp Database** thông qua REST API tự xây dựng bằng ASP.NET Core và kết nối với SQL Server.
2. **Tích hợp Chat AI** thông qua Google Gemini, đồng thời lưu lịch sử trò chuyện vào SQL Server.

Ứng dụng mobile được phát triển bằng Flutter/Dart. Backend sử dụng ASP.NET Core Web API (.NET 8), Entity Framework Core và SQL Server LocalDB.

---

## Chức năng chính

### 1. Quản lý môn học

Ứng dụng hỗ trợ đầy đủ các thao tác CRUD đối với môn học:

- Xem danh sách môn học
- Thêm môn học mới
- Chỉnh sửa môn học
- Xóa môn học
- Kéo xuống để tải lại danh sách
- Hiển thị trạng thái loading và thông báo lỗi

### 2. AI Assistant

Chức năng AI Assistant cho phép người dùng:

- Đặt câu hỏi trực tiếp từ ứng dụng Flutter
- Gửi câu hỏi đến ASP.NET Core backend
- Nhận câu trả lời thật từ Google Gemini
- Lưu câu hỏi và phản hồi AI vào SQL Server
- Tải lại lịch sử chat khi mở lại màn hình AI Assistant
- Xóa toàn bộ lịch sử chat

---

## Công nghệ sử dụng

### Frontend

- Flutter
- Dart
- Package `http`
- Material 3

### Backend

- ASP.NET Core Web API (.NET 8)
- Entity Framework Core 8
- SQL Server / SQL Server LocalDB
- Swagger / OpenAPI
- `HttpClient` để tích hợp Gemini REST API

### AI

- Google Gemini API
- Model được cấu hình trong backend: `gemini-3.5-flash-lite`

---

## Kiến trúc hệ thống

### Luồng Database

```text
Flutter App
    |
    | HTTP / JSON
    v
ASP.NET Core REST API
    |
    | Entity Framework Core
    v
SQL Server
```

### Luồng Chat AI

```text
Flutter App
    |
    | POST /api/ChatMessages/ask
    v
ASP.NET Core Web API
    |
    | Gemini REST API
    v
Google Gemini
    |
    | AI response
    v
ASP.NET Core Web API
    |
    | Lưu ChatMessage
    v
SQL Server
    |
    v
Flutter App
```

Gemini API key chỉ được lưu trên máy chạy backend dưới dạng **Environment Variable**. API key không được lưu trong source code Flutter và không được commit lên repository.

---

## Cấu trúc Database

Dự án sử dụng database:

```text
StudentAssistantDb
```

### Bảng Subjects

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| Id | int | Khóa chính, tự tăng |
| Name | string | Tên môn học |
| Description | string | Mô tả môn học |

### Bảng ChatMessages

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| Id | int | Khóa chính, tự tăng |
| Message | string | Câu hỏi của người dùng |
| Response | string | Phản hồi từ Gemini |
| CreatedAt | DateTime | Thời gian tạo tin nhắn |

---

## API Endpoints

### Subjects

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/api/Subjects` | Lấy toàn bộ môn học |
| GET | `/api/Subjects/{id}` | Lấy một môn học theo ID |
| POST | `/api/Subjects` | Tạo môn học mới |
| PUT | `/api/Subjects/{id}` | Cập nhật môn học |
| DELETE | `/api/Subjects/{id}` | Xóa môn học |

### Chat Messages

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/api/ChatMessages` | Lấy lịch sử chat |
| POST | `/api/ChatMessages` | Lưu một chat message thủ công |
| POST | `/api/ChatMessages/ask` | Gửi câu hỏi đến Gemini và lưu kết quả |
| DELETE | `/api/ChatMessages` | Xóa toàn bộ lịch sử chat |

---

## Cấu trúc project

### Backend

```text
StudentAssistant.API/
├── Controllers/
│   ├── SubjectsController.cs
│   └── ChatMessagesController.cs
├── Data/
│   └── AppDbContext.cs
├── Models/
│   ├── Subject.cs
│   ├── ChatMessage.cs
│   └── ChatRequest.cs
├── Services/
│   └── GeminiService.cs
├── Migrations/
├── Program.cs
├── appsettings.json
└── StudentAssistant.API.csproj
```

### Flutter

```text
lib/
├── main.dart
├── models/
│   ├── subject.dart
│   └── chat_message.dart
├── services/
│   ├── subject_service.dart
│   └── chat_service.dart
└── screens/
    ├── home_screen.dart
    ├── subjects_screen.dart
    ├── subject_form_screen.dart
    └── chat_screen.dart
```

---

## Yêu cầu môi trường

Trước khi chạy project, cần cài đặt:

- .NET 8 SDK
- SQL Server LocalDB hoặc SQL Server tương thích
- Flutter SDK
- Android Studio và Android Emulator
- Google Gemini API key

---

## Cấu hình

### 1. SQL Server

Backend hiện sử dụng SQL Server LocalDB với connection string:

```json
"DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=StudentAssistantDb;Trusted_Connection=True;TrustServerCertificate=True;"
```

Migration ban đầu tạo hai bảng: `Subjects` và `ChatMessages`.

Nếu database chưa được tạo, chạy lệnh sau trong thư mục backend:

```bash
dotnet ef database update
```

### 2. Gemini API Key

**Không hard-code Gemini API key trong source code.**

Tạo một Windows Environment Variable có tên:

```text
GEMINI_API_KEY
```

Ví dụ cấu hình tạm thời bằng PowerShell:

```powershell
$env:GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

Để cấu hình lâu dài trên Windows:

1. Tìm **Edit the system environment variables**.
2. Chọn **Environment Variables**.
3. Trong phần **User variables**, chọn **New**.
4. Variable name: `GEMINI_API_KEY`
5. Variable value: Gemini API key của bạn.
6. Khởi động lại terminal hoặc IDE sau khi lưu.

Có thể kiểm tra biến môi trường mà không hiển thị API key bằng:

```powershell
if ($env:GEMINI_API_KEY) {
    Write-Host "GEMINI_API_KEY đã được cấu hình"
} else {
    Write-Host "Chưa tìm thấy GEMINI_API_KEY"
}
```

---

## Cách chạy project

### Bước 1 – Chạy Backend

Mở terminal tại thư mục chứa file `StudentAssistant.API.csproj`:

```bash
dotnet restore
dotnet run
```

Theo cấu hình hiện tại, backend sử dụng:

```text
HTTP:  http://localhost:5177
HTTPS: https://localhost:7263
```

Swagger có thể truy cập trong Development mode tại:

```text
https://localhost:7263/swagger
```

hoặc theo URL thực tế hiển thị khi chạy `dotnet run`.

### Bước 2 – Chạy Flutter App

Mở thư mục Flutter project và chạy:

```bash
flutter pub get
flutter run
```

Khi chạy bằng Android Emulator, Flutter truy cập backend qua:

```text
http://10.0.2.2:5177
```

`10.0.2.2` là địa chỉ Android Emulator sử dụng để truy cập `localhost` của máy tính host.

Android project đã được cấu hình quyền Internet và cho phép clear-text HTTP trong môi trường development.

---

## API URL chính trong Flutter

```dart
// Subjects
http://10.0.2.2:5177/api/Subjects

// Chat
http://10.0.2.2:5177/api/ChatMessages
```

---

## Checklist Demo

### Demo Database

1. Mở **Quản lý môn học**.
2. Tải danh sách môn học.
3. Thêm một môn học.
4. Chỉnh sửa môn học.
5. Xóa môn học.

Luồng minh họa:

```text
Flutter -> REST API -> Entity Framework Core -> SQL Server
```

### Demo AI

1. Mở **AI Assistant**.
2. Nhập một câu hỏi, ví dụ:

```text
Giải thích StatefulWidget trong Flutter là gì?
```

3. Gửi câu hỏi.
4. Chờ phản hồi từ Gemini.
5. Thoát và mở lại màn hình chat để kiểm tra lịch sử được lưu.
6. Dùng nút xóa để xóa toàn bộ lịch sử chat.

Luồng minh họa:

```text
Flutter -> ASP.NET Core -> Gemini -> SQL Server -> Flutter
```

---

## Lưu ý bảo mật

- Gemini API key không được lưu trong Flutter.
- Gemini API key không được lưu trong `appsettings.json`.
- Gemini API key được đọc từ Environment Variable `GEMINI_API_KEY` khi backend chạy.
- Không commit API key, mật khẩu hoặc thông tin bí mật lên GitHub.
- Cấu hình CORS và HTTP hiện tại phục vụ mục đích học tập và demo trong môi trường development.

---

## Các chức năng đã kiểm thử thành công

Các luồng sau đã được kiểm thử thực tế:

- Subject GET
- Subject POST
- Subject PUT
- Subject DELETE
- Flutter Android Emulator kết nối ASP.NET Core API
- ASP.NET Core kết nối SQL Server
- ASP.NET Core gọi Google Gemini API
- Phản hồi Gemini thật được hiển thị trong Flutter
- Lịch sử chat được lưu và tải lại từ SQL Server
- Xóa lịch sử chat

---

## Bối cảnh môn học

Project được xây dựng cho môn **PRM393** nhằm minh họa:

- Tích hợp REST API và JSON
- Kết nối Database và thực hiện CRUD
- SQL Server với Entity Framework Core
- Giao tiếp giữa mobile app và backend
- Tích hợp Chat AI bằng Google Gemini
- Bảo mật API key bằng Environment Variable
