// ==============================================================================
// TOEIC Mastery Mobile - AI Score Prediction & Diagnostic Screen
// Tương thích: Flutter 3.0+ | Dart 3.0+ | Null-Safety
// Cách chạy: Dán trực tiếp vào file lib/main.dart trong dự án Flutter của bạn.
// ==============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

// =================================================================
// MODEL DỮ LIỆU
// ==============================================================================

class TrendPoint {
  final String label;
  final int score;
  final bool isLatest;

  const TrendPoint({
    required this.label,
    required this.score,
    this.isLatest = false,
  });
}

class PartAccuracyData {
  final int partNumber;
  final String title;
  final int percentage;
  final String feedback;
  final IconData icon;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final Color progressColor;
  final Color iconColor;
  final bool isCritical;

  const PartAccuracyData({
    required this.partNumber,
    required this.title,
    required this.percentage,
    required this.feedback,
    required this.icon,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.progressColor,
    required this.iconColor,
    this.isCritical = false,
  });
}

class MistakeItemData {
  final String category;
  final String countBadge;
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color badgeTextColor;

  const MistakeItemData({
    required this.category,
    required this.countBadge,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeTextColor,
  });
}

// ==============================================================================
// MÀN HÌNH CHÍNH (TOEIC PREDICTION SCREEN)
// ==============================================================================

class ToeicPredictionScreen extends StatefulWidget {
  const ToeicPredictionScreen({
    super.key,
    this.onNavigateHome,
    this.onNavigatePractice,
    this.isAdmin = false,
  });
  final VoidCallback? onNavigateHome;
  final VoidCallback? onNavigatePractice;
  final bool isAdmin;

  @override
  State<ToeicPredictionScreen> createState() => _ToeicPredictionScreenState();
}

class _ToeicPredictionScreenState extends State<ToeicPredictionScreen> {
  int _currentBottomNavIndex = 2; // Mặc định tab 'Phân tích'

  // Dữ liệu xu hướng điểm
  final List<TrendPoint> _trendPoints = const [
    TrendPoint(label: 'Test 1', score: 590),
    TrendPoint(label: 'Test 2', score: 630),
    TrendPoint(label: 'Test 3', score: 650),
    TrendPoint(label: 'Test 4', score: 670),
    TrendPoint(label: 'Gần nhất', score: 685, isLatest: true),
  ];

