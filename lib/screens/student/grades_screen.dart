import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List _grades = [];
  bool _loading = true;
  Map<String, dynamic>? _user;

  // فلاتر
  String? _selectedYear;       // academic_year
  int?    _selectedSemester;   // semester
  String? _selectedStatus;     // pass / fail
  int?    _selectedStudyYear;  // year_of_study (السنة الدراسية)

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _user = await ApiService.getUser();
    setState(() {});
    _load();
  }

  // السنة الدراسية للطالب (1 إلى year_of_study)
  int get _maxStudyYear => (_user?['year_of_study'] as int?) ?? 1;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getAcademicRecord(
        academicYear: _selectedYear,
        semester: _selectedSemester,
        status: _selectedStatus,
        yearOfStudy: _selectedStudyYear,
      );
      setState(() {
        _grades = res['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedSemester = null;
      _selectedStatus = null;
      _selectedStudyYear = null;
    });
    _load();
  }

  bool get _hasActiveFilter =>
      _selectedYear != null ||
          _selectedSemester != null ||
          _selectedStatus != null ||
          _selectedStudyYear != null;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: _loading
                  ? const LoadingWidget()
                  : _grades.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_rounded,
                        color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('لا توجد علامات بهذه الفلاتر',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                    if (_hasActiveFilter) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('مسح الفلاتر',
                            style:
                            TextStyle(color: AppColors.teal)),
                      ),
                    ]
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.teal,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 100),
                  itemCount: _grades.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _buildGradeCard(_grades[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('السجل الأكاديمي',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          if (_hasActiveFilter)
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('مسح الكل',
                    style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── السنة الأكاديمية ──
          _filterLabel('السنة الأكاديمية'),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _chip('الكل', _selectedYear == null, () {
                  setState(() => _selectedYear = null);
                  _load();
                }),
                _chip('2025-2026', _selectedYear == '2025-2026', () {
                  setState(() => _selectedYear = '2025-2026');
                  _load();
                }),
                _chip('2024-2025', _selectedYear == '2024-2025', () {
                  setState(() => _selectedYear = '2024-2025');
                  _load();
                }),
                _chip('2023-2024', _selectedYear == '2023-2024', () {
                  setState(() => _selectedYear = '2023-2024');
                  _load();
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── الفصل الدراسي ──
          _filterLabel('الفصل الدراسي'),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _chip('الكل', _selectedSemester == null, () {
                  setState(() => _selectedSemester = null);
                  _load();
                }),
                _chip('الأول', _selectedSemester == 1, () {
                  setState(() => _selectedSemester = 1);
                  _load();
                }),
                _chip('الثاني', _selectedSemester == 2, () {
                  setState(() => _selectedSemester = 2);
                  _load();
                }),
                _chip('الصيفي', _selectedSemester == 3, () {
                  setState(() => _selectedSemester = 3);
                  _load();
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── السنة الدراسية (من السنة 1 حتى سنة الطالب) ──
          _filterLabel('السنة الدراسية'),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _chip('الكل', _selectedStudyYear == null, () {
                  setState(() => _selectedStudyYear = null);
                  _load();
                }),
                ...List.generate(_maxStudyYear, (i) => i + 1).map((y) =>
                    _chip('السنة $y', _selectedStudyYear == y, () {
                      setState(() => _selectedStudyYear = y);
                      _load();
                    })),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── الحالة ──
          _filterLabel('الحالة'),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('الكل', _selectedStatus == null, () {
                setState(() => _selectedStatus = null);
                _load();
              }),
              const SizedBox(width: 8),
              _chip('ناجح ✓', _selectedStatus == 'pass', () {
                setState(() => _selectedStatus = 'pass');
                _load();
              }, activeColor: AppColors.passGreen, activeBg: AppColors.passBg),
              const SizedBox(width: 8),
              _chip('راسب ✗', _selectedStatus == 'fail', () {
                setState(() => _selectedStatus = 'fail');
                _load();
              }, activeColor: AppColors.failRed, activeBg: AppColors.failBg),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _chip(
      String label,
      bool active,
      VoidCallback onTap, {
        Color? activeColor,
        Color? activeBg,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? (activeBg ?? AppColors.navy)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? (activeColor ?? AppColors.navy)
                : AppColors.border,
            width: active ? 1 : 0.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? (activeColor ?? Colors.white)
                    : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildGradeCard(Map g) {
    final status = g['status'] ?? '';
    final total = g['total_score'];
    final practical = g['practical_score'] ?? 0;
    final theoretical = g['theoretical_score'] ?? 0;

    Color scoreColor;
    Color scoreBg;
    if (status == 'pass') {
      scoreColor = AppColors.passGreen;
      scoreBg = AppColors.passBg;
    } else if (status == 'fail') {
      scoreColor = AppColors.failRed;
      scoreBg = AppColors.failBg;
    } else {
      scoreColor = AppColors.pendingText;
      scoreBg = AppColors.pendingBg;
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: scoreBg,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                total != null ? '$total' : '—',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scoreColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g['course_name'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  'نظري: $theoretical  ·  عملي: $practical',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
                Text(
                  '${g['academic_year'] ?? ''}  ·  فصل ${g['semester'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          StatusBadge.fromStatus(status),
        ],
      ),
    );
  }
}