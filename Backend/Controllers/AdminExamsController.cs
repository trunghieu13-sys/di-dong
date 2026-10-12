using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Data;
using ToeicAdmin.Models;
using ToeicAdmin.Services;

namespace ToeicAdmin.Controllers;

[Authorize(Roles = "Admin")]
public class AdminExamsController(ToeicDbContext db, IWebHostEnvironment environment) : Controller
{
    public async Task<IActionResult> Index() => View(await db.Exams.Include(e => e.Questions).OrderByDescending(e => e.CreatedAt).ToListAsync());

    [HttpPost, ValidateAntiForgeryToken, RequestSizeLimit(50_000_000)]
    public async Task<IActionResult> Import(string title, IFormFile? file, string section = "Reading")
    {
        if (section is not ("Reading" or "Listening"))
        {
            TempData["Error"] = "Chọn Reading hoặc Listening cho đề thi.";
            return RedirectToAction(nameof(Index));
        }
        if (file is null || file.Length == 0 || !Path.GetExtension(file.FileName).Equals(".docx", StringComparison.OrdinalIgnoreCase))
        {
            TempData["Error"] = "Chọn tệp .docx có nội dung trước khi nhập.";
            return RedirectToAction(nameof(Index));
        }
        ImportResult result;
        try { await using var stream = file.OpenReadStream(); result = WordExamImporter.Parse(stream); }
        catch (Exception ex) when (ex is InvalidDataException or IOException or System.Xml.XmlException)
        {
            TempData["Error"] = "Không đọc được tệp Word: " + ex.Message;
            return RedirectToAction(nameof(Index));
        }
        if (result.Questions.Count == 0)
        {
            TempData["Error"] = string.Join(" ", result.Warnings);
            return RedirectToAction(nameof(Index));
        }
        var uploadDirectory = Path.Combine(environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot"), "uploads", "passages");
        Directory.CreateDirectory(uploadDirectory);
        var savedImages = new Dictionary<string, string>();
        foreach (var (relationshipId, image) in result.Images)
        {
            var fileName = $"{Guid.NewGuid():N}{image.Extension}";
            await System.IO.File.WriteAllBytesAsync(Path.Combine(uploadDirectory, fileName), image.Bytes);
            savedImages[relationshipId] = "/uploads/passages/" + fileName;
        }
        var passages = result.Questions.Where(q => q.Part > 5 && !string.IsNullOrWhiteSpace(q.ImportedPassage))
            .GroupBy(q => new { Text = q.ImportedPassage!, ImageId = q.ImportedImageRelationshipId })
            .Select(group => new Passage { Part = group.First().Part, Content = group.Key.Text, ImagePath = group.Key.ImageId is not null ? savedImages.GetValueOrDefault(group.Key.ImageId) : null, Questions = group.ToList() }).ToList();
        var exam = new Exam { Title = string.IsNullOrWhiteSpace(title) ? Path.GetFileNameWithoutExtension(file.FileName) : title.Trim(), Description = file.FileName, Section = section, IsPublished = false, Questions = result.Questions, Passages = passages };
        db.Exams.Add(exam);
        await db.SaveChangesAsync();
        TempData["ImportSummary"] = $"Đã nhập {result.Questions.Count} câu từ {file.FileName}. Kiểm tra câu trả lời và nội dung trước khi công bố.";
        TempData["Warnings"] = string.Join("|", result.Warnings);
        return RedirectToAction(nameof(Review), new { id = exam.Id });
    }

    public async Task<IActionResult> Review(int id)
    {
        var exam = await db.Exams.Include(e => e.Questions.OrderBy(q => q.Number)).FirstOrDefaultAsync(e => e.Id == id);
        return exam is null ? NotFound() : View(exam);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveReview(int id, List<ExamQuestion> questions, bool publish)
    {
        var exam = await db.Exams.Include(e => e.Questions).FirstOrDefaultAsync(e => e.Id == id);
        if (exam is null) return NotFound();
        foreach (var edit in questions)
        {
            var q = exam.Questions.FirstOrDefault(x => x.Id == edit.Id);
            if (q is null) continue;
            q.Prompt = edit.Prompt.Trim(); q.ChoiceA = edit.ChoiceA.Trim(); q.ChoiceB = edit.ChoiceB.Trim();
            q.ChoiceC = edit.ChoiceC.Trim(); q.ChoiceD = edit.ChoiceD.Trim();
            q.CorrectAnswer = edit.CorrectAnswer is "A" or "B" or "C" or "D" ? edit.CorrectAnswer : null;
            q.NeedsReview = q.CorrectAnswer is null || new[] { q.Prompt, q.ChoiceA, q.ChoiceB, q.ChoiceC, q.ChoiceD }.Any(string.IsNullOrWhiteSpace);
        }
        if (publish && exam.Questions.Any(q => q.NeedsReview))
        {
            TempData["Error"] = "Chưa thể công bố: vui lòng hoàn thành câu hỏi và đánh dấu đáp án đúng cho tất cả câu.";
            return RedirectToAction(nameof(Review), new { id });
        }
        exam.IsPublished = publish;
        await db.SaveChangesAsync();
        TempData["Success"] = publish ? "Đề thi đã được công bố cho người học." : "Đã lưu nội dung đề thi.";
        return RedirectToAction(nameof(Index));
    }
}