  // Dữ liệu 7 phần thi (Part 1 -> Part 7)
  final List<PartAccuracyData> _partAccuracies = const [
    PartAccuracyData(
      partNumber: 1,
      title: 'Mô tả hình ảnh',
      percentage: 85,
      feedback: 'Rất tốt – Nắm chắc từ vựng miêu tả hành động và vị trí',
      icon: Icons.verified,
      badgeBgColor: Color(0xFFEAEDFF),
      badgeTextColor: Color(0xFF004AC6),
      progressColor: Color(0xFF4EDEA3),
      iconColor: Color(0xFF005236),
    ),
    PartAccuracyData(
      partNumber: 2,
      title: 'Hỏi & Đáp',
      percentage: 78,
      feedback: 'Tốt – Phản xạ câu hỏi trực tiếp vững vàng',
      icon: Icons.thumb_up_alt_outlined,
      badgeBgColor: Color(0xFFEAEDFF),
      badgeTextColor: Color(0xFF004AC6),
      progressColor: Color(0xFF007D55),
      iconColor: Color(0xFF006242),
    ),
    PartAccuracyData(
      partNumber: 3,
      title: 'Đoạn hội thoại',
      percentage: 65,
      feedback: 'Cần cải thiện tốc độ bắt từ khóa (Keywords)',
      icon: Icons.speed,
      badgeBgColor: Color(0xFFEAEDFF),
      badgeTextColor: Color(0xFF004AC6),
      progressColor: Color(0xFFFEA619),
      iconColor: Color(0xFF855300),
    ),
    PartAccuracyData(
      partNumber: 4,
      title: 'Bài nói chuyện ngắn',
      percentage: 62,
      feedback: 'Khá yếu phần câu hỏi suy luận và ý ngụ ý người nói',
      icon: Icons.psychology_outlined,
      badgeBgColor: Color(0xFFEAEDFF),
      badgeTextColor: Color(0xFF004AC6),
      progressColor: Color(0xFFFFB95F),
      iconColor: Color(0xFF855300),
    ),
    PartAccuracyData(
      partNumber: 5,
      title: 'Điền vào câu',
      percentage: 75,
      feedback: 'Ngữ pháp ổn định, cần bổ sung cặp từ đồng nghĩa kinh tế',
      icon: Icons.spellcheck,
      badgeBgColor: Color(0xFFEAEDFF),
      badgeTextColor: Color(0xFF004AC6),
      progressColor: Color(0xFF4EDEA3),
      iconColor: Color(0xFF006242),
    ),
    PartAccuracyData(
      partNumber: 6,
      title: 'Điền đoạn văn',
      percentage: 68,
      feedback: 'Mức trung bình – Hay nhầm lẫn từ nối liên kết câu',
      icon: Icons.link,
      badgeBgColor: Color(0xFFEAEDFF),
      badgeTextColor: Color(0xFF004AC6),
      progressColor: Color(0xFFFEA619),
      iconColor: Color(0xFF855300),
    ),
    PartAccuracyData(
      partNumber: 7,
      title: 'Đọc hiểu đoạn văn',
      percentage: 54,
      feedback: 'Điểm yếu chí mạng – Thiếu thời gian làm bài đọc 3 đoạn (Triple Passages)',
      icon: Icons.flag,
      badgeBgColor: Color(0xFFFFDAD6),
      badgeTextColor: Color(0xFF93000A),
      progressColor: Color(0xFFBA1A1A),
      iconColor: Color(0xFFBA1A1A),
      isCritical: true,
    ),
  ];

