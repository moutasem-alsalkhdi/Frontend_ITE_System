import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'repository_courses_screen.dart';
import 'repository_department_screen.dart';

class RepositoryYearsScreen extends StatelessWidget {
  const RepositoryYearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('مستودع المحاضرات')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final year = i + 1;
            return _buildYearCard(context, year);
          },
        ),
      ),
    );
  }

  Widget _buildYearCard(BuildContext context, int year) {
    return AppCard(
      onTap: () => _onYearTap(context, year),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: AppColors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'السنة $year',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }

  void _onYearTap(BuildContext context, int year) {
    if (year >= 4) {
      // السنوات 4 و5 فيها تخصصات متعددة — لازم يختار القسم أولاً
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RepositoryDepartmentScreen(yearOfStudy: year),
        ),
      );
    } else {
      // السنوات 1-2-3 كلها "Basic Sciences" موحدة لكل التخصصات
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RepositoryCoursesScreen(yearOfStudy: year),
        ),
      );
    }
  }
}