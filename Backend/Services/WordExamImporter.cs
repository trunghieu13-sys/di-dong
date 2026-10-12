using System.Text.RegularExpressions;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using ToeicAdmin.Models;

namespace ToeicAdmin.Services;

public record ImportedImage(string Extension, byte[] Bytes);
public record ImportResult(List<ExamQuestion> Questions, List<string> Warnings, Dictionary<string, ImportedImage> Images);

/// <summary>Imports TOEIC questions from Word documents, including passages whose blank numbers are embedded in the text.</summary>
public static partial class WordExamImporter
{
    [GeneratedRegex(@"^\s*(\d{1,3})\s*[.)]?\s*(.*)$")]
    private static partial Regex NumberedLine();
    [GeneratedRegex(@"\(\s*([A-D])\s*\)\s*", RegexOptions.IgnoreCase)]
    private static partial Regex ChoiceMarker();
    [GeneratedRegex(@"[({]\s*([A-D])\s*[)}]\s*", RegexOptions.IgnoreCase)]
    private static partial Regex FlexibleChoiceMarker();
    [GeneratedRegex(@"^Questions?\s+(\d+)\s*[-–]\s*(\d+)", RegexOptions.IgnoreCase)]
    private static partial Regex QuestionRange();
    [GeneratedRegex(@"(?<!\d)(\d{1,3})\s*\.")]
    private static partial Regex InlineQuestionNumber();
    [GeneratedRegex(@"(?:_{3,}|-{3,}|[-–]+\s*\[?\s*\d+\s*\]?\s*[-–]+)")]
    private static partial Regex PlaceholderMarker();
    [GeneratedRegex(@"\s+")]
    private static partial Regex Whitespace();
    [GeneratedRegex(@"^\s*(?:(\d{1,3})\s*[.)]\s*)+$")]
    private static partial Regex NumberLabelList();
    [GeneratedRegex(@"(?<=\d)\s+(?=\d)")]
    private static partial Regex SplitDigitSpace();

    private sealed record SourceLine(string Text, bool Marked, List<string> ImageIds);