  // Dữ liệu bẫy & lỗi sai
  final List<MistakeItemData> _mistakes = const [
    MistakeItemData(
      category: 'LỖI NGỮ PHÁP',
      countBadge: 'Sai 6 câu',
      title: 'Mệnh đề quan hệ rút gọn',
      description: 'Hay nhầm lẫn dạng V-ing (chủ động) và V-ed (bị động) trong câu phức.',
      icon: Icons.rule,
      iconBgColor: Color(0xFFFFDAD6),
      iconColor: Color(0xFF93000A),
      badgeTextColor: Color(0xFFBA1A1A),
    ),
    MistakeItemData(
      category: 'LỖI TỪ VỰNG',
      countBadge: 'Sai 4 câu',
      title: 'Cặp từ dễ gây nhầm lẫn',
      description: 'Phân biệt \'Affect\' (Động từ) và \'Effect\' (Danh từ/Động từ gây ra).',
      icon: Icons.menu_book_outlined,
      iconBgColor: Color(0xFFFFDDB8),
      iconColor: Color(0xFF2A1700),
      badgeTextColor: Color(0xFF855300),
    ),
    MistakeItemData(
      category: 'LỖI BẪY ĐỀ THI',
      countBadge: 'Part 2',
      title: 'Distractor câu hỏi Wh- questions',
      description:
          'Bẫy lặp âm giống câu hỏi và trả lời Yes/No cho câu hỏi Who/Where.',
      icon: Icons.cancel_outlined,
      iconBgColor: Color(0xFFDAE2FD),
      iconColor: Color(0xFF004AC6),
      badgeTextColor: Color(0xFF004AC6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: _buildCustomHeader(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Tiêu đề trang
            _buildPageHeader(),
            const SizedBox(height: 16),

            // 2. Thẻ Dự đoán Điểm (Hero Card)
            _buildScoreHeroCard(),
            const SizedBox(height: 20),

            // 3. Biểu đồ Xu hướng Tăng trưởng
            _buildGrowthTrendCard(),
            const SizedBox(height: 24),

            // 4. Độ chính xác từng Part (Part 1 - 7)
            _buildPartAccuracySection(),
            const SizedBox(height: 24),

            // 5. Phân tích bẫy & lỗi sai
            _buildMistakeAnalysisSection(),
            const SizedBox(height: 20),

            // 6. Lời khuyên từ huấn luyện viên AI
            _buildAiCoachCard(),
            const SizedBox(height: 20),

            // 7. Nhóm nút hành động chính (CTAs)
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================================
  // WIDGET CON: HEADER APP BAR
  // ============================================================================
  PreferredSizeWidget _buildCustomHeader(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFAF8FF).withOpacity(0.95),
      elevation: 0,
      scrolledUnderElevation: 2.0,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      toolbarHeight: 64,
      title: Row(
        children: [
          // Logo biểu tượng nón tốt nghiệp
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'CHÀO BUỔI SÁNG,',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF434655),
                  ),
                ),
                Text(
                  'Nguyễn Hòa',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF131B2E),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Huy hiệu chuỗi học tập (Streak Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFEF3C7)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFEA619),
                  size: 18,
                ),
                SizedBox(width: 4),
                Text(
                  '14 Ngày',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF684000),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Ảnh đại diện học viên (Avatar)
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFDAE2FD),
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET CON: TIÊU ĐỀ TRANG
  // ============================================================================
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AI PHÂN TÍCH CHUYÊN SÂU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF434655),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Dự Đoán Điểm Số',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131B2E),
              ),
            ),
          ],
        ),
        // Badge 'Cập nhật hôm nay'
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEDFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF007D55),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Cập nhật hôm nay',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF131B2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // WIDGET CON: HERO SCORE CARD (THẺ ĐIỂM DỰ ĐOÁN XANH GRADIENT)
  // ============================================================================
  Widget _buildScoreHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004AC6), Color(0xFF2563EB), Color(0xFF0053DB)],
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
          // Hiệu ứng vòng sáng trang trí mờ ở góc dưới phải
          Positioned(
            right: -24,
            bottom: -32,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hàng hiển thị điểm & khoảng ước lượng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Điểm TOEIC Dự Đoán
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Điểm TOEIC Dự Đoán',
                            style: TextStyle(
                              color: Color(0xFFEEEFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: const [
                            Text(
                              '685',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '/ 990',
                              style: TextStyle(
                                color: Color(0xFFD2D9F4),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Khoảng ước lượng
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          'Khoảng ước lượng',
                          style: TextStyle(
                            color: Color(0xFFEEEFFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '660 – 710',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Thanh tiến độ mục tiêu (Goal Progress)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(text: 'Mục tiêu: '),
                                TextSpan(
                                  text: '750 điểm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFDDB8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(
                                Icons.trending_up_rounded,
                                color: Color(0xFF6FFBBE),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Cách mục tiêu 65 điểm',
                                style: TextStyle(
                                  color: Color(0xFF6FFBBE),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Thanh thanh progress gradient
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 8,
                          color: Colors.white.withOpacity(0.2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.86, // (685 / 750 ~ 91% hoặc theo tỉ lệ giao diện)
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFFDDB8),
                                      Color(0xFF6FFBBE),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2 Thẻ Listening & Reading
                Row(
                  children: [
                    Expanded(
                      child: _buildSkillMetricChip(
                        icon: Icons.headphones_rounded,
                        title: 'Listening',
                        score: '360',
                        total: '495',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSkillMetricChip(
                        icon: Icons.menu_book_rounded,
                        title: 'Reading',
                        score: '325',
                        total: '495',
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

  Widget _buildSkillMetricChip({
    required IconData icon,
    required String title,
    required String score,
    required String total,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD2D9F4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' / $total',
                      style: const TextStyle(
                        color: Color(0xFFD2D9F4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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

  // ============================================================================
  // WIDGET CON: XU HƯỚNG TĂNG TRƯỞNG & BIỂU ĐỒ NATIVE CUSTOMPAINTER
  // ============================================================================
  Widget _buildGrowthTrendCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề biểu đồ & badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.show_chart_rounded,
                    color: Color(0xFF004AC6),
                    size: 22,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Xu Hướng Tăng Trưởng',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+95 điểm gần đây',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007D55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vùng vẽ biểu đồ Canvas (CustomPainter)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: ScoreTrendPainter(points: _trendPoints),
            ),
          ),
          const SizedBox(height: 10),

          // Nhãn điểm & tên bài test dưới trục hoành
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _trendPoints.map((pt) {
              final isLatest = pt.isLatest;
              return Column(
                children: [
                  Text(
                    '${pt.score}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isLatest ? FontWeight.w800 : FontWeight.w700,
                      color: isLatest
                          ? const Color(0xFF004AC6)
                          : const Color(0xFF131B2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pt.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
                      color: isLatest
                          ? const Color(0xFF004AC6)
                          : const Color(0xFF737686),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET CON: ĐỘ CHÍNH XÁC TỪNG PART (PART 1 -> PART 7)
  // ============================================================================
  Widget _buildPartAccuracySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF004AC6),
                  size: 22,
                ),
                SizedBox(width: 6),
                Text(
                  'Độ Chính Xác Từng Part',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            Text(
              '7 Phần thi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF737686),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Danh sách 7 card Part
        ..._partAccuracies.map(
          (part) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildPartAccuracyCard(part),
          ),
        ),
      ],
    );
  }

  Widget _buildPartAccuracyCard(PartAccuracyData part) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: part.isCritical
            ? const Color(0xFFFFDAD6).withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: part.isCritical
            ? Border.all(color: const Color(0xFFFFDAD6), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Part tag, tên part, và phần trăm %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: part.badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Part ${part.partNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: part.badgeTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    part.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: part.isCritical
                          ? const Color(0xFFBA1A1A)
                          : const Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (part.isCritical) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFBA1A1A),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${part.percentage}%',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: part.progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Thanh phần trăm Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 7,
              color: part.isCritical
                  ? const Color(0xFFFFDAD6)
                  : const Color(0xFFEAEDFF),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: part.percentage / 100.0,
                  child: Container(color: part.progressColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lời nhận xét đánh giá chi tiết
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(part.icon, size: 16, color: part.iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  part.feedback,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: part.isCritical
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: part.iconColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET CON: PHÂN TÍCH BẪY & LỖI SAI
  // ============================================================================
  Widget _buildMistakeAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề mục & badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.troubleshoot_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 22,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Phân Tích Bẫy & Lỗi Sai',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Cần khắc phục',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Danh sách các lỗi sai
          ..._mistakes.map(
            (mistake) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildMistakeItem(mistake),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeItem(MistakeItemData mistake) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: mistake.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(mistake.icon, color: mistake.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mistake.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF434655),
                      ),
                    ),
                    Text(
                      mistake.countBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mistake.badgeTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mistake.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mistake.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF434655),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET CON: LỜI KHUYÊN TỪ HUẤN LUYỆN VIÊN AI
  // ============================================================================
  Widget _buildAiCoachCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ảnh chân dung Huấn luyện viên
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Nội dung lời khuyên
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 15,
                      color: Color(0xFF004AC6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lời khuyên từ Huấn luyện viên AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF004AC6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '\"Chỉ cần tăng 35 điểm Part 7 bằng kỹ thuật Skimming, bạn sẽ vượt mốc 720+ ngay tuần tới!\"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF131B2E),
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET CON: CÁC NÚT HÀNH ĐỘNG (ACTION BUTTONS)
  // ============================================================================
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Nút chính: Khắc Phục Part 7 Ngay Lập Tức
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bắt đầu lộ trình luyện tập tăng tốc Part 7...',
                  ),
                  backgroundColor: Color(0xFF004AC6),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004AC6),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF004AC6).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bolt_rounded, size: 20),
                SizedBox(width: 6),
                Text(
                  'Khắc Phục Part 7 Ngay Lập Tức',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Nút phụ: Xuất Báo Cáo PDF Học Tập
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang tạo báo cáo học tập PDF...'),
                  backgroundColor: Color(0xFF131B2E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF131B2E),
              side: const BorderSide(color: Color(0xFFEAEDFF), width: 1.5),
              elevation: 1,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 19,
                  color: Color(0xFF737686),
                ),
                SizedBox(width: 6),
                Text(
                  'Xuất Báo Cáo PDF Học Tập',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // WIDGET CON: THANH ĐIỀU HƯỚNG DƯỚI CÙNG (BOTTOM NAVIGATION BAR)
  // ============================================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, 'Tổng quan'),
              _buildNavItem(1, Icons.menu_book_outlined, 'Luyện thi'),
              _buildNavItem(2, Icons.insights_rounded, 'Phân tích'),
              if (widget.isAdmin)
                _buildNavItem(3, Icons.manage_accounts_outlined, 'Quản trị'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    if (index == 3 && !widget.isAdmin) return const SizedBox.shrink();
    final isSelected = _currentBottomNavIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          widget.onNavigateHome?.call();
          return;
        }
        if (index == 1) {
          widget.onNavigatePractice?.call();
          return;
        }
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDBE1FF).withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF004AC6)
                  : const Color(0xFF737686),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF004AC6)
                    : const Color(0xFF737686),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// CUSTOM PAINTER: VẼ ĐƯỜNG CONG TĂNG TRƯỞNG & ĐIỂM SỐ CHUẨN TỪNG PIXEL
// ==============================================================================

class ScoreTrendPainter extends CustomPainter {
  final List<TrendPoint> points;

  ScoreTrendPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 1. Vẽ các đường lưới nét đứt nằm ngang (Dashed Grid lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFDAE2FD)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4.0;
    const double dashSpace = 4.0;

    for (double y in [
      size.height * 0.15,
      size.height * 0.5,
      size.height * 0.85,
    ]) {
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(math.min(startX + dashWidth, size.width), y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // 2. Tính tọa độ X, Y cho các điểm
    final minScore = 580;
    final maxScore = 700;
    final count = points.length;
    final List<Offset> offsets = [];

    for (int i = 0; i < count; i++) {
      final x = (size.width * 0.05) + (i / (count - 1)) * (size.width * 0.90);
      final normalizedY = (points[i].score - minScore) / (maxScore - minScore);
      // Đảo ngược Y vì trục Canvas tăng từ trên xuống
      final y = size.height * 0.85 - normalizedY * (size.height * 0.70);
      offsets.add(Offset(x, y));
    }

    // 3. Tạo Path đường cong mượt mà (Smooth Cubic Bezier curve)
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // 4. Vẽ Gradient vùng bóng mờ phía dưới (Area under curve)
    final areaPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF004AC6).withOpacity(0.22),
          const Color(0xFF004AC6).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, fillPaint);

    // 5. Vẽ đường kẻ viền chính (Line stroke)
    final linePaint = Paint()
      ..color = const Color(0xFF004AC6)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // 6. Vẽ các điểm tròn (Nodes)
    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final isLatest = points[i].isLatest;

      if (isLatest) {
        // Điểm gần nhất: Điểm xanh đặc to viền trắng nổi bật
        final outerCircle = Paint()
          ..color = const Color(0xFF004AC6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 6.5, outerCircle);

        final innerBorder = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(offset, 6.5, innerBorder);
      } else {
        // Các điểm thông thường: Trắng viền xanh
        final fill = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 4.5, fill);

        final stroke = Paint()
          ..color = const Color(0xFF004AC6)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(offset, 4.5, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScoreTrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
