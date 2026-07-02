import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  List _students = [];
  bool _loading = true;
  int? _selectedCourseId;
  String? _selectedSessionType ;
  String _lectureNumber = '1';
  List _courses = [];
  int? _currentUserId;
  List<String> _availableTypes = [];
  String _scope = 'all';

  @override
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadCourses();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ApiService.getUser();
    setState(() => _currentUserId = user?['id']);
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiService.getMyCourses();
      setState(() => _courses = res['data'] ?? []);
    } catch (_) {}
  }

  Future<void> _fetchAttendance() async {
    if (_selectedCourseId == null) {
      _showSnack('اختر مادة من فضلك', AppColors.amber);
      return;
    }
    if (_selectedSessionType == null) {
      _showSnack('اختر نوع الجلسة (نظري/عملي)', AppColors.amber);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await ApiService.getLectureAttendance(
        courseId: _selectedCourseId!,
        sessionType: _selectedSessionType!,
        lectureNumber: _lectureNumber,
        scope: _scope,
      );

      setState(() {
        _students = res['students'] ?? [];
        _loading = false;
      });

      _showSnack('عدد الحاضرين: ${_students.length}', AppColors.teal);
    } catch (_) {
      _showSnack('فشل تحميل قائمة الحضور', AppColors.failRed);
      setState(() => _loading = false);
    }
  }

  List<String> _computeAvailableTypes(dynamic course) {
    if (course == null || _currentUserId == null) return [];
    final assignments = course['staff_assignments'];
    if (assignments == null) return [];

    final types = <String>[];
    final theoretical = (assignments['theoretical'] as List?) ?? [];
    final practical = (assignments['theoretical'] as List?) ?? [];

    if (theoretical.any((s) => s['id'] == _currentUserId)) types.add('theoretical');
    if (practical.any((s) => s['id'] == _currentUserId)) types.add('practical');

    return types;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

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
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.teal))
                  : _students.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_rounded,
                        color: AppColors.textHint, size: 48),
                    const SizedBox(height: 12),
                    const Text('لا توجد قائمة حضور',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                      ),
                      child: const Text('حاول مجدداً'),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 12, 16, 20),
                itemCount: _students.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _buildStudentCard(_students[i]),
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
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
          ),
          const Text('قائمة الحضور',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المادة
          const Text('المادة الدراسية',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedCourseId,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('اختر مادة',
                    style: TextStyle(color: AppColors.textHint)),
              ),
              items: _courses.map((c) {
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(c['name'] ?? ''),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                final selected = _courses.firstWhere((c) => c['id'] == v, orElse: () => null);
                setState(() {
                  _selectedCourseId = v;
                  _availableTypes = _computeAvailableTypes(selected);
                  _selectedSessionType = _availableTypes.length == 1 ? _availableTypes.first : null;
                });
              },
              underline: const SizedBox(),
            ),
          ),
          const SizedBox(height: 12),

          // نوع الجلسة والمحاضرة
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('النوع',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSessionType,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _availableTypes.isEmpty ? 'اختر مادة أولاً' : 'اختر النوع',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                          ),
                        ),
                        items: _availableTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(type == 'theoretical' ? 'نظري' : 'عملي'),
                            ),
                          );
                        }).toList(),
                        onChanged: _availableTypes.isEmpty
                            ? null
                            : (v) => setState(() => _selectedSessionType = v),
                        underline: const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المحاضرة #',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _lectureNumber,
                      textDirection: TextDirection.rtl,
                      onChanged: (v) =>
                          setState(() => _lectureNumber = v),
                      decoration: InputDecoration(
                        hintText: '1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          const Text('عرض الحضور',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('جميع الطلاب'),
                  selected: _scope == 'all',
                  onSelected: (_) => setState(() => _scope = 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('طلابي فقط'),
                  selected: _scope == 'mine',
                  onSelected: (_) => setState(() => _scope = 'mine'),
                ),
              ),
            ],
          ),

          // زر البحث
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchAttendance,
              icon: const Icon(Icons.search_rounded),
              label: const Text('بحث',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map student) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (student['name'] ?? '')[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  'الرقم الجامعي: ${student['university_id'] ?? '—'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
                Text(
                  'رقم امتحاني: ${student['exam_number'] ?? '—'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.teal, size: 20),
              const SizedBox(height: 4),
              Text(
                student['attended_at'] ?? '',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}