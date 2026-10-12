// ============================================================================
// TOEIC Mastery Mobile - Flutter (Dart) Source Code
// Chuyển đổi hoàn chỉnh từ giao diện TOEIC Master sang mã nguồn Flutter chuẩn
// Đã kiểm tra tương thích: Flutter 3.19+ / Dart 3.3+ (Null Safety)
// ============================================================================

import 'package:flutter/material.dart';

// 1. THEME & DESIGN TOKENS (Hệ thống màu & Typography)
// ============================================================================
class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF004AC6);
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBE1FF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF855300);
  static const Color secondaryContainer = Color(0xFFFEA619);
  static const Color secondaryLight = Color(0xFFFFDDB8);

  static const Color tertiary = Color(0xFF007D55);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color tertiaryContainer = Color(0xFF006242);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF434655);
  static const Color textMuted = Color(0xFF737686);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      fontFamily: 'Plus Jakarta Sans', // Hoặc sử dụng fallback sans-serif
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    );
  }
}

// ============================================================================
// 2. DATA MODELS (Mô hình dữ liệu)
// ============================================================================
class TaskItem {
  final String id;
  final String title;
  final String subtitle;
  final String xpReward;
  final bool isCompleted;
  final bool hasActionButton;

  const TaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    this.isCompleted = false,
    this.hasActionButton = false,
  });
}

class AiRecommendationItem {
  final String category;
  final String title;
  final String description;
  final String duration;
  final String benefitText;
  final IconData icon;
  final Color badgeColor;
  final Color iconColor;

  const AiRecommendationItem({
    required this.category,
    required this.title,
    required this.description,
    required this.duration,
    required this.benefitText,
    required this.icon,
    required this.badgeColor,
    required this.iconColor,
  });
}

// ============================================================================
// 3. MAIN DASHBOARD SCREEN (Màn hình chính)
// ============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.displayName = 'Học viên',
    this.onPracticeTap,
    this.onAnalysisTap,
    this.isAdmin = false,
    this.onAdminTap,
    this.onLogout,
  });
  final String displayName;
  final VoidCallback? onPracticeTap;
  final VoidCallback? onAnalysisTap;
  final bool isAdmin;
  final VoidCallback? onAdminTap;
  final VoidCallback? onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;

  // Mock state cho các nhiệm vụ hàng ngày
  final List<TaskItem> _tasks = [
    const TaskItem(
      id: 'task_1',
      title: 'Part 2: 15 câu Hỏi – Đáp nhanh',
      subtitle: 'Hoàn thành',
      xpReward: '+20 XP',
      isCompleted: true,
    ),
    const TaskItem(
      id: 'task_2',
      title: 'Part 5: 20 câu Ngữ pháp giới từ',
      subtitle: 'Chưa làm',
      xpReward: '+25 XP',
      isCompleted: false,
      hasActionButton: true,
    ),
    const TaskItem(
      id: 'task_3',
      title: 'Flashcards: Office & Workplace',
      subtitle: '25 từ vựng • +15 từ mới',
      xpReward: '',
      isCompleted: true,
    ),
    const TaskItem(
      id: 'task_4',
      title: '1 Bài nghe ngắn Part 4',
      subtitle: 'Short Talks (Store Announcement)',
      xpReward: '',
      isCompleted: true,
    ),
  ];

  final List<AiRecommendationItem> _recommendations = [
    const AiRecommendationItem(
      category: 'KHẮC PHỤC ĐIỂM YẾU',
      title: 'Bẫy đồng âm Part 1 & Part 2',
      description: 'Bạn thường nhầm lẫn giữa các âm /p/ và /b/ cũng như câu hỏi gián tiếp Yes/No. 10 bài tập phản xạ nhanh...',
      duration: '15 phút',
      benefitText: 'Tăng ~15 điểm Listening',
      icon: Icons.warning_amber_rounded,
      badgeColor: AppTheme.errorContainer,
      iconColor: AppTheme.error,
    ),
    const AiRecommendationItem(
      category: 'CHIẾN THUẬT THỜI GIAN',
      title: 'Skimming Part 7 bài đọc đôi',
      description: 'Tối ưu kỹ thuật đọc lướt câu hỏi liên kết thông tin giữa Email & Bảng thông báo. Tiết kiệm 4 phút cho toàn...',
      duration: '20 phút',
      benefitText: 'Giảm 40% lỗi liên kết',
      icon: Icons.psychology_outlined,
      badgeColor: AppTheme.surfaceContainerHigh,
      iconColor: AppTheme.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: CustomTopHeader(
        displayName: widget.displayName,
        onLogout: widget.onLogout,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Dải huy hiệu chuỗi & XP
              const GamificationQuickStats(),
              const SizedBox(height: 16),

              // 2. Thẻ mục tiêu điểm số Bento Hero
              const TargetScoreHeroCard(
                targetScore: '750+ TOEIC',
                daysLeft: 28,
                predictedScore: 685,
                maxScore: 990,
                scoreDelta: '+45 điểm',
                progressPercent: 0.76,
                listeningScore: 360,
                readingScore: 325,
              ),
              const SizedBox(height: 24),

              // 3. Danh sách nhiệm vụ hàng ngày
              DailyTasksSection(tasks: _tasks),
              const SizedBox(height: 24),

              // 4. Đề xuất từ AI Tutor
              AiTutorSection(recommendations: _recommendations),
              const SizedBox(height: 20),

              // 5. Thẻ sự kiện cuối tuần
              const WeekendEventBanner(),
              const SizedBox(height: 20),

              // 6. Thẻ lời khuyên hôm nay (Ảnh nền & Audio button)
              const DailyTipCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentTabIndex,
        isAdmin: widget.isAdmin,
        onTap: (index) {
          if (index == 1) {
            widget.onPracticeTap?.call();
            return;
          }
          if (index == 2) {
            widget.onAnalysisTap?.call();
            return;
          }
          if (index == 3 && widget.isAdmin) {
            widget.onAdminTap?.call();
            return;
          }
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}

// ============================================================================
// 4. COMPONENT WIDGETS (Các widget thành phần chuẩn)
// ============================================================================

/// AppBar Header với Lời chào, Chuỗi ngày và Avatar cá nhân
class CustomTopHeader extends StatelessWidget implements PreferredSizeWidget {
  const CustomTopHeader({super.key, required this.displayName, this.onLogout});
  final String displayName;
  final VoidCallback? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface.withOpacity(0.95),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Icon ứng dụng
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B4DFF), Color(0xFF382BF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4DFF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),

              // Lời chào & Tên học viên
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHÀO BUỔI SÁNG,',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Chip Chuỗi 14 ngày
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '14 Ngày',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              IconButton(
                onPressed: onLogout,
                tooltip: 'Đăng xuất',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dải huy hiệu gamification (Chuỗi ngày, XP, Đá quý/Gem)
class GamificationQuickStats extends StatelessWidget {
  const GamificationQuickStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Chuỗi ngày liên tiếp
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDDB8).withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFF855300),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                '14 Ngày liên tiếp',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF855300),
                ),
              ),
            ],
          ),
        ),

        // Nhóm điểm XP & Kim cương
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.stars_rounded,
                    color: AppTheme.primaryContainer,
                    size: 17,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '1,420 XP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.diamond_outlined,
                    color: AppTheme.tertiary,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '85',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Thẻ Bento Master hiển thị Dự đoán điểm số & Mục tiêu
