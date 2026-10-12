import 'package:flutter/material.dart';

/// Ứng dụng Toeic Master - Thiết kế giao diện luyện thi chuẩn Mobile
/// Màn hình chính Luyện thi TOEIC
class ToeicHomeScreen extends StatefulWidget {
  const ToeicHomeScreen({
    super.key,
    this.displayName = 'Học viên',
    this.onNavigateHome,
    this.onOpenExams,
    this.readingExamList,
    this.listeningExamList,
    this.isAdmin = false,
  });
  final String displayName;
  final VoidCallback? onNavigateHome;
  final VoidCallback? onOpenExams;
  final Widget? readingExamList;
  final Widget? listeningExamList;
  final bool isAdmin;

  @override
  State<ToeicHomeScreen> createState() => _ToeicHomeScreenState();
}

class _ToeicHomeScreenState extends State<ToeicHomeScreen> {
  int _currentTabIndex =
      0; // 0: Luyện từng Part, 1: Đề Full Test, 2: Kho Từ vựng
  int _currentNavIndex = 1; // 1: Luyện thi
  bool _isPlayingAudio = false;
  int _knownCount = 42;
  bool _isCardFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      // --- HEADER APP BAR ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8FF).withOpacity(0.92),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + Greeting
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF004AC6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CHÀO BUỔI SÁNG,',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF737686),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            widget.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF131B2E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Streak Badge + Profile Avatar
                  Row(
                    children: [
                      // Streak Flame Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
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
                                color: Color(0xFF855300),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // --- BODY SCROLLVIEW ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Goal Banner (Mục tiêu tuần & XP)
            _buildGoalBanner(),
            const SizedBox(height: 16),

            // 2. Segmented Pill Tab Bar (Luyện từng Part | Đề Full Test | Kho Từ vựng)
            _buildSegmentedTabBar(),
            const SizedBox(height: 20),

            // 3. Tab Contents
            if (_currentTabIndex == 0) ...[
              _buildListeningSection(),
              const SizedBox(height: 24),
              _buildReadingSection(),
              const SizedBox(height: 24),
              _buildFullTestSection(),
              const SizedBox(height: 24),
              _buildFlashcardSection(),
              const SizedBox(height: 20),
              _buildTipCard(),
            ] else if (_currentTabIndex == 1) ...[
              _buildFullTestSection(),
              const SizedBox(height: 20),
              _buildTipCard(),
            ] else ...[
              _buildFlashcardSection(),
              const SizedBox(height: 20),
              _buildTipCard(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // 1. MỤC TIÊU TUẦN & XP BANNER
  // ==========================================
  Widget _buildGoalBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MỤC TIÊU TUẦN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF737686),
                    ),
                  ),
                  Text(
                    'Đạt 850+ TOEIC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF004AC6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDAE2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF007D55),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  '+180 XP hôm nay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006242),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SEGMENTED TAB BAR
  // ==========================================
  Widget _buildSegmentedTabBar() {
    final tabs = ['Luyện từng Part', 'Đề Full Test', 'Kho Từ vựng'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E7FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _currentTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF004AC6)
                        : const Color(0xFF434655),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // 3. KỸ NĂNG LISTENING (PART 1 - 4)
  // ==========================================
  Widget _buildListeningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.headphones_rounded,
                  color: Color(0xFF004AC6),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Kỹ năng Listening (Part 1 – 4)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            const Text(
              '4 Kỹ năng',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF737686),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (widget.listeningExamList != null) ...[
          widget.listeningExamList!,
          const SizedBox(height: 14),
        ],

        // --- PART 1 CARD ---
        _buildPart1Card(),
        const SizedBox(height: 14),

        // --- PART 2 CARD ---
        _buildPart2Card(),
        const SizedBox(height: 14),

        // --- PART 3 & 4 CARD ---
        _buildPart3And4Card(),
      ],
    );
  }

  Widget _buildPart1Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBE1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF004AC6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Part 1: Mô tả hình...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEDFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '6 câu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF004AC6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tranh phong cảnh & hoạt độn...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF737686)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '88% Đúng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF007D55),
                    ),
                  ),
                  Text(
                    '10 Bộ đề',
                    style: TextStyle(fontSize: 11, color: Color(0xFF737686)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mini Preview Image Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600&auto=format&fit=crop&q=80',
                  height: 96,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF6FFBBE),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Nhận diện bẫy thì Hiện tại hoàn thành',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: widget.onOpenExams,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AC6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Luyện ngay',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPart2Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDB8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFF855300),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Part 2: Hỏi & ...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDDB8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '25 câu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF855300),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Câu hỏi Wh-, Yes/No & Câu trầ...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF737686)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '76% Đúng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF855300),
                    ),
                  ),
                  Text(
                    '14 Bộ đề',
                    style: TextStyle(fontSize: 11, color: Color(0xFF737686)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Audio Waveform Player Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPlayingAudio = !_isPlayingAudio;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF004AC6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlayingAudio
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _waveBar(12, true),
                      _waveBar(20, true),
                      _waveBar(8, true),
                      _waveBar(16, true),
                      _waveBar(22, true),
                      _waveBar(14, false),
                      _waveBar(18, false),
                      _waveBar(8, false),
                      _waveBar(20, false),
                      _waveBar(12, false),
                      _waveBar(6, false),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '0:14 / 0:32',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF737686),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waveBar(double height, bool active) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF004AC6) : const Color(0xFFC3C6D7),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildPart3And4Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF6FFBBE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF006242),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Part 3 & 4: Hội thoại & Bà...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kèm Transcript tương tác, nhấn đúp ...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF737686)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Text(
                '69 câu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF004AC6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 8,
                    backgroundColor: Color(0xFFE2E7FF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF007D55),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Hoàn thành 65%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF737686),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. KỸ NĂNG READING (PART 5 - 7)
  // ==========================================
  Widget _buildReadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF004AC6),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Kỹ năng Reading (Part 5 – 7)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            const Text(
              '3 Kỹ năng',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF737686),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (widget.readingExamList != null) ...[
          widget.readingExamList!,
          const SizedBox(height: 14),
        ],

        // Part 5
        _buildReadingItemCard(
          icon: Icons.spellcheck_rounded,
          iconBgColor: const Color(0xFFDAE2FD),
          iconColor: const Color(0xFF004AC6),
          title: 'Part 5: Điền vào c...',
          subtitle: 'Trọng tâm Từ loại, Mệnh đ...',
          buttonText: 'Ôn 30 câu',
        ),
        const SizedBox(height: 12),

        // Part 6 & 7
        _buildReadingItemCard(
          icon: Icons.article_rounded,
          iconBgColor: const Color(0xFFEAEDFF),
          iconColor: const Color(0xFF003EA8),
          title: 'Part 6 & 7: Đoạn ...',
          subtitle: 'Email, Memo, Hóa đơn & ...',
          buttonText: 'Luyện đọc',
        ),
      ],
    );
  }

  Widget _buildReadingItemCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF737686),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onOpenExams,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAEDFF),
              foregroundColor: const Color(0xFF004AC6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. BỘ ĐỀ FULL TEST CHUẨN FORMAT
  // ==========================================
  Widget _buildFullTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.timer_outlined, color: Color(0xFF004AC6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Bộ đề Full Test Chuẩn Format',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ETS 2024',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93000A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Test 03 (Hot Test)
        _buildEtsTest03Card(),
        const SizedBox(height: 14),

        // Test 02 (Completed)
        _buildEtsTest02Card(),
        const SizedBox(height: 14),

        // Hacker TOEIC 3 Preview
        _buildHackerToeicCard(),
      ],
    );
  }

  Widget _buildEtsTest03Card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              const Text(
                'ETS 2024 – Test 03',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF131B2E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEA619),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 12,
                      color: Color(0xFF684000),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Hot',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF684000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFFEA619),
              ),
              const SizedBox(width: 3),
              const Text(
                '4.8',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const Text(' • ', style: TextStyle(color: Color(0xFF737686))),
              const Text(
                '3.4k lượt làm thi',
                style: TextStyle(fontSize: 12, color: Color(0xFF737686)),
              ),
              const Text(' • ', style: TextStyle(color: Color(0xFF737686))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FFBBE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Giải chi tiết 100%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF002113),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration & Questions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Color(0xFF004AC6),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '120 Phút',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: const [
                      Icon(
                        Icons.quiz_outlined,
                        size: 18,
                        color: Color(0xFF004AC6),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '200 Câu hỏi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dual Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onOpenExams,
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: const Text('Làm full 120p'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AC6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onOpenExams,
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Rút gọn 30p'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E7FF),
                    foregroundColor: const Color(0xFF004AC6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtsTest02Card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ETS 2024 – Test 02',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Làm ngày 12/05 • Thời gian làm: 114 phút',
                    style: TextStyle(fontSize: 12, color: Color(0xFF737686)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '710',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF004AC6),
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ 990 điểm',
                    style: TextStyle(fontSize: 11, color: Color(0xFF737686)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Listening & Reading Score breakdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Listening:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF737686),
                        ),
                      ),
                      Text(
                        '395/495',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF007D55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Reading:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF737686),
                        ),
                      ),
                      Text(
                        '315/495',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF855300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onOpenExams,
              icon: const Icon(Icons.rule_rounded, size: 18),
              label: const Text('Xem lại 34 câu sai & lời giải'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAEDFF),
                foregroundColor: const Color(0xFF004AC6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHackerToeicCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Hacker TOEIC 3 – T...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAE2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Mục tiêu 850+',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF434655),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Độ khó cao hơn 15% so với đề thi thật',
                  style: TextStyle(fontSize: 12, color: Color(0xFF737686)),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF004AC6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. FLASHCARD 600 TỪ VỰNG THIẾT YẾU
  // ==========================================
  Widget _buildFlashcardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.style_outlined, color: Color(0xFF004AC6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Flashcard 600 Từ Vựng',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            const Text(
              'Học 15 từ/ngày',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF004AC6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Interactive Flashcard Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2F3FF), Color(0xFFDAE2FD)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Topic badge & audio button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBE1FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.psychology_outlined,
                          size: 14,
                          color: Color(0xFF003EA8),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Chủ đề Hợp đồng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF003EA8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF004AC6),
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Word & Phonetics
              const Text(
                'Negotiate',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF004AC6),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '/nɪˈɡoʊ.ʃi.eɪt/ (verb)',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF434655),
                ),
              ),
              const SizedBox(height: 10),

              // Meaning Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Text(
                  'Đàm phán, thương lượng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Context Sentence in ETS Part 7
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ví dụ trong đề ETS Part 7:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF004AC6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF131B2E),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '"The legal team spent three hours trying to ',
                          ),
                          TextSpan(
                            text: 'negotiate',
                            style: TextStyle(
                              color: Color(0xFF004AC6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' more favorable contract terms."'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '(Đội ngũ pháp lý đã dành 3 giờ đồng hồ để cố gắng thương lượng các điều khoản hợp đồng có lợi hơn.)',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF737686),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons (Chưa thuộc / Đã thuộc từ này)
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onOpenExams,
                      icon: const Icon(
                        Icons.replay_rounded,
                        size: 18,
                        color: Color(0xFFBA1A1A),
                      ),
                      label: const Text(
                        'Chưa thuộc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFC3C6D7),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onOpenExams,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: Color(0xFF007D55),
                      ),
                      label: const Text(
                        'Đã thuộc từ này',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF007D55),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Topic Categories Title
        const Text(
          'Chủ đề từ vựng thông dụng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF131B2E),
          ),
        ),
        const SizedBox(height: 10),

        // Topic 1
        _buildVocabTopicItem(
          icon: Icons.handshake_outlined,
          iconBgColor: const Color(0xFF6FFBBE),
          iconColor: const Color(0xFF006242),
          title: 'Hợp đồng & Giao dịch',
          subtitle: 'Contracts, Agreements, Terms',
          completed: 42,
          total: 50,
        ),
        const SizedBox(height: 10),

        // Topic 2
        _buildVocabTopicItem(
          icon: Icons.campaign_outlined,
          iconBgColor: const Color(0xFFFFDDB8),
          iconColor: const Color(0xFF855300),
          title: 'Marketing & Bán hàng',
          subtitle: 'Promotions, Advertising, Market',
          completed: 35,
          total: 50,
        ),
        const SizedBox(height: 10),

        // Topic 3
        _buildVocabTopicItem(
          icon: Icons.account_balance_outlined,
          iconBgColor: const Color(0xFFDBE1FF),
          iconColor: const Color(0xFF004AC6),
          title: 'Tài chính & Kế toán',
          subtitle: 'Budget, Tax, Audits, Invoices',
          completed: 28,
          total: 50,
        ),
        const SizedBox(height: 10),

        // Topic 4
        _buildVocabTopicItem(
          icon: Icons.flight_takeoff_rounded,
          iconBgColor: const Color(0xFFDAE2FD),
          iconColor: const Color(0xFF131B2E),
          title: 'Đi lại & Chuyến công ...',
          subtitle: 'Flight, Luggage, Itinerary',
          completed: 19,
          total: 50,
        ),
      ],
    );
  }

  Widget _buildVocabTopicItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int completed,
    required int total,
  }) {
    final progress = completed / total;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF737686),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completed / $total từ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF004AC6),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E7FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF004AC6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. MẸO HỌC PART 1 & PART 2 TIP CARD
  // ==========================================
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDDB8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF855300),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mẹo học Part 1 & Part 2',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131B2E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Lắng nghe kỹ từ đầu tiên của câu hỏi (Who/Where/When/Why) để loại trừ phương án sai nhanh gấp đôi!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF434655),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 8. BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar() {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'activeIcon': Icons.dashboard_rounded,
        'label': 'Tổng quan',
      },
      {
        'icon': Icons.menu_book_outlined,
        'activeIcon': Icons.menu_book_rounded,
        'label': 'Luyện thi',
      },
      {
        'icon': Icons.insights_rounded,
        'activeIcon': Icons.insights_rounded,
        'label': 'Phân tích',
      },
      {
        'icon': Icons.manage_accounts_outlined,
        'activeIcon': Icons.manage_accounts_rounded,
        'label': 'Quản trị',
      },
    ];
    final visibleNavItems = widget.isAdmin
        ? navItems
        : navItems.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(visibleNavItems.length, (index) {
              final isSelected = _currentNavIndex == index;
              final item = visibleNavItems[index];

              return InkWell(
                onTap: () {
                  if (index == 0) {
                    widget.onNavigateHome?.call();
                    return;
                  }
                  setState(() {
                    _currentNavIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFDBE1FF).withOpacity(0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        size: 22,
                        color: isSelected
                            ? const Color(0xFF004AC6)
                            : const Color(0xFF737686),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF004AC6)
                              : const Color(0xFF737686),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
