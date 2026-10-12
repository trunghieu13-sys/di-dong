# TOEIC database schema

The backend uses SQL Server through Entity Framework Core. On its first launch, `EnsureCreated` creates the tables from the entity model. The connection string is in `Backend/appsettings.json` and can be overridden with `ConnectionStrings__ToeicDatabase`.

```mermaid
erDiagram
    AppUser ||--o{ AppUserRole : has
    AppRole ||--o{ AppUserRole : grants
    Exam ||--o{ Passage : contains
    Exam ||--o{ ExamQuestion : contains
    Passage o|--o{ ExamQuestion : groups
    Exam ||--o{ ExamAttempt : receives
    ExamAttempt ||--o{ AttemptAnswer : records
    ExamQuestion ||--o{ AttemptAnswer : answered_as

    Exam {
      int Id PK
      string Title
      string Description
      int DurationMinutes
      bool IsPublished
      datetime CreatedAt
    }
    Passage {
      int Id PK
      int ExamId FK
      int Part
      string Content
      string ImagePath
    }
    ExamQuestion {
      int Id PK
      int ExamId FK
      int PassageId FK
      int Number
      int Part
      string Prompt
      string ChoiceA
      string ChoiceB
      string ChoiceC
      string ChoiceD
      string CorrectAnswer
      bool NeedsReview
    }
    ExamAttempt {
      int Id PK
      int ExamId FK
      string UserName
      datetime StartedAt
      datetime SubmittedAt
      int CorrectCount
    }
    AttemptAnswer {
      int Id PK
      int ExamAttemptId FK
      int QuestionId FK
      string SelectedAnswer
      bool IsCorrect
    }
    AppUser {
      int Id PK
      string Email
      string NormalizedEmail UK
      string DisplayName
      string PasswordHash
      bool IsActive
      datetime CreatedAt
    }
    AppRole {
      int Id PK
      string Name
      string NormalizedName UK
    }
    AppUserRole {
      int UserId PK,FK
      int RoleId PK,FK
    }
```

`AppRoles` is initialized with `Admin` and `User`. Public registration always assigns `User`; an Admin can change roles from `/AdminUsers`. To create the first Admin, set `Auth__BootstrapAdmin__Email` and `Auth__BootstrapAdmin__Password` in the environment before starting the backend. The seed runs only if that email does not already exist.

Part 5 questions have no passage. Part 6 and Part 7 questions may link to a shared passage, and Part 7 can represent a set of questions for a longer text. Answers and scoring are stored per attempt. The unique `(ExamId, Number)` index prevents duplicate question numbers in one exam.
