using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ToeicAdmin.Models;

public class Exam
{
    public int Id { get; set; }
    [Required, StringLength(200)] public string Title { get; set; } = "";
    [StringLength(1000)] public string? Description { get; set; }
    [Required, StringLength(20)] public string Section { get; set; } = "Reading";
    public int DurationMinutes { get; set; } = 75;
    public bool IsPublished { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public List<Passage> Passages { get; set; } = [];
    public List<ExamQuestion> Questions { get; set; } = [];
}

public class Passage
{
    public int Id { get; set; }
    public int ExamId { get; set; }
    public Exam Exam { get; set; } = null!;
    public int Part { get; set; }
    public string Content { get; set; } = "";
    public string? ImagePath { get; set; }
    public List<ExamQuestion> Questions { get; set; } = [];
}

public class ExamQuestion
{
    public int Id { get; set; }
    public int ExamId { get; set; }
    public Exam Exam { get; set; } = null!;
    public int? PassageId { get; set; }
    public Passage? Passage { get; set; }
    public int Number { get; set; }
    public int Part { get; set; }
    public string Prompt { get; set; } = "";
    public string ChoiceA { get; set; } = "";
    public string ChoiceB { get; set; } = "";
    public string ChoiceC { get; set; } = "";
    public string ChoiceD { get; set; } = "";
    [StringLength(1)] public string? CorrectAnswer { get; set; }
    public bool NeedsReview { get; set; } = true;
    [NotMapped] public string? ImportedPassage { get; set; }
    [NotMapped] public string? ImportedImageRelationshipId { get; set; }
}

public class ExamAttempt
{
    public int Id { get; set; }
    public int ExamId { get; set; }
    public Exam Exam { get; set; } = null!;
    [StringLength(100)] public string UserName { get; set; } = "Guest";
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SubmittedAt { get; set; }
    public int CorrectCount { get; set; }
    public List<AttemptAnswer> Answers { get; set; } = [];
}

public class AttemptAnswer
{
    public int Id { get; set; }
    public int ExamAttemptId { get; set; }
    public ExamAttempt ExamAttempt { get; set; } = null!;
    public int QuestionId { get; set; }
    public ExamQuestion Question { get; set; } = null!;
    [StringLength(1)] public string? SelectedAnswer { get; set; }
    public bool IsCorrect { get; set; }
}
