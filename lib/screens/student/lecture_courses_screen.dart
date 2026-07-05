import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'lecture_uploader_type_screen.dart';

class LectureCoursesScreen extends StatefulWidget {
  const LectureCoursesScreen({super.key});

  @override
  State<LectureCoursesScreen> createState() => _LectureCoursesScreenState();
}

class _LectureCoursesScreenState extends State<LectureCoursesScreen> {
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
      final res = await ApiService.getMyEnrolledCourses();
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
        appBar: AppBar(title: const Text('المحاضرات')),
        body: _loading
            ? const LoadingWidget()
            : _hasError
            ? ErrorWidget2(message: 'فشل تحميل المواد', onRetry: _load)
            : _courses.isEmpty
            ? const Center(
          child: Text('لا توجد مواد مسجل بها',
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
            builder: (_) => LectureUploaderTypeScreen(
              courseId: course['id'],
              courseName: course['name'] ?? '',
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