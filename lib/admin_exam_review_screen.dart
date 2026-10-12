import 'package:flutter/material.dart';

class AdminExamReviewScreen extends StatefulWidget {
  const AdminExamReviewScreen({
    super.key,
    required this.examId,
    required this.loadExam,
    required this.saveReview,
  });

  final int examId;
  final Future<Map<String, dynamic>> Function(int) loadExam;
  final Future<Map<String, dynamic>> Function(
    int,
    List<Map<String, dynamic>>,
    bool,
  )
  saveReview;

  @override
  State<AdminExamReviewScreen> createState() => _AdminExamReviewScreenState();
}

class _AdminExamReviewScreenState extends State<AdminExamReviewScreen> {
  Map<String, dynamic>? exam;
  List<Map<String, dynamic>> questions = [];
  bool loading = true, saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.loadExam(widget.examId);
      if (!mounted) return;
      setState(() {
        exam = data;
        questions = (data['questions'] as List)
            .map((q) => Map<String, dynamic>.from(q as Map))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  Future<void> _save(bool publish) async {
    setState(() => saving = true);
    try {
      final result = await widget.saveReview(widget.examId, questions, publish);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Đã lưu đề thi.'),
        ),
      );
      if (publish) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = exam?['title'] as String? ?? 'Rà soát đề thi';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FC),
      appBar: AppBar(
        title: const Text('Rà soát đề thi'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Column(
              children: [
                Material(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${exam?['section'] ?? ''} · ${questions.length} câu · Kiểm tra nội dung và đáp án trước khi công bố.',
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, index) => _questionCard(index),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => _save(false),
                            child: const Text('Lưu bản nháp'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: saving ? null : () => _save(true),
                            child: Text(
                              saving ? 'Đang lưu…' : 'Lưu và công bố',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _questionCard(int index) {
    final q = questions[index];
    final choices = ['A', 'B', 'C', 'D'];
    final passage = q['passage'] as String?;
    final previousPassage = index == 0 ? null : questions[index - 1]['passage'];
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Part ${q['part']} · Câu ${q['number']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF004AC6),
              ),
            ),
            if (passage != null &&
                passage.isNotEmpty &&
                passage != previousPassage) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đoạn văn / nội dung dùng chung',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(passage),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              initialValue: q['prompt'] as String? ?? '',
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => q['prompt'] = v,
            ),
            const SizedBox(height: 8),
            for (final key in choices)
              Row(
                children: [
                  Radio<String>(
                    value: key,
                    groupValue: q['correctAnswer'] as String?,
                    onChanged: (v) => setState(() => q['correctAnswer'] = v),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: q['choice$key'] as String? ?? '',
                      decoration: InputDecoration(
                        labelText: 'Lựa chọn $key',
                        isDense: true,
                      ),
                      onChanged: (v) => q['choice$key'] = v,
                    ),
                  ),
                ],
              ),
            if (q['needsReview'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Cần kiểm tra câu hỏi/đáp án',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
