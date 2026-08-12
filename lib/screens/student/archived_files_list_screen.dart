import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ArchivedFilesListScreen extends StatefulWidget {
  final String courseName;
  final String academicYear;
  final List files;

  const ArchivedFilesListScreen({
    super.key,
    required this.courseName,
    required this.academicYear,
    required this.files,
  });

  @override
  State<ArchivedFilesListScreen> createState() => _ArchivedFilesListScreenState();
}

class _ArchivedFilesListScreenState extends State<ArchivedFilesListScreen> {
  int? _downloadingId;

  Future<void> _openFile(Map f) async {
    setState(() => _downloadingId = f['id']);
    try {
      final ext = (f['file_url'] as String).split('.').last;
      final fileName = '${f['title']}.$ext';
      await ApiService.downloadAndOpenLectureFile (f['id'], fileName);
    } catch (_) {
      _showSnack('فشل فتح الملف', AppColors.failRed);
    } finally {
      setState(() => _downloadingId = null);
    }
  }

  Future<void> _saveFile(Map f) async {
    setState(() => _downloadingId = f['id']);
    try {
      final ext = (f['file_url'] as String).split('.').last;
      final fileName = '${f['title']}.$ext';
      final path = await ApiService.saveLectureFileToDevice(f['id'], fileName);
      _showSnack('تم الحفظ: $path', AppColors.teal);
    } catch (e) {
      // 🎯 إظهار رسالة مخصصة إذا كان الملف محفوظاً مسبقاً في مجلد التنزيلات
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'ALREADY_DOWNLOADED') {
        _showSnack(
            'هذا الملف تم تنزيله مسبقاً وهو محفوظ بالفعل في مجلد التنزيلات',
            AppColors.amber);
      } else {
        _showSnack('فشل حفظ الملف', AppColors.failRed);
      }
    } finally {
      setState(() => _downloadingId = null);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('${widget.courseName} — ${widget.academicYear}')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.files.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _buildFileCard(widget.files[i]),
        ),
      ),
    );
  }

  Widget _buildFileCard(Map f) {
    final isDownloading = _downloadingId == f['id'];
    return GestureDetector(
      onTap: isDownloading ? null : () => _openFile(f),
      child: AppCard(
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, color: AppColors.textHint, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(f['uploader']?['name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            if (isDownloading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 20),
                tooltip: 'حفظ في الجهاز',
                onPressed: () => _saveFile(f),
              ),
          ],
        ),
      ),
    );
  }
}