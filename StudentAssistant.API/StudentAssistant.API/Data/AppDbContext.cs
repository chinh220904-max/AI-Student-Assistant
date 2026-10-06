using Microsoft.EntityFrameworkCore;
using StudentAssistant.API.Models;

namespace StudentAssistant.API.Data;

public class AppDbContext : DbContext
{
    // Constructor that receives DbContextOptions via dependency injection
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // DbSet for Subject entity - represents the Subjects table in the database
    public DbSet<Subject> Subjects { get; set; }

    // DbSet for ChatMessage entity - represents the ChatMessages table in the database
    public DbSet<ChatMessage> ChatMessages { get; set; }
}