class TargetScoreHeroCard extends StatelessWidget {
  final String targetScore;
  final int daysLeft;
  final int predictedScore;
  final int maxScore;
  final String scoreDelta;
  final double progressPercent;
  final int listeningScore;
  final int readingScore;

  const TargetScoreHeroCard({
    super.key,
    required this.targetScore,
    required this.daysLeft,
    required this.predictedScore,
    required this.maxScore,
    required this.scoreDelta,
    required this.progressPercent,
    required this.listeningScore,
    required this.readingScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004AC6).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hiệu ứng ánh sáng nền trang trí
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryContainer.withOpacity(0.12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Badge Mục tiêu & Số ngày còn lại
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.tertiaryFixed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MỤC TIÊU: $targetScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alarm_rounded,
                            color: AppTheme.tertiaryFixed,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Còn $daysLeft ngày',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hàng 2: Dự đoán điểm số & Tăng trưởng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DỰ ĐOÁN HIỆN TẠI',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$predictedScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ $maxScore',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Badge tăng trưởng
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007D55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scoreDelta,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hàng 3: Thanh tiến độ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ chặng ôn thi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  width: double.infinity,
                  padding: const EdgeInsets.all(1.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryFixed,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF6FFBBE), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Hàng 4: Chi tiết điểm Listening & Reading
                Row(
                  children: [
                    Expanded(
                      child: _buildSkillCard(
                        skillName: 'Listening',
                        score: '$listeningScore',
                        maxScore: '495',
                        statusText: 'Tăng đều',
                        statusIcon: Icons.check_circle_rounded,
                        accentColor: AppTheme.tertiaryFixed,
                        icon: Icons.headphones_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSkillCard(
                        skillName: 'Reading',
                        score: '$readingScore',
                        maxScore: '495',
                        statusText: 'Tăng tốc Part 7',
                        statusIcon: Icons.speed_rounded,
                        accentColor: const Color(0xFFFFB95F),
                        icon: Icons.auto_stories_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard({
    required String skillName,
    required String score,
    required String maxScore,
    required String statusText,
    required IconData statusIcon,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skillName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: accentColor, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/$maxScore',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(statusIcon, color: accentColor, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Phần Nhiệm vụ hôm nay với Checklist và nút 'Luyện ngay'
class DailyTasksSection extends StatelessWidget {
  final List<TaskItem> tasks;

  const DailyTasksSection({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    int completedCount = tasks.where((t) => t.isCompleted).length;

    return Column(
      children: [
        // Tiêu đề phần
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.checklist_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Nhiệm vụ hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$completedCount / ${tasks.length} Đạt',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách thẻ nhiệm vụ
        ...tasks.map((task) => _buildTaskItem(context, task)).toList(),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskItem task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? AppTheme.surfaceContainerLow
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: task.isCompleted
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon trạng thái (hoàn thành hoặc chưa làm)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted
                  ? AppTheme.tertiary
                  : AppTheme.primaryLight,
            ),
            child: Icon(
              task.isCompleted
                  ? Icons.check_rounded
                  : Icons.assignment_turned_in_rounded,
              color: task.isCompleted ? Colors.white : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Nội dung nhiệm vụ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      task.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: task.isCompleted
                            ? AppTheme.tertiary
                            : AppTheme.secondary,
                      ),
                    ),
                    if (task.xpReward.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? const Color(0xFF6FFBBE)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.xpReward,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: task.isCompleted
                                ? const Color(0xFF002113)
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Widget bên phải (Nút Luyện ngay hoặc Huy hiệu Đã đạt)
          if (task.hasActionButton)
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bắt đầu làm: ${task.title}'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Luyện ngay',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            )
          else
            const Icon(
              Icons.verified_rounded,
              color: AppTheme.tertiary,
              size: 20,
            ),
        ],
      ),
    );
  }
}

/// Phần Đề xuất từ AI Tutor với các Thẻ phân tích điểm yếu & chiến thuật
class AiTutorSection extends StatelessWidget {
  final List<AiRecommendationItem> recommendations;

  const AiTutorSection({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.smart_toy_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Đề xuất từ AI Tutor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Text(
              'Cá nhân hoá',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...recommendations.map(
          (item) => _buildRecommendationCard(context, item),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    AiRecommendationItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Category + Title + Duration
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: item.iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.duration,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mô tả chi tiết
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Footer: Lợi ích đạt được & Nút Bắt đầu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    item.category.contains('ĐIỂM YẾU')
                        ? Icons.bolt_rounded
                        : Icons.insights_rounded,
                    color: item.category.contains('ĐIỂM YẾU')
                        ? AppTheme.primary
                        : AppTheme.tertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.benefitText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: item.category.contains('ĐIỂM YẾU')
                          ? AppTheme.primary
                          : AppTheme.tertiary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mở bài học: ${item.title}'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      'Bắt đầu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner Sự kiện cuối tuần với Gradient vàng nâu
class WeekendEventBanner extends StatelessWidget {
  const WeekendEventBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEA619), Color(0xFF855300)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF855300).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.military_tech_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SỰ KIỆN CUỐI TUẦN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mini Mock Test 50 Câu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đo lường năng lực chuẩn cấu trúc ETS • Thưởng +100 Gem',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Nút Tham gia Chủ Nhật
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đăng ký Mini Mock Test 50 Câu!'),
                  backgroundColor: Color(0xFF855300),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Text(
                    'Tham gia',
                    style: TextStyle(
                      color: Color(0xFF855300),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Chủ Nhật',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
}

/// Thẻ Lời khuyên hôm nay (Ảnh nền học tập & Nút Play Audio)
class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=600&auto=format&fit=crop&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF283044).withOpacity(0.92),
              const Color(0xFF283044).withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'LỜI KHUYÊN HÔM NAY',
                  style: TextStyle(
                    color: AppTheme.tertiaryFixed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '15 phút mỗi ngày làm nên kỳ tích',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            // Nút Play tròn mờ kiểu Frosted Glass
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh điều hướng dưới cùng (BottomNavigationBar) 4 Tab chuẩn
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Tổng quan',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.menu_book_rounded,
                label: 'Luyện thi',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.insights_rounded,
                label: 'Phân tích',
              ),
              if (isAdmin)
                _buildNavItem(
                  index: 3,
                  icon: Icons.manage_accounts_rounded,
                  label: 'Quản trị',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDBE1FF).withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
