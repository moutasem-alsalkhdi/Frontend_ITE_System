import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class LectureFilesScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String? uploaderType; // null = بدون فلترة (للدكتور)
  final String screenTitle;


  const LectureFilesScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    this.uploaderType,
    required this.screenTitle,
  });

  @override
  State<LectureFilesScreen> createState() => _LectureFilesScreenState();
}

class _LectureFilesScreenState extends State<LectureFilesScreen> {
  List _files = [];
  bool _loading = true;
  int? _downloadingId;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
       _user = await ApiService.getUser();
      final res = await ApiService.getLectureFiles(
        courseId: widget.courseId,
        uploaderType: widget.uploaderType,
      );
      setState(() {
        _files = res['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openFile(Map f) async {
    setState(() => _downloadingId = f['id']);
    try {
      final ext = (f['file_url'] as String).split('.').last;
      final fileName = '${f['title']}.$ext';
      await ApiService.downloadAndOpenLectureFile(f['id'], fileName);
    } catch (e) {
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
      _showSnack('فشل حفظ الملف', AppColors.failRed);
    } finally {
      setState(() => _downloadingId = null);
    }
  }

  Future<void> _deleteFile(int fileId) async {
    // إظهار تأكيد قبل الحذف لحماية المستخدم من الضغط الخاطئ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الملف نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.failRed)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final res = await ApiService.deleteLectureFile(fileId);
      if (res['status'] == 'success') {
        _showSnack(res['message'] ?? 'تم الحذف بنجاح', AppColors.teal);
        _load(); // إعادة تحميل القائمة بعد الحذف الناجح
      } else {
        _showSnack(res['message'] ?? 'فشل الحذف', AppColors.failRed);
        setState(() => _loading = false);
      }
    } catch (e) {
      _showSnack('حدث خطأ أثناء الاتصال بالسيرفر', AppColors.failRed);
      setState(() => _loading = false);
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
        appBar: AppBar(title: Text(widget.screenTitle)),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : _files.isEmpty
            ? const Center(child: Text('لا توجد ملفات بعد', style: TextStyle(color: AppColors.textHint)))
            : RefreshIndicator(
          onRefresh: _load,
          color: AppColors.teal,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _files.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildFileCard(_files[i]),
          ),
        ),
      ),
    );
  }


  Widget _buildFileCard(Map f) {
    final isDownloading = _downloadingId == f['id'];
    bool _canDeleteFile(Map f) {
      final role = _user?['role'];
      if (role == 'doctor') {
        return f['uploaded_by'] == _user?['id'];
      } else if (role == 'volunteer') {
        return f['uploader_type'] == 'volunteer';
      }
      return false;
    }
    final hasDeletePermission = _canDeleteFile(f);
    return GestureDetector(
        onTap: isDownloading ? null : () => _openFile(f),
        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, color: AppColors.teal, size: 28),
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
              else ...[
                if (hasDeletePermission)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.failRed, size: 20),
                    tooltip: 'حذف نهائي',
                    onPressed: () => _deleteFile(f['id']),
                  ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 20),
                  tooltip: 'حفظ في الجهاز',
                  onPressed: () => _saveFile(f),
                ),
          ],
        ],
          ),
      ),
    );
  }
}