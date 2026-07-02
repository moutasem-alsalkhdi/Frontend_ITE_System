import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'attendance_type_screen.dart';

class AttendanceCoursesScreen extends StatefulWidget {
  const AttendanceCoursesScreen({super.key});

  @override
  State<AttendanceCoursesScreen> createState() => _AttendanceCoursesScreenState();
}

class _AttendanceCoursesScreenState extends State<AttendanceCoursesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // 1. مواد الطالب المسجل بيها فعلياً بالفصل الحالي
      final coursesRes = await ApiService.getMyEnrolledCourses();
      final myCourses = coursesRes['data'] ?? [];

      // 2. إحصائيات الحضور المتوفرة (ممكن تكون فاضية لو ما فيه جلسات منتهية بعد)
      final attendRes = await ApiService.getAttendance();
      final attendanceRaw = attendRes['attendance_summary'] ?? [];
      final attendanceByCourse = _groupByCourse(attendanceRaw);

      setState(() {
        _courses = myCourses.map<Map<String, dynamic>>((c) {
          final courseId = c['id'];
          final stats = attendanceByCourse.firstWhere(
                (a) => a['course_id'] == courseId,
            orElse: () => {
              'course_id': courseId,
              'course_name': c['name'],
              'types': <String, Map<String, int>>{},
            },
          );
          return stats;
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // يجمع صفوف (course, session_type) بنفس المادة بمفتاح واحد فيه النوعين
  List<Map<String, dynamic>> _groupByCourse(List raw) {
    final Map<int, Map<String, dynamic>> grouped = {};
    for (final item in raw) {
      final courseId = item['course_id'];
      grouped.putIfAbsent(courseId, () => {
        'course_id': courseId,
        'course_name': item['course_name'],
        'types': <String, Map<String, int>>{},
      });
      final total = int.tryParse('${item['total_sessions'] ?? 0}') ?? 0;
      final attended = int.tryParse('${item['attended_sessions'] ?? 0}') ?? 0;
      (grouped[courseId]!['types'] as Map<String, Map<String, int>>)[item['session_type']] = {
        'total': total,
        'attended': attended,
      };
    }
    return grouped.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('سجل الحضور')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : _courses.isEmpty
            ? const Center(child: Text('لا توجد مواد مسجل بها', style: TextStyle(color: AppColors.textHint)))
            : RefreshIndicator(
          onRefresh: _load,
          color: AppColors.teal,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildCourseCard(_courses[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final types = course['types'] as Map<String, Map<String, int>>;
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceTypeScreen(
              courseId: course['course_id'],
              courseName: course['course_name'] ?? '',
              types: types,
            ),
          ),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(course['course_name'] ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }
}