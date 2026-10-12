import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'dashboard_screen.dart' show DashboardScreen;
import 'practice_screen.dart' show ToeicHomeScreen;
import 'analysis_screen.dart' show ToeicPredictionScreen;
import 'admin_screen.dart' show AdminDashboardScreen;
import 'admin_exam_review_screen.dart' show AdminExamReviewScreen;

const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
final apiBaseUrl = configuredApiBaseUrl.isNotEmpty
    ? configuredApiBaseUrl
    : kIsWeb
    ? '${Uri.base.origin}/api'
    : 'http://10.0.2.2:5029/api';
final api = ToeicApi(apiBaseUrl);

const blue = Color(0xFF315CF5);
const navy = Color(0xFF172744);
const ink = Color(0xFF202B3C);
const muted = Color(0xFF7B8798);

class Question {
  const Question(
    this.number,
    this.part,
    this.prompt,
    this.choices,
    this.answer, {
    this.passage,
    this.id,
    this.passageImage,
  });
  final int number, part;
  final String prompt;
  final String? answer;
  final int? id;
  final List<String> choices;
  final String? passage;
  final String? passageImage;
}

const sampleQuestions = <Question>[
  Question(
    1,
    5,
    'The marketing team will present _____ proposal to the director tomorrow.',
    ['they', 'their', 'them', 'theirs'],
    'B',
  ),
  Question(
    2,
    5,
    'Please submit your travel receipts _____ the end of the month.',
    ['by', 'during', 'between', 'among'],
    'A',
  ),
  Question(
    3,
    5,
    'Ms. Durkin asked for volunteers to help _____ with the fitness program.',
    ['she', 'her', 'hers', 'herself'],
    'D',
  ),
  Question(4, 5, 'The new software allows employees to work more _____.', [
    'efficient',
    'efficiency',
    'efficiently',
    'efficientness',
  ], 'C'),
  Question(
    5,
    5,
    '_____ the weather was poor, the outdoor event attracted a large crowd.',
    ['Despite', 'Although', 'Because of', 'During'],
    'B',
  ),
  Question(
    6,
    6,
    'What is being announced?',
    [
      'A new product line',
      'A store reopening',
      'A change in hours',
      'A parking fee increase',
    ],
    'B',
    passage: 'Dear customers,\n\nOur downtown store will reopen on Monday after a complete renovation. The upgraded location features a larger showroom and additional parking. We look forward to welcoming you back.\n\nSincerely, Customer Relations',
  ),
  Question(
    7,
    6,
    'The word “upgraded” is closest in meaning to',
    ['improved', 'relocated', 'reduced', 'delayed'],
    'A',
    passage: 'Dear customers,\n\nOur downtown store will reopen on Monday after a complete renovation. The upgraded location features a larger showroom and additional parking. We look forward to welcoming you back.\n\nSincerely, Customer Relations',
  ),
  Question(
    8,
    7,
    'What is offered to new gym customers?',
    [
      'A free month of access',
      'Discounted annual membership',
      'Personal training',
      'Free exercise equipment',
    ],
    'A',
    passage: 'GLOBAL STRENGTH GYM\n\nTry our 30-day trial period and enjoy full access to all classes, equipment, and facilities. Sign up online with your contact information. You will only be charged if you continue as a member after the trial.',
  ),
  Question(
    9,
    7,
    'When will a customer pay a membership fee?',
    [
      'When signing up',
      'After the trial if they continue',
      'At the end of each class',
      'Before visiting the gym',
    ],
    'B',
    passage: 'GLOBAL STRENGTH GYM\n\nTry our 30-day trial period and enjoy full access to all classes, equipment, and facilities. Sign up online with your contact information. You will only be charged if you continue as a member after the trial.',
  ),
  Question(
    10,
    7,
    'How can a customer register for the trial?',
    [
      'By sending a letter',
      'By calling the manager',
      'On the gym website',
      'At a fitness class',
    ],
    'C',
    passage: 'GLOBAL STRENGTH GYM\n\nTry our 30-day trial period and enjoy full access to all classes, equipment, and facilities. Sign up online with your contact information. You will only be charged if you continue as a member after the trial.',
  ),
];

