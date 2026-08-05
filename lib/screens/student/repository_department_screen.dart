import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'repository_courses_screen.dart';

class RepositoryDepartmentScreen extends StatelessWidget {
  final int yearOfStudy;
  const RepositoryDepartmentScreen({super.key, required this.yearOfStudy});

  static const Map<String, String> _departments = {
    'software': 'هندسة البرمجيات',
    'networks': 'نظم وشبكات',
    'ai': 'الذكاء الاصطناعي',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('السنة $yearOfStudy — اختر القسم')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _departments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final deptKey = _departments.keys.elementAt(i);
            final deptLabel = _departments.values.elementAt(i);
            return AppCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RepositoryCoursesScreen(
                    yearOfStudy: yearOfStudy,
                    department: deptKey,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_tree_rounded, color: AppColors.teal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(deptLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}