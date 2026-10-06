namespace StudentAssistant.API.Models;

public class Subject
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty; // Subject name (e.g., "Mathematics")
    public string Description { get; set; } = string.Empty; // Brief description of the subject
}
