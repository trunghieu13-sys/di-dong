import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// Gợi ý: Thêm 'google_fonts: ^6.2.1' vào pubspec.yaml nếu muốn dùng GoogleFonts.plusJakartaSans
// Hoặc sử dụng TextStyle tiêu chuẩn bên dưới để chạy trực tiếp không cần thư viện bên thứ 3.

/// Ứng dụng Quản trị Hệ thống TOEIC Master
// ==========================================
// BẢNG MÀU THIẾT KẾ CHUẨN (DESIGN TOKENS)
// ==========================================
class AppColors {
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);

  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  static const Color primary = Color(0xFF004AC6);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixedVariant = Color(0xFF003EA8);

  static const Color secondary = Color(0xFF855300);
  static const Color secondaryFixed = Color(0xFFFFDDB8);
  static const Color secondaryContainer = Color(0xFFFEA619);
  static const Color onSecondaryContainer = Color(0xFF684000);

  static const Color tertiary = Color(0xFF006242);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color onTertiaryFixedVariant = Color(0xFF005236);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

// ==========================================
// MÀN HÌNH CHÍNH QUẢN TRỊ (ADMIN DASHBOARD)
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.displayName,
    required this.onImport,
    required this.onReviewExam,
    required this.loadAdminExams,
    this.onNavigateDashboard,
    this.onNavigatePractice,
    this.onNavigateAnalysis,
    this.onLogout,
  });
  final String displayName;
  final Future<Map<String, dynamic>> Function(String, Uint8List, String, String)
  onImport;
  final Future<void> Function(int) onReviewExam;
  final Future<List<Map<String, dynamic>>> Function() loadAdminExams;
  final VoidCallback? onNavigateDashboard;
  final VoidCallback? onNavigatePractice;
  final VoidCallback? onNavigateAnalysis;
  final VoidCallback? onLogout;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _recentExamsFuture;
  int _selectedNavIndex = 3; // Mặc định ở tab 'Quản trị'
  String _selectedPart = 'Part 1 (Mô tả ảnh)';

  final List<String> _partFilters = [
    'Part 1 (Mô tả ảnh)',
    'Part 2 (Hỏi đáp)',
    'Part 3 (Hội thoại)',
    'Part 5 (Điền câu)',
    'Part 7 (Đọc hiểu)',
  ];

  @override
  void initState() {
    super.initState();
    _recentExamsFuture = widget.loadAdminExams();
  }

  Future<void> _openReview(int examId) async {
    await widget.onReviewExam(examId);
    if (mounted) setState(() => _recentExamsFuture = widget.loadAdminExams());
  }

  Future<void> _showCreateExamDialog() async {
    final titleController = TextEditingController();
    PlatformFile? selectedFile;
    var section = 'Reading';
    var uploading = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tạo đề mới'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập đề TOEIC từ file Word (.docx). Đề sẽ được lưu ở dạng bản nháp để Admin rà soát trước khi công bố.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên đề thi (không bắt buộc)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: section,
                  decoration: const InputDecoration(
                    labelText: 'Phần thi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Reading', child: Text('Reading')),
                    DropdownMenuItem(
                      value: 'Listening',
                      child: Text('Listening'),
                    ),
                  ],
                  onChanged: uploading
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() => section = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          final file = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: const ['docx'],
                          );
                          if (file != null) {
                            setDialogState(() {
                              selectedFile = file;
                              errorMessage = null;
                            });
                          }
                        },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(selectedFile?.name ?? 'Chọn file .docx'),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: selectedFile == null || uploading
                  ? null
                  : () async {
                      setDialogState(() => uploading = true);
                      try {
                        final file = selectedFile!;
                        final bytes = await file.readAsBytes();
                        final result = await widget.onImport(
                          file.name,
                          bytes,
                          titleController.text.trim(),
                          section,
                        );
                        if (!mounted) return;
                        final examId = result['id'] as int;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] as String)),
                        );
                        await _openReview(examId);
                      } catch (error) {
                        setDialogState(() {
                          errorMessage = error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                        });
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => uploading = false);
                        }
                      }
                    },
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(uploading ? 'Đang nhập...' : 'Nhập đề'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildCustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Role Banner & Switcher
              _buildRoleBanner(),
              const SizedBox(height: 16),

              // 2. Alert Notification Banner
              _buildUrgentAlertBanner(),
              const SizedBox(height: 16),

              // 3. KPI Bento Grid 2x2
              _buildKpiGrid(),
              const SizedBox(height: 24),

              // 4. Quản lý trực quan (Visual Hub)
              _buildVisualManagementSection(),
              const SizedBox(height: 20),

              // 5. Bộ lọc ngân hàng câu hỏi (Filter Chips)
              _buildQuestionBankFilter(),
              const SizedBox(height: 24),

              // 6. Đề thi gần đây (Recent Exams List)
              _buildRecentExamsSection(),
              const SizedBox(height: 24),

              // 7. Học viên xuất sắc & Cảnh báo Streak
              _buildStudentProgressSection(),
              const SizedBox(height: 20),

              // 8. Hạ tầng Audio CDN & Storage Card
              _buildStorageInfrastructureCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ----------------------------------------------------
  // APP BAR TÙY BIẾN VỚI LOGO, LỜI CHÀO & HUY HIỆU STREAK
  // ----------------------------------------------------
  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(
        children: [
          // Logo TOEIC Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Chào buổi sáng & Tên người dùng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CHÀO BUỔI SÁNG,',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  widget.displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Streak Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              SizedBox(width: 4),
              Text(
                '14 Ngày',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Avatar tròn
        Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.surfaceContainerHigh,
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80',
            ),
          ),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: widget.onLogout,
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 1. BANNER VAI TRÒ ADMIN & NÚT CHUYỂN ĐỔI CHẾ ĐỘ
  // ----------------------------------------------------
  Widget _buildRoleBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon Khiên Quản Trị
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Thông tin Quản Trị Hệ Thống
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Quản Trị Hệ ...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Phiên làm việc: Nguyễn Hòa',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Nút Chuyển Giao diện Học viên
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chuyển sang góc nhìn Học Viên')),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Học viên',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  // ----------------------------------------------------
  // 2. KHUNG THÔNG BÁO KHẨN CẤP (ALERT BOX)
  // ----------------------------------------------------
  Widget _buildUrgentAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cần duyệt 3 phản hồi lỗi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Khẩn cấp',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Audio rè Part 1 #04, lỗi font Part 5 #112',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onErrorContainer.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mở phiếu duyệt lỗi Part 1 & Part 5'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLowest,
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(56, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xử lý',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 3. GRID 2X2 THỐNG KÊ CHỈ SỐ KPI (BENTO STYLE)
  // ----------------------------------------------------
  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        // KPI 1: Học viên hoạt động
        _buildKpiCard(
          icon: Icons.people_outline_rounded,
          iconBgColor: AppColors.primaryFixed,
          iconColor: AppColors.onPrimaryFixedVariant,
          value: '1,248',
          label: 'HỌC VIÊN HOẠT ĐỘNG',
          badgeText: '+12%',
          badgeIcon: Icons.trending_up_rounded,
          badgeColor: AppColors.tertiary,
        ),
        // KPI 2: Đạt mục tiêu TOEIC
        _buildKpiCard(
          icon: Icons.workspace_premium_outlined,
          iconBgColor: AppColors.tertiaryFixed,
          iconColor: AppColors.onTertiaryFixedVariant,
          value: '94.2%',
          valueColor: AppColors.tertiary,
          label: 'ĐẠT MỤC TIÊU TOEIC',
          badgeText: 'Mục tiêu',
          badgeColor: AppColors.tertiary,
        ),
        // KPI 3: Đề Full Tests
        _buildKpiCard(
          icon: Icons.menu_book_outlined,
          iconBgColor: AppColors.surfaceContainerHigh,
          iconColor: AppColors.primary,
          value: '42',
          label: 'ĐỀ FULL TESTS',
          badgeText: '4 bản nháp',
          badgeColor: AppColors.onSurfaceVariant,
        ),
        // KPI 4: Ngân hàng câu hỏi
        _buildKpiCard(
          icon: Icons.quiz_outlined,
          iconBgColor: AppColors.secondaryFixed,
          iconColor: AppColors.secondary,
          value: '8,500+',
          label: 'NGÂN HÀNG CÂU HỎI',
          badgeText: 'Part 1-7',
          badgeColor: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    Color? valueColor,
    required String label,
    required String badgeText,
    IconData? badgeIcon,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeIcon != null) ...[
                    Icon(badgeIcon, color: badgeColor, size: 14),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 4. QUẢN LÝ TRỰC QUAN & 2 MODULE ĐIỀU HƯỚNG
  // ----------------------------------------------------
  Widget _buildVisualManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quản Lý Trực Quan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateExamDialog,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                'Tạo đề mới',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVisualCard(
                icon: Icons.library_books_rounded,
                iconBg: AppColors.primaryFixed,
                iconColor: AppColors.primary,
                title: 'Ngân hàng Part 1–7',
                subtitle: 'Quản lý Audio, Transcrip...',
                actionText: '3 cấp độ',
                actionColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVisualCard(
                icon: Icons.analytics_outlined,
                iconBg: AppColors.tertiaryFixed,
                iconColor: AppColors.tertiary,
                title: 'Tiến độ & Cảnh báo',
                subtitle: 'Theo dõi Streak, tăng...',
                actionText: '18 học viên tụt',
                actionColor: AppColors.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisualCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required Color actionColor,
  }) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: actionColor,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: actionColor),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 5. BỘ LỌC NGÂN HÀNG CÂU HỎI (HORIZONTAL FILTER CHIPS)
  // ----------------------------------------------------
  Widget _buildQuestionBankFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bộ lọc ngân hàng câu hỏi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Xem tất cả (7)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _partFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final part = _partFilters[index];
              final isSelected = part == _selectedPart;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPart = part;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    part,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 6. DANH SÁCH ĐỀ THI GẦN ĐÂY (EXAM CARDS)
  // ----------------------------------------------------
  Widget _buildRecentExamsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recentExamsFuture,
      builder: (context, snapshot) {
        final exams = snapshot.data ?? const <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '\u0110\u1ec1 Thi G\u1ea7n \u0110\u00e2y',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  snapshot.hasData
                      ? '\u0110ang qu\u1ea3n l\u00fd ${exams.length} b\u1ed9'
                      : '\u0110\u1ec1 \u0111\u00e3 import',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting &&
                exams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c danh s\u00e1ch \u0111\u1ec1: ${snapshot.error}',
                ),
              )
            else if (exams.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Ch\u01b0a c\u00f3 \u0111\u1ec1 thi. H\u00e3y ch\u1ecdn "T\u1ea1o \u0111\u1ec1 m\u1edbi" \u0111\u1ec3 import file Word.',
                ),
              )
            else
              for (var index = 0; index < exams.length; index++) ...[
                _buildDatabaseExamCard(exams[index]),
                if (index < exams.length - 1) const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  Widget _buildDatabaseExamCard(Map<String, dynamic> exam) {
    final id = exam['id'] as int;
    final title = exam['title'] as String? ?? '\u0110\u1ec1 thi $id';
    final section = exam['section'] as String? ?? 'Reading';
    final count = exam['questionCount'] as int? ?? 0;
    final published = exam['isPublished'] as bool? ?? false;
    final createdAt = DateTime.tryParse(exam['createdAt'] as String? ?? '');
    final createdLabel = createdAt == null
        ? ''
        : ' \u00b7 ${createdAt.toLocal().toString().substring(0, 16)}';
    return _buildExamCard(
      icon: section == 'Listening'
          ? Icons.headphones_outlined
          : Icons.menu_book_rounded,
      title: title,
      subtitle: '$section \u00b7 $count c\u00e2u$createdLabel',
      statusText: published
          ? '\u0110\u00e3 xu\u1ea5t b\u1ea3n'
          : 'B\u1ea3n nh\u00e1p',
      statusColor: published
          ? AppColors.tertiaryFixed
          : AppColors.secondaryFixed,
      statusTextColor: published
          ? AppColors.onTertiaryFixedVariant
          : AppColors.secondary,
      metrics: [
        _buildMetricCol('Ph\u1ea7n thi', section, AppColors.primary),
        _buildMetricCol(
          'S\u1ed1 c\u00e2u h\u1ecfi',
          '$count c\u00e2u',
          AppColors.onSurface,
        ),
        _buildMetricCol(
          'Th\u1eddi gian',
          '${exam['durationMinutes'] ?? 75} ph\u00fat',
          AppColors.onSurfaceVariant,
        ),
      ],
      actions: [
        _buildCardActionButton(
          Icons.edit_outlined,
          'Ch\u1ec9nh s\u1eeda',
          onPressed: () => _openReview(id),
        ),
      ],
    );
  }

  Widget _buildExamCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required Color statusTextColor,
    required List<Widget> metrics,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header đề thi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chỉ số phân tích đề (Metric Bar)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                for (int i = 0; i < metrics.length; i++) ...[
                  Expanded(child: metrics[i]),
                  if (i < metrics.length - 1)
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Thanh nút thao tác
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: actions),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCardActionButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.onSurface),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPrimaryButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 7. TIẾN ĐỘ HỌC VIÊN XUẤT SẮC & NHẮC NHỞ STREAK
  // ----------------------------------------------------
  Widget _buildStudentProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Row(
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tiến Độ Học Viên Xuất Sắc',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const Text(
                'Tất cả',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Học viên 1
          _buildStudentRow(
            avatarLetters: 'TL',
            name: 'Trần Hoàng Long',
            details: 'Target: 800+ • Streak 28 ngày',
            deltaPoints: '+185 điểm',
            pointsFlow: '545 ➔ 730 TOEIC',
          ),
          const Divider(height: 16, thickness: 0.5),

          // Học viên 2
          _buildStudentRow(
            avatarLetters: 'MA',
            name: 'Mai Phương Anh',
            details: 'Target: 900+ • Streak 45 ngày',
            deltaPoints: '+140 điểm',
            pointsFlow: '780 ➔ 920 TOEIC',
          ),
          const SizedBox(height: 12),

          // Khung cảnh báo đứt chuỗi Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_paused_outlined,
                  color: AppColors.secondaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '18 học viên có nguy cơ đứt Streak > 3 ngày',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã gửi thông báo nhắc nhở qua App/Zalo!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: const Size(80, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Gửi nhắc nhở',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow({
    required String avatarLetters,
    required String name,
    required String details,
    required String deltaPoints,
    required String pointsFlow,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceContainer,
          child: Text(
            avatarLetters,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                details,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              deltaPoints,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.tertiary,
              ),
            ),
            Text(
              pointsFlow,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 8. HẠ TẦNG AUDIO CDN & BỘ NHỚ LƯU TRỮ
  // ----------------------------------------------------
  Widget _buildStorageInfrastructureCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HẠ TẦNG AUDIO CDN & STORAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Bình thường',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dung lượng file nghe Part 1–4',
                style: TextStyle(fontSize: 12.5, color: AppColors.onSurface),
              ),
              Text(
                '14.8 GB / 50 GB',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 14.8 / 50.0,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // THANH ĐIỀU HƯỚNG DƯỚI ĐÁY (BOTTOM NAVIGATION BAR)
  // ----------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Tổng quan',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'Luyện thi',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.insights_rounded,
                activeIcon: Icons.insights_rounded,
                label: 'Phân tích',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.manage_accounts_outlined,
                activeIcon: Icons.manage_accounts_rounded,
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
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0) {
          widget.onNavigateDashboard?.call();
          return;
        }
        if (index == 1) {
          widget.onNavigatePractice?.call();
          return;
        }
        if (index == 2) {
          widget.onNavigateAnalysis?.call();
          return;
        }
        setState(() {
          _selectedNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