    public static ImportResult Parse(Stream docx)
    {
        using var word = WordprocessingDocument.Open(docx, false);
        var body = word.MainDocumentPart?.Document?.Body
            ?? throw new InvalidDataException("Tệp Word không có phần nội dung.");
        var mainPart = word.MainDocumentPart!;
        var lines = body.Descendants<Paragraph>()
            .Select(p => new SourceLine(
                Whitespace().Replace(p.InnerText.Replace('\u00a0', ' ').Trim(), " "),
                p.Descendants<Run>().Any(r => r.RunProperties?.Bold is not null || r.RunProperties?.Highlight is not null),
                p.Descendants<DocumentFormat.OpenXml.Drawing.Blip>().Select(b => b.Embed?.Value)
                    .Where(id => !string.IsNullOrWhiteSpace(id)).Cast<string>().ToList()))
            .Where(p => !string.IsNullOrWhiteSpace(p.Text) || p.ImageIds.Count > 0)
            .ToList();

        var byNumber = new SortedDictionary<int, ExamQuestion>();
        var warnings = new List<string>();
        var images = new Dictionary<string, ImportedImage>();
        var passageLines = new List<string>();
        var passageQuestionNumbers = new HashSet<int>();
        var passageImageId = (string?)null;
        var rangeStart = 0;
        var rangeEnd = 0;
        var readingOptionsStarted = false;
        ExamQuestion? optionQuestion = null;
        var pendingQuestionNumbers = new Queue<int>();

        int PartFor(int number) => number <= 130 ? 5 : number <= 146 ? 6 : 7;

        ExamQuestion GetQuestion(int number)
        {
            if (!byNumber.TryGetValue(number, out var question))
            {
                question = new ExamQuestion { Number = number, Part = PartFor(number), Prompt = "" };
                byNumber.Add(number, question);
            }
            return question;
        }

        static MatchCollection GetChoiceMarkers(string text) => FlexibleChoiceMarker().Matches(text);
        static bool IsChoiceStart(string text) => GetChoiceMarkers(text).Count > 0 && GetChoiceMarkers(text)[0].Index == 0;

        void AddChoices(ExamQuestion question, string text, bool marked)
        {
            var markers = GetChoiceMarkers(text);
            if (markers.Count == 0) return;
            for (var i = 0; i < markers.Count; i++)
            {
                var key = markers[i].Groups[1].Value.ToUpperInvariant();
                var start = markers[i].Index + markers[i].Length;
                var end = i + 1 < markers.Count ? markers[i + 1].Index : text.Length;
                var value = text[start..end].Trim();
                switch (key)
                {
                    case "A": question.ChoiceA = value; break;
                    case "B": question.ChoiceB = value; break;
                    case "C": question.ChoiceC = value; break;
                    case "D": question.ChoiceD = value; break;
                }
                if (marked) question.CorrectAnswer = key;
            }
        }

        void FinishPassage()
        {
            if (rangeStart == 0 || rangeEnd < rangeStart
                || !passageLines.Any(x => !string.IsNullOrWhiteSpace(x))) return;
            var rawPassage = string.Join("\n\n", passageLines.Where(x => !string.IsNullOrWhiteSpace(x)));
            var cleanPassage = rawPassage;
            foreach (var number in passageQuestionNumbers)
                cleanPassage = Regex.Replace(cleanPassage, $@"(?<!\d){number}\s*\.\s*", " ");
            cleanPassage = Whitespace().Replace(cleanPassage, " ").Trim();

            var blankMatches = PlaceholderMarker().Matches(cleanPassage).Cast<Match>().ToList();
            var orderedNumbers = Enumerable.Range(rangeStart, rangeEnd - rangeStart + 1).ToList();
            for (var i = 0; i < orderedNumbers.Count; i++)
            {
                var question = GetQuestion(orderedNumbers[i]);
                question.ImportedPassage = cleanPassage;
                question.ImportedImageRelationshipId = passageImageId;
                if (i < blankMatches.Count)
                {
                    var blank = blankMatches[i];
                    var sentenceStart = cleanPassage.LastIndexOf('.', Math.Max(0, blank.Index - 1));
                    sentenceStart = sentenceStart < 0 ? 0 : sentenceStart + 1;
                    var sentenceEnd = cleanPassage.IndexOf('.', blank.Index + blank.Length);
                    if (sentenceEnd >= 0 && string.IsNullOrWhiteSpace(cleanPassage[(blank.Index + blank.Length)..sentenceEnd]))
                        sentenceEnd = cleanPassage.IndexOf('.', sentenceEnd + 1);
                    if (sentenceEnd < 0) sentenceEnd = cleanPassage.Length;
                    question.Prompt = cleanPassage[sentenceStart..sentenceEnd].Trim();
                }
                else
                {
                    question.Prompt = $"Chỗ trống câu {question.Number} trong đoạn văn bên dưới.";
                }
            }
            passageLines.Clear();
            passageQuestionNumbers.Clear();
            passageImageId = null;
        }

        foreach (var line in lines)
        {
            var sourceText = line.Text;
            var range = QuestionRange().Match(sourceText);
            if (range.Success && int.TryParse(range.Groups[1].Value, out var startNumber) && int.TryParse(range.Groups[2].Value, out var endNumber))
            {
                FinishPassage();
                rangeStart = startNumber;
                rangeEnd = endNumber;
                readingOptionsStarted = false;
                optionQuestion = null;
                passageLines.Clear();
                passageQuestionNumbers.Clear();
                passageImageId = null;
                continue;
            }

            var labelText = SplitDigitSpace().Replace(sourceText, "");
            var labels = NumberLabelList().Match(labelText);
            if (rangeStart == 0 && labels.Success)
            {
                foreach (Match label in Regex.Matches(labelText, @"\d{1,3}"))
                    if (int.TryParse(label.Value, out var queued) && queued is >= 1 and <= 200)
                        pendingQuestionNumbers.Enqueue(queued);
                optionQuestion = null;
                continue;
            }

            var numbered = NumberedLine().Match(sourceText);
            var leadingNumber = 0;
            var hasLeadingNumber = numbered.Success && int.TryParse(numbered.Groups[1].Value, out leadingNumber)
                && leadingNumber is >= 1 and <= 200;
            var tail = hasLeadingNumber ? numbered.Groups[2].Value.Trim() : sourceText;
            var leadingNumberIsChoiceBlock = hasLeadingNumber && IsChoiceStart(tail);

            if (rangeStart > 0 && !readingOptionsStarted && !leadingNumberIsChoiceBlock)
            {
                var startsQuestionList = hasLeadingNumber && leadingNumber >= rangeStart
                    && leadingNumber <= rangeEnd && !string.IsNullOrWhiteSpace(tail);
                if (startsQuestionList)
                {
                    FinishPassage();
                    readingOptionsStarted = true;
                    optionQuestion = GetQuestion(leadingNumber);
                    var markers = GetChoiceMarkers(tail);
                    optionQuestion.Prompt = markers.Count == 0 ? tail : tail[..markers[0].Index].Trim();
                    if (markers.Count > 0) AddChoices(optionQuestion, tail[markers[0].Index..], line.Marked);
                    continue;
                }
                if (!string.IsNullOrWhiteSpace(line.Text)) passageLines.Add(line.Text);
                if (line.ImageIds.Count > 0) passageImageId = line.ImageIds[^1];
                foreach (Match match in InlineQuestionNumber().Matches(line.Text))
                {
                    if (int.TryParse(match.Groups[1].Value, out var embedded) && embedded >= rangeStart && embedded <= rangeEnd)
                        passageQuestionNumbers.Add(embedded);
                }
                continue;
            }

            if (leadingNumberIsChoiceBlock)
            {
                if (rangeStart > 0) readingOptionsStarted = true;
                optionQuestion = GetQuestion(leadingNumber);
                AddChoices(optionQuestion, tail, line.Marked);
                continue;
            }

            if (hasLeadingNumber)
            {
                var q = GetQuestion(leadingNumber);
                optionQuestion = q;
                var markers = GetChoiceMarkers(tail);
                if (markers.Count > 0)
                {
                    q.Prompt = tail[..markers[0].Index].Trim();
                    AddChoices(q, tail[markers[0].Index..], line.Marked);
                }
                else if (!string.IsNullOrWhiteSpace(tail))
                {
                    q.Prompt = string.IsNullOrEmpty(q.Prompt) ? tail : $"{q.Prompt} {tail}".Trim();
                }
                continue;
            }

            var choiceMarkers = GetChoiceMarkers(sourceText);
            if (rangeStart == 0 && pendingQuestionNumbers.Count > 0 && choiceMarkers.Count > 0
                && choiceMarkers[0].Groups[1].Value.Equals("A", StringComparison.OrdinalIgnoreCase))
            {
                if (optionQuestion is not null && !string.IsNullOrWhiteSpace(optionQuestion.Prompt)
                    && string.IsNullOrWhiteSpace(optionQuestion.ChoiceA))
                {
                    AddChoices(optionQuestion, sourceText, line.Marked);
                    continue;
                }
                optionQuestion = GetQuestion(pendingQuestionNumbers.Dequeue());
                optionQuestion.Prompt = sourceText[..choiceMarkers[0].Index].Trim();
                AddChoices(optionQuestion, sourceText[choiceMarkers[0].Index..], line.Marked);
                continue;
            }
            if (rangeStart == 0 && pendingQuestionNumbers.Count > 0 && choiceMarkers.Count == 0)
            {
                optionQuestion = GetQuestion(pendingQuestionNumbers.Dequeue());
                optionQuestion.Prompt = sourceText;
                continue;
            }
            if (choiceMarkers.Count > 0 && optionQuestion is not null)
            {
                AddChoices(optionQuestion, line.Text, line.Marked);
                continue;
            }

            if (optionQuestion is not null && string.IsNullOrWhiteSpace(optionQuestion.Prompt) && !string.IsNullOrWhiteSpace(line.Text))
                optionQuestion.Prompt = line.Text;
        }
        FinishPassage();

        foreach (var id in byNumber.Values.Select(q => q.ImportedImageRelationshipId).Where(id => id is not null).Distinct())
        {
            var part = mainPart.GetPartById(id!);
            if (part is not ImagePart imagePart) continue;
            using var stream = imagePart.GetStream();
            using var memory = new MemoryStream();
            stream.CopyTo(memory);
            var extension = imagePart.ContentType switch
            {
                "image/jpeg" => ".jpg", "image/gif" => ".gif", "image/bmp" => ".bmp", "image/svg+xml" => ".svg", _ => ".png"
            };
            images[id!] = new ImportedImage(extension, memory.ToArray());
        }

        foreach (var question in byNumber.Values)
        {
            if (new[] { question.ChoiceA, question.ChoiceB, question.ChoiceC, question.ChoiceD }.Any(string.IsNullOrWhiteSpace))
                warnings.Add($"Câu {question.Number}: thiếu một hoặc nhiều lựa chọn A-D.");
            if (question.CorrectAnswer is null)
                warnings.Add($"Câu {question.Number}: chưa nhận diện đáp án đúng (hãy chọn đáp án trong bước rà soát).");
            question.NeedsReview = question.CorrectAnswer is null || string.IsNullOrWhiteSpace(question.Prompt)
                || new[] { question.ChoiceA, question.ChoiceB, question.ChoiceC, question.ChoiceD }.Any(string.IsNullOrWhiteSpace);
        }
        if (byNumber.Count == 0) warnings.Add("Không tìm thấy câu hỏi được đánh số và các lựa chọn (A)-(D) trong file Word.");
        return new ImportResult(byNumber.Values.ToList(), warnings, images);
    }
}
