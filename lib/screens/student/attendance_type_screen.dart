import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'attendance_detail_screen.dart';

class AttendanceTypeScreen extends StatelessWidget {
  final int courseId;
  final String courseName;
  final Map<String, Map<String, int>> types; // {'theoretical': {total, attended}, 'practical': {...}}

  const AttendanceTypeScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    final hasTheoretical = types.containsKey('theoretical');
    final hasPractical = types.containsKey('practical');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(courseName)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (hasTheoretical) _buildTypeCard(context, 'theoretical', 'نظري', types['theoretical']!),
              if (hasTheoretical && hasPractical) const SizedBox(height: 12),
              if (hasPractical) _buildTypeCard(context, 'practical', 'عملي', types['practical']!),
              if (!hasTheoretical && !hasPractical)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text('لا توجد جلسات حضور لهذه المادة بعد', style: TextStyle(color: AppColors.textHint)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, String typeKey, String typeLabel, Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final attended = stats['attended'] ?? 0;
    final pct = total > 0 ? attended / total : 0.0;
    final isLow = pct < 0.7;

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceDetailScreen(
              courseId: courseId,
              courseName: courseName,
              sessionType: typeKey,
              sessionTypeLabel: typeLabel,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isLow ? AppColors.failRed : AppColors.teal).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              typeKey == 'theoretical' ? Icons.menu_book_rounded : Icons.science_rounded,
              color: isLow ? AppColors.failRed : AppColors.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('$attended / $total محاضرة', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }
}