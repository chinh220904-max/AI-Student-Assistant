# AI Student Assistant

## Overview

AI Student Assistant is a Flutter mobile application combined with ASP.NET Core Web API, SQL Server, and Google Gemini AI. The app allows students to manage subjects and ask questions to an AI assistant powered by Google Gemini.

## Features

### Subject Management
- View all subjects
- Add new subject
- Update existing subject
- Delete subject

### AI Assistant
- Ask AI questions using Google Gemini
- View chat history
- Store chat history in SQL Server
- Clear chat history

## Technologies

- **Frontend**: Flutter, Dart
- **Backend**: ASP.NET Core Web API (.NET 8)
- **Database**: SQL Server with Entity Framework Core
- **AI**: Google Gemini API

## Architecture

```
Flutter App
    │
    └──► ASP.NET Core REST API
              │
              ├──► SQL Server (Subjects, ChatMessages)
              │
              └──► Google Gemini API (Chat AI)
```

## API Endpoints

### Subjects
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/Subjects` | Get all subjects |
| GET | `/api/Subjects/{id}` | Get subject by ID |
| POST | `/api/Subjects` | Create new subject |
| PUT | `/api/Subjects/{id}` | Update subject |
| DELETE | `/api/Subjects/{id}` | Delete subject |

### Chat Messages
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/ChatMessages` | Get all chat messages |
| POST | `/api/ChatMessages` | Create chat message (manual) |
| POST | `/api/ChatMessages/ask` | Ask AI question |
| DELETE | `/api/ChatMessages` | Clear all chat history |

## Configuration

### Backend

The Gemini API key must be configured as a Windows Environment Variable:

```
GEMINI_API_KEY = your_api_key_here
```

### Flutter

The Flutter app connects to the backend using Android Emulator's special IP:

```dart
const String baseUrl = 'http://10.0.2.2:5177';
```

Note: Use `10.0.2.2` instead of `localhost` when running on Android Emulator.

## How to Run

### Backend

```bash
cd StudentAssistant.API
dotnet run
```

The API will be available at `https://localhost:5001` (or 5000).

### Flutter

```bash
cd student_assistant
flutter pub get
flutter run
```

## Project Structure

### Backend
```
StudentAssistant.API/
├── Controllers/
│   ├── SubjectsController.cs
│   └── ChatMessagesController.cs
├── Models/
│   ├── Subject.cs
│   ├── ChatMessage.cs
│   └── ChatRequest.cs
├── Data/
│   └── AppDbContext.cs
├── Services/
│   └── GeminiService.cs
├── Program.cs
└── appsettings.json
```

### Flutter
```
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

## Database

The application uses SQL Server LocalDB with Entity Framework Core. Database schema:

- **Subjects**: Id, Name, Description
- **ChatMessages**: Id, Message, Response, CreatedAt

## License

This project is for educational purposes (PRM393 course).
