import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'grades_screen.dart';
import 'requests_screen.dart';
import 'announcements_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'qr_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _user;
  double _balance = 0;
  List _attendanceSummary = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _departmentLabel(String? dept) {
    switch (dept) {
      case 'software':   return 'هندسة البرمجيات';
      case 'networks':   return 'نظم وشبكات';
      case 'Basic Sciences': return 'العلوم الأساسية';
      case 'ai':             return 'الذكاء الاصطناعي';
      default:           return dept ?? '';
    }
  }

  Future<void> _loadData() async {
    try {
      final user = await ApiService.getUser();
      final balanceRes = await ApiService.getWalletBalance();
      final attendRes = await ApiService.getAttendance();
      final notifRes = await ApiService.getNotifications();

      setState(() {
        _user = user;
        _balance = (balanceRes['data']?['balance'] ?? 0).toDouble();
        _attendanceSummary =
            attendRes['attendance_summary'] ?? [];
        _unreadCount = notifRes['unread_count'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  final List<String> _pageTitles = ['الرئيسية', 'علاماتي', 'طلباتي', 'الإعلانات', 'حسابي'];

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
            const GradesScreen(),
            const RequestsScreen(),
            const AnnouncementsScreen(),
            const ProfileScreen(),
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
            fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
        unselectedLabelStyle:
        const TextStyle(fontSize: 10, fontFamily: 'Cairo'),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'علاماتي'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article_rounded),
              label: 'طلباتي'),
          BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text('$_unreadCount'),
                child: const Icon(Icons.campaign_outlined),
              ),
              activeIcon: const Icon(Icons.campaign_rounded),
              label: 'الإعلانات'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    if (_loading) return const LoadingWidget();
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.teal,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTopBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildWalletCard(),
                const SizedBox(height: 16),
                const SectionTitle(title: 'الوصول السريع'),
                _buildQuickGrid(),
                const SizedBox(height: 16),
                const SectionTitle(title: 'الحضور — هذا الفصل'),
                ..._buildAttendanceCards(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صباح الخير،',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                  Text(
                    _user?['name'] ?? 'الطالب',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _currentIndex = 3),
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 26),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السنة ${_user?['year_of_study'] ?? ''} — ${_departmentLabel(_user?['department'])}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 11),
                    ),
                    const Text(
                      'الفصل الثاني | 2025-2026',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
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

  Widget _buildWalletCard() {
    return AppCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رصيد المحفظة',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _balance.toStringAsFixed(0),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('ل.س',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _walletBtn(
                  label: 'سجل المعاملات',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _walletBtn(
                  label: 'بطاقة QR',
                  icon: Icons.qr_code_rounded,
                  color: AppColors.teal.withOpacity(0.25),
                  borderColor: AppColors.teal.withOpacity(0.4),
                  textColor: AppColors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QrScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletBtn({
    required String label,
    required IconData icon,
    Color? color,
    Color? borderColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.15), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGrid() {
    final items = [
      {'icon': Icons.bar_chart_rounded, 'title': 'علاماتي', 'sub': 'السجل الأكاديمي', 'color': const Color(0xFFE1F5EE), 'iconColor': const Color(0xFF0F6E56), 'index': 1},
      {'icon': Icons.calendar_today_rounded, 'title': 'الجدول', 'sub': 'جدول الدوام', 'color': const Color(0xFFFAEEDA), 'iconColor': AppColors.pendingText, 'index': -3},
      {'icon': Icons.article_rounded, 'title': 'طلباتي', 'sub': 'الخدمات الجامعية', 'color': const Color(0xFFE6F1FB), 'iconColor': const Color(0xFF185FA5), 'index': 2},
      {'icon': Icons.menu_book_rounded, 'title': 'المحاضرات', 'sub': 'ملفات المواد', 'color': const Color(0xFFEEEDFE), 'iconColor': const Color(0xFF534AB7), 'index': -2},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items.map((item) {
        return AppCard(
          onTap: () {
            final idx = item['index'] as int;
            if (idx >= 0) {
              setState(() => _currentIndex = idx);
            } else if (idx == -3) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScheduleScreen()));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'] as IconData,
                    color: item['iconColor'] as Color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(item['title'] as String,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(item['sub'] as String,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildAttendanceCards() {
    if (_attendanceSummary.isEmpty) {
      return [
        const AppCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد بيانات حضور بعد',
                  style: TextStyle(color: AppColors.textHint)),
            ),
          ),
        )
      ];
    }
    return _attendanceSummary.map<Widget>((item) {
      final attended = item['attended_sessions'] ?? 0;
      final total = (item['total_sessions'] ?? 0) > 0 ? item['total_sessions'] : attended;
      final pct = total > 0 ? (attended / total).clamp(0.0, 1.0) : 0.0;
      final isLow = pct < 0.7;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['course_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLow
                          ? AppColors.failBg
                          : AppColors.passBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLow ? 'تحذير غياب' : 'منتظم',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLow
                              ? AppColors.failRed
                              : AppColors.passGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct.toDouble(),
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isLow ? AppColors.failRed : AppColors.teal),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$attended / $total محاضرة',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLow ? AppColors.failRed : AppColors.teal),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}