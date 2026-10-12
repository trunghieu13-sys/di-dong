# TOEIC Reading practice

This workspace contains the Flutter learner app at the repository root and an ASP.NET Core MVC admin/API project in `Backend/`.

## Learner app

Open this folder in VS Code or Android Studio and run `flutter run`. The app lists published exams from the backend; if the backend is unreachable or has no published exam, it shows a 10-question sample for preview. Published exams load their questions and passage images from the API, use the server-side 75-minute deadline, and return the server's score breakdown.

## Admin backend

Prerequisites: .NET 10 SDK and SQL Server. The connection string targets `localhost`, database `TiengAnh`, using Windows Authentication; update it in `Backend/appsettings.json` if your SQL Server is elsewhere.

```powershell
dotnet run --project Backend
```

On startup, the backend creates the authentication tables `AppUsers`, `AppRoles`, and `AppUserRoles` in `TiengAnh` and seeds the `Admin` and `User` roles. Flutter users can register and sign in; public registration always creates a `User`. Admins sign in to the website and manage accounts at `/AdminUsers`.

To create the first administrator, set credentials in PowerShell before the first backend run (choose your own email and strong password):

```powershell
$env:Auth__BootstrapAdmin__Email = 'admin@example.com'
$env:Auth__BootstrapAdmin__Password = 'choose-a-strong-password'
dotnet run --project Backend
```

The initial administrator is only created if that email does not already exist. JWT settings are in `Backend/appsettings.json`; replace the local development signing key before deploying.

The site opens at `http://localhost:5029`. Use **Quản lý đề thi** to import a `.docx` file, review the parsed questions, choose the correct answers, and publish. The app only exposes published exams through `GET /api/exams`; question answers are not included in the exam response. `POST /api/exams/{id}/start` creates a timed attempt. `POST /api/exams/{id}/submit` records responses and returns the score breakdown.

The importer expects numbered questions followed by four `(A)`–`(D)` choices. It reads paragraph text and embedded passage images. Bold or highlighted choices are treated as likely answer keys; all other questions stay in draft review until the admin selects the correct answer. Check imported text and formatting before publication. On an Android emulator, the Flutter app uses `10.0.2.2:5029` to reach the local API. For Flutter Web or a physical phone, set `API_BASE_URL` to a reachable API address with `--dart-define=API_BASE_URL=http://<host>:5029/api`.

The normalized schema is documented in [docs/database-schema.md](docs/database-schema.md).
