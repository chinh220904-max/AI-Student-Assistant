using Microsoft.EntityFrameworkCore;
using StudentAssistant.API.Data;
using StudentAssistant.API.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container

// Register AppDbContext with SQL Server using connection string from appsettings.json
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Đăng ký HttpClient cho GeminiService (dependency injection)
builder.Services.AddHttpClient<GeminiService>();

// Add controllers to the container
builder.Services.AddControllers();

// Enable Swagger/OpenAPI in development environment
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure CORS policy for Flutter frontend
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin()   // Allow any origin (for classroom demo)
              .AllowAnyHeader()   // Allow any HTTP header
              .AllowAnyMethod();  // Allow any HTTP method
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    // Enable Swagger UI in development mode
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Redirect HTTP to HTTPS
app.UseHttpsRedirection();

// Apply CORS policy before authorization
app.UseCors("AllowFlutter");

// Enable authorization middleware
app.UseAuthorization();

// Map controller routes
app.MapControllers();

// Run the application
app.Run();
