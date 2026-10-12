using System.Xml;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ToeicAdmin.Data;
using ToeicAdmin.Models;
using ToeicAdmin.Services;

namespace ToeicAdmin.Controllers;

[ApiController]
[Route("api/admin/exams")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Admin")]
public class AdminExamsApiController(ToeicDbContext db, IWebHostEnvironment environment) : ControllerBase
{
    public sealed record ReviewQuestion(int Id, string Prompt, string ChoiceA, string ChoiceB, string ChoiceC, string ChoiceD, string? CorrectAnswer);
    public sealed record ReviewRequest(List<ReviewQuestion> Questions, bool Publish);

    [HttpGet]
    public async Task<IActionResult> List()
    {
        var exams = await db.Exams.OrderByDescending(e => e.CreatedAt)
            .Select(e => new { e.Id, e.Title, e.Section, e.IsPublished, e.CreatedAt, e.DurationMinutes, QuestionCount = e.Questions.Count })
            .ToListAsync();
        return Ok(exams);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Review(int id)
    {
        var exam = await db.Exams.Include(e => e.Questions).ThenInclude(q => q.Passage).FirstOrDefaultAsync(e => e.Id == id);
        if (exam is null) return NotFound(new { message = "Không tìm thấy đề thi." });
        return Ok(new
        {
            exam.Id, exam.Title, exam.Section, exam.DurationMinutes, exam.IsPublished,
            questions = exam.Questions.OrderBy(q => q.Number).Select(q => new
            {
                q.Id, q.Number, q.Part, q.Prompt, Passage = q.Passage == null ? null : q.Passage.Content,
                q.ChoiceA, q.ChoiceB, q.ChoiceC, q.ChoiceD,
                q.CorrectAnswer, q.NeedsReview
            })
        });
    }

    [HttpPut("{id:int}/review")]
    public async Task<IActionResult> SaveReview(int id, [FromBody] ReviewRequest request)
    {
        var exam = await db.Exams.Include(e => e.Questions).FirstOrDefaultAsync(e => e.Id == id);
        if (exam is null) return NotFound(new { message = "Không tìm thấy đề thi." });
        foreach (var edit in request.Questions)
        {
            var question = exam.Questions.FirstOrDefault(q => q.Id == edit.Id);
            if (question is null) continue;
            question.Prompt = edit.Prompt.Trim();
            question.ChoiceA = edit.ChoiceA.Trim(); question.ChoiceB = edit.ChoiceB.Trim();
            question.ChoiceC = edit.ChoiceC.Trim(); question.ChoiceD = edit.ChoiceD.Trim();
            question.CorrectAnswer = edit.CorrectAnswer is "A" or "B" or "C" or "D" ? edit.CorrectAnswer : null;
            question.NeedsReview = question.CorrectAnswer is null ||
                new[] { question.Prompt, question.ChoiceA, question.ChoiceB, question.ChoiceC, question.ChoiceD }.Any(string.IsNullOrWhiteSpace);
        }
        if (request.Publish && exam.Questions.Any(q => q.NeedsReview))
            return BadRequest(new { message = "Hoàn thiện nội dung và chọn đáp án đúng cho tất cả câu trước khi công bố." });
        exam.IsPublished = request.Publish;
        await db.SaveChangesAsync();
        return Ok(new { message = request.Publish ? "Đã lưu và công bố đề thi." : "Đã lưu bản nháp." , exam.IsPublished });
    }

    [HttpPost("import")]
    [RequestSizeLimit(50_000_000)]
    public async Task<IActionResult> Import([FromForm] string? title, [FromForm] string section, [FromForm] IFormFile? file)
    {
        if (section is not ("Reading" or "Listening"))
            return BadRequest(new { message = "Chọn Reading hoặc Listening cho đề thi." });
        if (file is null || file.Length == 0 || !Path.GetExtension(file.FileName).Equals(".docx", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { message = "Chọn tệp .docx có nội dung trước khi nhập." });

        ImportResult result;
        try
        {
            await using var stream = file.OpenReadStream();
            result = WordExamImporter.Parse(stream);
        }
        catch (Exception ex) when (ex is InvalidDataException or IOException or XmlException)
        {
            return BadRequest(new { message = "Không đọc được tệp Word: " + ex.Message });
        }
        if (result.Questions.Count == 0)
            return BadRequest(new { message = string.Join(" ", result.Warnings) });

        var uploadDirectory = Path.Combine(environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot"), "uploads", "passages");
        Directory.CreateDirectory(uploadDirectory);
        var savedImages = new Dictionary<string, string>();
        foreach (var (relationshipId, image) in result.Images)
        {
            var fileName = $"{Guid.NewGuid():N}{image.Extension}";
            await System.IO.File.WriteAllBytesAsync(Path.Combine(uploadDirectory, fileName), image.Bytes);
            savedImages[relationshipId] = "/uploads/passages/" + fileName;
        }

        var passages = result.Questions
            .Where(q => q.Part > 5 && !string.IsNullOrWhiteSpace(q.ImportedPassage))
            .GroupBy(q => new { Text = q.ImportedPassage!, ImageId = q.ImportedImageRelationshipId })
            .Select(group => new Passage
            {
                Part = group.First().Part,
                Content = group.Key.Text,
                ImagePath = group.Key.ImageId is not null ? savedImages.GetValueOrDefault(group.Key.ImageId) : null,
                Questions = group.ToList()
            }).ToList();
        var exam = new Exam
        {
            Title = string.IsNullOrWhiteSpace(title) ? Path.GetFileNameWithoutExtension(file.FileName) : title.Trim(),
            Description = file.FileName,
            Section = section,
            IsPublished = false,
            Questions = result.Questions,
            Passages = passages
        };
        db.Exams.Add(exam);
        await db.SaveChangesAsync();
        return Ok(new
        {
            id = exam.Id,
            title = exam.Title,
            section = exam.Section,
            importedCount = result.Questions.Count,
            warnings = result.Warnings,
            message = $"Đã nhập {result.Questions.Count} câu. Đề được lưu ở trạng thái bản nháp; hãy rà soát đáp án trước khi công bố."
        });
    }
}
