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
  String _selectedSessionType = 'theory';
  String _lectureNumber = '1';
  List _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiService.getCourses();
      setState(() => _courses = res['data'] ?? []);
    } catch (_) {}
  }

  Future<void> _fetchAttendance() async {
    if (_selectedCourseId == null) {
      _showSnack('اختر مادة من فضلك', AppColors.amber);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await ApiService.getLectureAttendance(
        courseId: _selectedCourseId!,
        sessionType: _selectedSessionType,
        lectureNumber: _lectureNumber,
      );

      setState(() {
        _students = res['students'] ?? [];
        _loading = false;
      });

      _showSnack(
          'عدد الحاضرين: ${_students.length}', AppColors.teal);
    } catch (_) {
      _showSnack('فشل تحميل قائمة الحضور', AppColors.failRed);
      setState(() => _loading = false);
    }
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
              onChanged: (v) => setState(() => _selectedCourseId = v),
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
                        items: [
                          DropdownMenuItem(
                            value: 'theory',
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('نظري'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lab',
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('عملي'),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(
                                () => _selectedSessionType = v ?? 'theory'),
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