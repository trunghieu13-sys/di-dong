using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Data;
using ToeicAdmin.Models;

namespace ToeicAdmin.Controllers;

[ApiController, Route("api/exams")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "User,Admin")]
public class ExamsApiController(ToeicDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? section = null)
    {
        var exams = db.Exams.Where(e => e.IsPublished);
        if (section is "Reading" or "Listening") exams = exams.Where(e => e.Section == section);
        return Ok(await exams.Select(e => new { e.Id, e.Title, e.Description, e.Section, e.DurationMinutes, QuestionCount = e.Questions.Count }).ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Detail(int id)
    {
        var exam = await db.Exams.Where(e => e.Id == id && e.IsPublished).Select(e => new { e.Id, e.Title, e.DurationMinutes, Questions = e.Questions.OrderBy(q => q.Number).Select(q => new { q.Id, q.Number, q.Part, q.Prompt, q.PassageId, Passage = q.Passage == null ? null : q.Passage.Content, PassageImage = q.Passage == null ? null : q.Passage.ImagePath, Choices = new[] { q.ChoiceA, q.ChoiceB, q.ChoiceC, q.ChoiceD } }) }).FirstOrDefaultAsync();
        return exam is null ? NotFound() : Ok(exam);
    }

    public record AnswerDto(int QuestionId, string? Answer);
    public record StartDto(string? UserName);
    public record SubmitDto(int AttemptId, List<AnswerDto> Answers);

    [HttpPost("{id:int}/start")]
    public async Task<IActionResult> Start(int id, [FromBody] StartDto? input)
    {
        var exam = await db.Exams.FirstOrDefaultAsync(e => e.Id == id && e.IsPublished);
        if (exam is null) return NotFound();
        var attempt = new ExamAttempt { ExamId = exam.Id, UserName = string.IsNullOrWhiteSpace(input?.UserName) ? "Guest" : input.UserName.Trim() };
        db.Attempts.Add(attempt);
        await db.SaveChangesAsync();
        return Ok(new { attempt.Id, attempt.StartedAt, Deadline = attempt.StartedAt.AddMinutes(exam.DurationMinutes), exam.DurationMinutes });
    }

    [HttpPost("{id:int}/submit")]
    public async Task<IActionResult> Submit(int id, [FromBody] SubmitDto input)
    {
        var exam = await db.Exams.Include(e => e.Questions).FirstOrDefaultAsync(e => e.Id == id && e.IsPublished);
        if (exam is null) return NotFound();
        var attempt = await db.Attempts.FirstOrDefaultAsync(a => a.Id == input.AttemptId && a.ExamId == id);
        if (attempt is null) return BadRequest("Không tìm thấy lượt làm bài.");
        if (attempt.SubmittedAt is not null) return Conflict("Lượt làm bài này đã được nộp.");
        if (DateTime.UtcNow > attempt.StartedAt.AddMinutes(exam.DurationMinutes).AddSeconds(15)) return StatusCode(StatusCodes.Status410Gone, "Đã quá thời gian làm bài.");
        var questions = exam.Questions.ToDictionary(q => q.Id);
        if (input.Answers.Count > questions.Count || input.Answers.Any(a => !questions.ContainsKey(a.QuestionId))) return BadRequest("Câu trả lời không thuộc đề thi này.");
        var answers = input.Answers.GroupBy(a => a.QuestionId).Select(g => g.Last()).ToList();
        foreach (var answer in answers)
        {
            var q = questions[answer.QuestionId];
            var selected = answer.Answer?.ToUpperInvariant();
            var correct = selected == q.CorrectAnswer;
            if (correct) attempt.CorrectCount++;
            attempt.Answers.Add(new AttemptAnswer { QuestionId = q.Id, SelectedAnswer = selected, IsCorrect = correct });
        }
        attempt.SubmittedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        var breakdown = exam.Questions.GroupBy(q => q.Part).OrderBy(g => g.Key).Select(g => new { Part = g.Key, Total = g.Count(), Correct = attempt.Answers.Count(a => g.Any(q => q.Id == a.QuestionId) && a.IsCorrect) });
        return Ok(new { attempt.Id, attempt.CorrectCount, Total = exam.Questions.Count, Unanswered = exam.Questions.Count - answers.Count, Breakdown = breakdown });
    }
}
