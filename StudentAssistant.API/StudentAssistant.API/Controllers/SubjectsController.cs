using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentAssistant.API.Data;
using StudentAssistant.API.Models;

namespace StudentAssistant.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SubjectsController : ControllerBase
{
    private readonly AppDbContext _context;

    // Constructor - inject AppDbContext via dependency injection
    public SubjectsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/Subjects
    // Returns all subjects from the database
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Subject>>> GetSubjects()
    {
        var subjects = await _context.Subjects.ToListAsync();
        return Ok(subjects);
    }

    // GET: api/Subjects/{id}
    // Returns a single subject by ID, or 404 if not found
    [HttpGet("{id}")]
    public async Task<ActionResult<Subject>> GetSubject(int id)
    {
        var subject = await _context.Subjects.FindAsync(id);
        
        if (subject == null)
        {
            return NotFound(new { message = $"Subject with ID {id} not found." });
        }
        
        return Ok(subject);
    }

    // POST: api/Subjects
    // Creates a new subject in the database
    [HttpPost]
    public async Task<ActionResult<Subject>> PostSubject(Subject subject)
    {
        // Add the new subject to the database
        _context.Subjects.Add(subject);
        await _context.SaveChangesAsync();

        // Return 201 Created with the created subject and location header
        return CreatedAtAction(nameof(GetSubject), new { id = subject.Id }, subject);
    }

    // PUT: api/Subjects/{id}
    // Updates an existing subject
    [HttpPut("{id}")]
    public async Task<IActionResult> PutSubject(int id, Subject subject)
    {
        // Check if route ID matches the subject's ID
        if (id != subject.Id)
        {
            return BadRequest(new { message = "Route ID does not match subject ID." });
        }

        // Check if the subject exists in the database
        var existingSubject = await _context.Subjects.FindAsync(id);
        if (existingSubject == null)
        {
            return NotFound(new { message = $"Subject with ID {id} not found." });
        }

        // Update the subject properties
        existingSubject.Name = subject.Name;
        existingSubject.Description = subject.Description;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            // Handle concurrency conflicts
            if (!await _context.Subjects.AnyAsync(s => s.Id == id))
            {
                return NotFound(new { message = $"Subject with ID {id} not found." });
            }
            throw;
        }

        // Return 204 No Content on success
        return NoContent();
    }

    // DELETE: api/Subjects/{id}
    // Deletes a subject from the database
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSubject(int id)
    {
        var subject = await _context.Subjects.FindAsync(id);
        
        if (subject == null)
        {
            return NotFound(new { message = $"Subject with ID {id} not found." });
        }

        _context.Subjects.Remove(subject);
        await _context.SaveChangesAsync();

        // Return 204 No Content on success
        return NoContent();
    }
}
