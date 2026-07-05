import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'package:ite_app/screens/lecture_files_screen.dart';

class LectureUploaderTypeScreen extends StatelessWidget {
  final int courseId;
  final String courseName;

  const LectureUploaderTypeScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(courseName)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LectureFilesScreen(
                      courseId: courseId,
                      courseName: courseName,
                      uploaderType: 'doctor',
                      screenTitle: 'محاضرات الدكتور',
                    ),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.school_rounded, color: AppColors.teal, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('محاضرات الدكتور',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textHint),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LectureFilesScreen(
                      courseId: courseId,
                      courseName: courseName,
                      uploaderType: 'volunteer',
                      screenTitle: 'محاضرات الفريق التطوعي',
                    ),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.groups_rounded,
                        color: AppColors.pendingText, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('محاضرات الفريق التطوعي',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textHint),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}