class PublishedExam {
  const PublishedExam({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.questionCount,
    this.section = 'Reading',
  });
  final int id, durationMinutes, questionCount;
  final String title;
  final String section;
}

class ToeicApi {
  ToeicApi(this.baseUrl);
  final String baseUrl;
  String? token;
  String displayName = 'Học viên';
  bool isAdmin = false;
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  String assetUrl(String path) =>
      baseUrl.replaceFirst(RegExp(r'/api/?$'), '') + path;

  Future<Map<String, dynamic>> login(String email, String password) =>
      _authenticate('login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) => _authenticate('register', {
    'displayName': name,
    'email': email,
    'password': password,
  });

  Future<Map<String, dynamic>> _authenticate(
    String action,
    Map<String, String> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/$action'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200)
      throw Exception(result['message'] ?? 'Không thể đăng nhập.');
    token = result['token'] as String;
    final user = result['user'] as Map<String, dynamic>;
    displayName = user['displayName'] as String;
    isAdmin = (user['roles'] as List).contains('Admin');
    return result;
  }

  Future<Map<String, dynamic>> importExam(
    String fileName,
    Uint8List bytes,
    String title,
    String section,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/exams/import'),
    )..headers['Authorization'] = 'Bearer ${token ?? ''}';
    request.fields['title'] = title;
    request.fields['section'] = section;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không thể nhập đề thi.');
    }
    return data;
  }

  Future<List<PublishedExam>> listExams({String? section}) async {
    final uri = Uri.parse(
      '$baseUrl/exams',
    ).replace(queryParameters: section == null ? null : {'section': section});
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200)
      throw Exception('Không tải được danh sách đề.');
    return (jsonDecode(response.body) as List)
        .map(
          (e) => PublishedExam(
            id: e['id'] as int,
            title: e['title'] as String,
            durationMinutes: e['durationMinutes'] as int,
            questionCount: e['questionCount'] as int,
            section: e['section'] as String? ?? 'Reading',
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> loadAdminExam(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/exams/$id'),
      headers: headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200)
      throw Exception(data['message'] ?? 'Không tải được đề thi.');
    return data;
  }

  Future<List<Map<String, dynamic>>> listAdminExams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/exams'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = data is Map<String, dynamic> ? data['message'] : null;
      throw Exception(message ?? 'Không tải được danh sách đề thi.');
    }
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> saveAdminExamReview(
    int id,
    List<Map<String, dynamic>> questions,
    bool publish,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/exams/$id/review'),
      headers: headers,
      body: jsonEncode({'questions': questions, 'publish': publish}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200)
      throw Exception(data['message'] ?? 'Không lưu được đề thi.');
    return data;
  }

  Future<(int, DateTime, List<Question>)> startExam(PublishedExam exam) async {
    final detail = await http
        .get(Uri.parse('$baseUrl/exams/${exam.id}'), headers: headers)
        .timeout(const Duration(seconds: 8));
    if (detail.statusCode != 200)
      throw Exception('Không tải được nội dung đề.');
    final data = jsonDecode(detail.body) as Map<String, dynamic>;
    final items = (data['questions'] as List).map((raw) {
      final q = raw as Map<String, dynamic>;
      final choices = (q['choices'] as List).cast<String>();
      return Question(
        q['number'] as int,
        q['part'] as int,
        q['prompt'] as String,
        choices,
        null,
        id: q['id'] as int,
        passage: q['passage'] as String?,
        passageImage: q['passageImage'] as String?,
      );
    }).toList();
    final start = await http
        .post(
          Uri.parse('$baseUrl/exams/${exam.id}/start'),
          headers: headers,
          body: '{}',
        )
        .timeout(const Duration(seconds: 8));
    if (start.statusCode != 200) throw Exception('Không thể bắt đầu đề thi.');
    final session = jsonDecode(start.body) as Map<String, dynamic>;
    return (
      session['id'] as int,
      DateTime.parse(session['deadline'] as String),
      items,
    );
  }

  Future<Map<String, dynamic>> submit(
    int examId,
    int attemptId,
    List<Question> questions,
    Map<int, String> answers,
  ) async {
    final payload = {
      'attemptId': attemptId,
      'answers': [
        for (final q in questions)
          if (q.id != null && answers.containsKey(q.number))
            {'questionId': q.id, 'answer': answers[q.number]},
      ],
    };
    final response = await http
        .post(
          Uri.parse('$baseUrl/exams/$examId/submit'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200)
      throw Exception('Không gửi được bài thi: ${response.body}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

void main() => runApp(const ToeicApp());

class ToeicApp extends StatelessWidget {
  const ToeicApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TOEIC Practice',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    ),
    home: api.token == null ? const LoginScreen() : const HomeScreen(),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registerMode = false, busy = false, hidePassword = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (registerMode) {
        await api.register(name.text.trim(), email.text.trim(), password.text);
      } else {
        await api.login(email.text.trim(), password.text);
      }
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (dashboardContext) => DashboardScreen(
              displayName: api.displayName,
              onPracticeTap: () => Navigator.push(
                dashboardContext,
                MaterialPageRoute(
                  builder: (practiceContext) => ToeicHomeScreen(
                    displayName: api.displayName,
                    isAdmin: api.isAdmin,
                    readingExamList: _publishedExamList(
                      practiceContext,
                      'Reading',
                    ),
                    listeningExamList: _publishedExamList(
                      practiceContext,
                      'Listening',
                    ),
                    onNavigateHome: () => Navigator.pop(practiceContext),
                    onOpenExams: () => Navigator.push(
                      practiceContext,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                  ),
                ),
              ),
              onAnalysisTap: () => Navigator.push(
                dashboardContext,
                MaterialPageRoute(
                  builder: (analysisContext) => ToeicPredictionScreen(
                    isAdmin: api.isAdmin,
                    onNavigateHome: () => Navigator.pop(analysisContext),
                    onNavigatePractice: () {
                      Navigator.pop(analysisContext);
                      Navigator.push(
                        dashboardContext,
                        MaterialPageRoute(
                          builder: (practiceContext) => ToeicHomeScreen(
                            displayName: api.displayName,
                            isAdmin: api.isAdmin,
                            readingExamList: _publishedExamList(
                              practiceContext,
                              'Reading',
                            ),
                            listeningExamList: _publishedExamList(
                              practiceContext,
                              'Listening',
                            ),
                            onNavigateHome: () =>
                                Navigator.pop(practiceContext),
                            onOpenExams: () => Navigator.push(
                              practiceContext,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              isAdmin: api.isAdmin,
              onAdminTap: api.isAdmin
                  ? () => Navigator.push(
                      dashboardContext,
                      MaterialPageRoute(
                        builder: (adminContext) => AdminDashboardScreen(
                          displayName: api.displayName,
                          onImport: api.importExam,
                          loadAdminExams: api.listAdminExams,
                          onReviewExam: (examId) async {
                            await Navigator.push<bool>(
                              adminContext,
                              MaterialPageRoute(
                                builder: (_) => AdminExamReviewScreen(
                                  examId: examId,
                                  loadExam: api.loadAdminExam,
                                  saveReview: api.saveAdminExamReview,
                                ),
                              ),
                            );
                          },
                          onNavigateDashboard: () =>
                              Navigator.pop(adminContext),
                          onNavigatePractice: () {
                            Navigator.pop(adminContext);
                            Navigator.push(
                              dashboardContext,
                              MaterialPageRoute(
                                builder: (practiceContext) => ToeicHomeScreen(
                                  displayName: api.displayName,
                                  isAdmin: api.isAdmin,
                                  readingExamList: _publishedExamList(
                                    practiceContext,
                                    'Reading',
                                  ),
                                  listeningExamList: _publishedExamList(
                                    practiceContext,
                                    'Listening',
                                  ),
                                  onNavigateHome: () =>
                                      Navigator.pop(practiceContext),
                                  onOpenExams: () => Navigator.push(
                                    practiceContext,
                                    MaterialPageRoute(
                                      builder: (_) => const HomeScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          onNavigateAnalysis: () {
                            Navigator.pop(adminContext);
                            Navigator.push(
                              dashboardContext,
                              MaterialPageRoute(
                                builder: (analysisContext) =>
                                    ToeicPredictionScreen(
                                      isAdmin: api.isAdmin,
                                      onNavigateHome: () =>
                                          Navigator.pop(analysisContext),
                                    ),
                              ),
                            );
                          },
                          onLogout: () {
                            api.token = null;
                            api.isAdmin = false;
                            Navigator.pushAndRemoveUntil(
                              dashboardContext,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (_) => false,
                            );
                          },
                        ),
                      ),
                    )
                  : null,
              onLogout: () {
                api.token = null;
                Navigator.pushAndRemoveUntil(
                  dashboardContext,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.auto_stories_rounded, color: blue, size: 54),
            const SizedBox(height: 12),
            Text(
              registerMode ? 'Tạo tài khoản' : 'Chào mừng trở lại',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              registerMode
                  ? 'Đăng ký để bắt đầu luyện TOEIC'
                  : 'Đăng nhập để tiếp tục luyện TOEIC',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 26),
            Form(
              key: formKey,
              child: Column(
                children: [
                  if (registerMode)
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập họ tên'
                          : null,
                    ),
                  if (registerMode) const SizedBox(height: 14),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email không hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: password,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => hidePassword = !hidePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Mật khẩu cần ít nhất 8 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: busy ? null : submit,
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(registerMode ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() => registerMode = !registerMode),
              child: Text(
                registerMode
                    ? 'Đã có tài khoản? Đăng nhập'
                    : 'Chưa có tài khoản? Đăng ký',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENGLISH LAB',
                        style: TextStyle(
                          color: blue,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Luyện thi TOEIC',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Đăng xuất',
                    onPressed: () {
                      api.token = null;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [navy, blue]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'MỤC TIÊU 800+',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Mỗi ngày một\nbước gần hơn.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        height: 1.16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Luyện tập đúng lộ trình, tự tin chinh phục TOEIC.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          '01\nBài thi',
                          style: TextStyle(color: Colors.white, height: 1.6),
                        ),
                        SizedBox(width: 24),
                        Text(
                          '75\nPhút / bài',
                          style: TextStyle(color: Colors.white, height: 1.6),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_outward_rounded, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Đề thi Reading',
                style: TextStyle(
                  fontSize: 20,
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              FutureBuilder<List<PublishedExam>>(
                future: api.listExams(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty)
                    return const SizedBox.shrink();
                  return Column(
                    children: [
                      for (final exam in snapshot.data!)
                        _publishedExamCard(context, exam),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFE8EDF4)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: blue,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOEIC Reading · Practice 01',
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Trung cấp',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'MỚI',
                            style: TextStyle(
                              color: Color(0xFF28824F),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 16, color: muted),
                        SizedBox(width: 5),
                        Text(
                          sampleQuestions.length.toString() + ' câu mẫu',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        SizedBox(width: 17),
                        Icon(Icons.schedule_rounded, size: 16, color: muted),
                        SizedBox(width: 5),
                        Text(
                          '75 phút',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        SizedBox(width: 17),
                        Icon(Icons.menu_book_outlined, size: 16, color: muted),
                        SizedBox(width: 5),
                        Text(
                          'Reading',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuizScreen()),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Bắt đầu làm bài',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Cấu trúc bài thi',
                style: TextStyle(
                  fontSize: 20,
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              _part(
                '5',
                'Incomplete Sentences',
                '30 câu · Ngữ pháp & từ vựng',
                Icons.short_text_rounded,
                const Color(0xFFEAF0FF),
              ),
              const SizedBox(height: 9),
              _part(
                '6',
                'Text Completion',
                '16 câu · Hoàn thành đoạn văn',
                Icons.subject_rounded,
                const Color(0xFFE8F7F2),
              ),
              const SizedBox(height: 9),
              _part(
                '7',
                'Reading Comprehension',
                '54 câu · Đọc hiểu văn bản',
                Icons.menu_book_rounded,
                const Color(0xFFFFF2E8),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _publishedExamList(BuildContext context, String section) =>
    FutureBuilder<List<PublishedExam>>(
      future: api.listExams(section: section),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!
              .map((exam) => _publishedExamCard(context, exam))
              .toList(),
        );
      },
    );

Widget _publishedExamCard(BuildContext context, PublishedExam exam) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exam.title,
            style: const TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${exam.questionCount} câu · ${exam.durationMinutes} phút',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  final session = await api.startExam(exam);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        questions: session.$3,
                        title: exam.title,
                        durationMinutes: exam.durationMinutes,
                        deadline: session.$2,
                        examId: exam.id,
                        attemptId: session.$1,
                      ),
                    ),
                  );
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu làm bài'),
              style: FilledButton.styleFrom(backgroundColor: blue),
            ),
          ),
        ],
      ),
    );

Widget _part(
  String n,
  String title,
  String subtitle,
  IconData icon,
  Color bg,
) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE8EDF4)),
  ),
  child: Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: blue),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PART ' + n,
              style: const TextStyle(
                color: blue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
      const Icon(Icons.chevron_right_rounded, color: muted),
    ],
  ),
);

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    this.questions = sampleQuestions,
    this.title = 'TOEIC Reading · Practice 01',
    this.durationMinutes = 75,
    this.deadline,
    this.examId,
    this.attemptId,
  });
  final List<Question> questions;
  final String title;
  final int durationMinutes;
  final DateTime? deadline;
  final int? examId, attemptId;
  @override
  State<QuizScreen> createState() => _QuizState();
}

class _QuizState extends State<QuizScreen> {
  final Map<int, String> answers = {};
  bool _finishing = false;
  int index = 0;
  late final List<Question> questions = widget.questions;
  late int seconds;
  Timer? timer;
  Question get q => questions[index];

  @override
  void initState() {
    super.initState();
    seconds = widget.deadline == null
        ? widget.durationMinutes * 60
        : widget.deadline!
              .difference(DateTime.now())
              .inSeconds
              .clamp(0, widget.durationMinutes * 60);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds > 0) {
        setState(() => seconds--);
      } else {
        _finish(auto: true);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get clock =>
      (seconds ~/ 3600).toString().padLeft(2, '0') +
      ':' +
      ((seconds % 3600) ~/ 60).toString().padLeft(2, '0') +
      ':' +
      (seconds % 60).toString().padLeft(2, '0');

  Future<void> _finish({bool auto = false}) async {
    if (_finishing) return;
    _finishing = true;
    if (!auto) {
      final unanswered = questions
          .where((question) => !answers.containsKey(question.number))
          .length;
      final readyToConfirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(unanswered > 0 ? 'Câu trả lời chưa hoàn tất' : 'Nộp bài thi?'),
          content: unanswered > 0
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    border: Border.all(color: Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Còn $unanswered câu chưa chọn đáp án. Bạn có muốn tiếp tục nộp bài không?',
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                )
              : Text('Bạn đã trả lời đủ ${questions.length} câu. Bạn có muốn nộp bài không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Quay lại làm bài'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nộp bài'),
            ),
          ],
        ),
      );
      if (readyToConfirm != true) {
        _finishing = false;
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xác nhận nộp bài'),
          content: Text(unanswered > 0
              ? 'B\u1ea1n v\u1eabn c\u00f2n $unanswered c\u00e2u ch\u01b0a ch\u1ecdn. X\u00e1c nh\u1eadn n\u1ed9p b\u00e0i ngay b\u00e2y gi\u1edd?'
              : 'Bạn chắc chắn muốn nộp bài và xem kết quả?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Kiểm tra lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xác nhận nộp'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _finishing = false;
        return;
      }
    }
    timer?.cancel();
    Map<String, dynamic>? result;
    try {
      if (widget.examId != null && widget.attemptId != null) {
        result = await api.submit(
          widget.examId!,
          widget.attemptId!,
          questions,
          answers,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      _finishing = false;
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          answers: Map.of(answers),
          questions: questions,
          serverResult: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐANG LÀM BÀI',
            style: TextStyle(
              color: blue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          Text(
            widget.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: blue, size: 17),
              const SizedBox(width: 5),
              Text(clock, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        LinearProgressIndicator(
          value: (index + 1) / questions.length,
          minHeight: 3,
          color: blue,
          backgroundColor: const Color(0xFFE5EAF2),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  _tag('PART ' + q.part.toString()),
                  const Spacer(),
                  Text(
                    'Câu ' +
                        q.number.toString() +
                        ' / ' +
                        questions.length.toString(),
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (q.passage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐOẠN VĂN',
                        style: TextStyle(
                          color: blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        q.passage!,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 14,
                          height: 1.65,
                        ),
                      ),
                      if (q.passageImage != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            api.assetUrl(q.passageImage!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUESTION ' + q.number.toString(),
                      style: const TextStyle(
                        color: blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      q.prompt,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 18,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < 4; i++)
                      _choice(String.fromCharCode(65 + i), q.choices[i]),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Text(
                    'Danh sách câu',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    answers.length.toString() + ' đã trả lời',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (var i = 0; i < questions.length; i++)
                    InkWell(
                      onTap: () => setState(() => index = i),
                      child: Container(
                        width: 38,
                        height: 37,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == index
                              ? blue
                              : (answers.containsKey(questions[i].number)
                                    ? const Color(0xFFE7F5EC)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: i == index ? blue : const Color(0xFFE3E9F1),
                          ),
                        ),
                        child: Text(
                          (i + 1).toString(),
                          style: TextStyle(
                            color: i == index ? Colors.white : muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9EDF3))),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: index > 0 ? () => setState(() => index--) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Trước'),
              ),
              const Spacer(),
              Text(
                (index + 1).toString() + ' / ' + questions.length.toString(),
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const Spacer(),
              if (index < questions.length - 1)
                FilledButton.icon(
                  onPressed: () => setState(() => index++),
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Tiếp'),
                  iconAlignment: IconAlignment.end,
                  style: FilledButton.styleFrom(backgroundColor: blue),
                )
              else
                FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(backgroundColor: blue),
                  child: const Text('Nộp bài'),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _choice(String letter, String text) {
    final selected = answers[q.number] == letter;
    return InkWell(
      onTap: () => setState(() => answers[q.number] = letter),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? blue : const Color(0xFFE5EAF1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? blue : const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? Colors.white : muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: ink, fontSize: 14),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: blue, size: 19),
          ],
        ),
      ),
    );
  }
}

Widget _tag(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: const Color(0xFFEAF0FF),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    text,
    style: const TextStyle(
      color: blue,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: .5,
    ),
  ),
);

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.answers,
    required this.questions,
    this.serverResult,
  });
  final Map<int, String> answers;
  final List<Question> questions;
  final Map<String, dynamic>? serverResult;

  @override
  Widget build(BuildContext context) {
    final localCorrect = questions
        .where((q) => q.answer != null && answers[q.number] == q.answer)
        .length;
    final correct = serverResult?['correctCount'] as int? ?? localCorrect;
    final total = serverResult?['total'] as int? ?? questions.length;
    final unanswered =
        serverResult?['unanswered'] as int? ?? total - answers.length;
    final breakdown = (serverResult?['breakdown'] as List?)
        ?.cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kết quả bài thi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [navy, blue]),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .4),
                      width: 4,
                    ),
                  ),
                  child: Text(
                    (total == 0 ? 0 : correct * 100 ~/ total).toString() + '%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bài thi đã hoàn thành',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Bạn trả lời đúng ' +
                      correct.toString() +
                      '/' +
                      total.toString() +
                      ' câu',
                  style: TextStyle(color: Colors.white.withValues(alpha: .8)),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _metric(correct.toString(), 'Đúng'),
                    _metric((answers.length - correct).toString(), 'Sai'),
                    _metric(unanswered.toString(), 'Bỏ trống'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Phân tích kết quả',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final part in [5, 6, 7])
            _partResult(
              part,
              breakdown?.where((e) => e['part'] == part).firstOrNull,
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 49,
            child: FilledButton.icon(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Về trang chủ'),
              style: FilledButton.styleFrom(backgroundColor: blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partResult(int part, Map<String, dynamic>? remote) {
    final qs = questions.where((q) => q.part == part).toList();
    final total = remote?['total'] as int? ?? qs.length;
    final score =
        remote?['correct'] as int? ??
        qs
            .where((q) => q.answer != null && answers[q.number] == q.answer)
            .length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _tag('PART ' + part.toString()),
              const Spacer(),
              Text(
                score.toString() + '/' + total.toString() + ' câu đúng',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 11),
          LinearProgressIndicator(
            value: total == 0 ? 0 : score / total,
            minHeight: 6,
            color: blue,
            backgroundColor: const Color(0xFFEDF0F5),
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}

Widget _metric(String value, String label) => Expanded(
  child: Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .72),
          fontSize: 11,
        ),
      ),
    ],
  ),
);
