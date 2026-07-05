import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../login_screen.dart';
import '../student/announcements_screen.dart';
import 'lecture_upload_screen.dart';
import 'create_announcement_screen.dart';
import 'attendance_list_screen.dart';
import 'scan_setup_screen.dart';
import 'doctor_lecture_courses_screen.dart';
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomePage(),
            const AnnouncementsScreen(),
            _buildProfilePage(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo'),
        unselectedLabelStyle:
        const TextStyle(fontSize: 10, fontFamily: 'Cairo'),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign_rounded),
              label: 'الإعلانات'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildScanCard(),
              const SizedBox(height: 16),
              const SectionTitle(title: 'أدوات سريعة'),
              _buildQuickTools(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرحباً،',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13)),
          Text(
            _user?['name'] ?? 'الدكتور',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, Color(0xFF00A896)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ماسح الحضور',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12)),
                const SizedBox(height: 4),
                const Text('سجّل حضور الطلاب بسهولة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const ScanSetupScreen()),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded,
                      size: 18),
                  label: const Text('مسح الرمز',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.qr_code_2_rounded,
              color: Colors.white24, size: 80),
        ],
      ),
    );
  }

  Widget _buildQuickTools() {
    final tools = [
      {
        'icon': Icons.upload_file_rounded,
        'label': 'رفع محاضرة',
        'color': const Color(0xFFE6F1FB),
        'iconColor': const Color(0xFF185FA5),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LectureUploadScreen()),
        ),
      },
      {
        'icon': Icons.campaign_rounded,
        'label': 'إعلان جديد',
        'color': const Color(0xFFE1F5EE),
        'iconColor': const Color(0xFF0F6E56),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CreateAnnouncementScreen()),
        ),
      },
      {
        'icon': Icons.people_alt_outlined,
        'label': 'قائمة الحضور',
        'color': AppColors.pendingBg,
        'iconColor': AppColors.pendingText,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceListScreen()),
        ),
      },
      {
        'icon': Icons.folder_open_rounded,
        'label': 'ملفاتي',
        'color': const Color(0xFFEEEDFE),
        'iconColor': const Color(0xFF534AB7),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorLectureCoursesScreen()),
        ),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: tools.map((t) {
        return AppCard(
          onTap: t['action'] as VoidCallback,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(t['icon'] as IconData,
                    color: t['iconColor'] as Color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(t['label'] as String,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfilePage() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              color: AppColors.navy,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal, width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.teal, size: 38),
                  ),
                  const SizedBox(height: 12),
                  Text(_user?['name'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_user?['email'] ?? '',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              color: AppColors.teal),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الدور الوظيفي',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint)),
                              Text(
                                _user?['role'] == 'doctor'
                                    ? 'دكتور'
                                    : 'معيد',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ApiService.logout();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                                  (_) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.failRed),
                        label: const Text('تسجيل الخروج',
                            style: TextStyle(
                                color: AppColors.failRed,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.failRed, width: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}