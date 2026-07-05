import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'package:ite_app/screens/lecture_files_screen.dart'; // عدّل المسار إذا الملف موجود بمكان ثاني

class DoctorLectureCoursesScreen extends StatefulWidget {
  const DoctorLectureCoursesScreen({super.key});

  @override
  State<DoctorLectureCoursesScreen> createState() => _DoctorLectureCoursesScreenState();
}

class _DoctorLectureCoursesScreenState extends State<DoctorLectureCoursesScreen> {
  List _courses = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final res = await ApiService.getMyCourses();
      setState(() {
        _courses = res['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('ملفاتي')),
        body: _loading
            ? const LoadingWidget()
            : _hasError
            ? ErrorWidget2(message: 'فشل تحميل المواد', onRetry: _load)
            : _courses.isEmpty
            ? const Center(
          child: Text('لا توجد مواد مسندة إليك',
              style: TextStyle(color: AppColors.textHint)),
        )
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

  Widget _buildCourseCard(Map course) {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LectureFilesScreen(
              courseId: course['id'],
              courseName: course['name'] ?? '',
              uploaderType: 'doctor',
              screenTitle: course['name'] ?? '',
            ),
          ),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              course['name'] ?? '',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }
}