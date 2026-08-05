import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'archived_files_list_screen.dart';

class ArchivedYearsScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String? uploaderType;

  const ArchivedYearsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    this.uploaderType,
  });

  @override
  State<ArchivedYearsScreen> createState() => _ArchivedYearsScreenState();
}

class _ArchivedYearsScreenState extends State<ArchivedYearsScreen> {
  bool _loading = true;
  Map<String, List> _filesByYear = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getArchivedFiles(
        courseId: widget.courseId,
        uploaderType: widget.uploaderType,
      );
      final files = res['data'] ?? [];

      final Map<String, List> grouped = {};
      for (final f in files) {
        final year = f['academic_year'] ?? 'غير محدد';
        grouped.putIfAbsent(year, () => []);
        grouped[year]!.add(f);
      }

      setState(() {
        _filesByYear = grouped;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = _filesByYear.keys.toList()..sort((a, b) => b.compareTo(a)); // الأحدث أولاً

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('الأرشيف — ${widget.courseName}')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : years.isEmpty
            ? const Center(
          child: Text('لا توجد ملفات مؤرشفة', style: TextStyle(color: AppColors.textHint)),
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: years.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final year = years[i];
            final count = _filesByYear[year]!.length;
            return AppCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArchivedFilesListScreen(
                      courseName: widget.courseName,
                      academicYear: year,
                      files: _filesByYear[year]!,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.pendingText, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(year,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text('$count ملف مؤرشف',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
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