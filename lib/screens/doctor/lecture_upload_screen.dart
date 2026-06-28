import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class LectureUploadScreen extends StatefulWidget {
  const LectureUploadScreen({super.key});

  @override
  State<LectureUploadScreen> createState() => _LectureUploadScreenState();
}

class _LectureUploadScreenState extends State<LectureUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _academicYearController = TextEditingController();

  int? _selectedCourseId;
  PlatformFile? _selectedFile;
  List _courses = [];
  bool _loading = false;
  bool _uploadingFile = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiService.getCourses();
      setState(() => _courses = res['data'] ?? []);
    } catch (_) {
      _showSnack('فشل تحميل المواد', AppColors.failRed);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip', 'rar'],
        withData: true,
      );

      if (result != null) {
        setState(() => _selectedFile = result.files.first);
        _showSnack('تم اختيار الملف: ${_selectedFile!.name}', AppColors.teal);
      }
    } catch (e) {
      _showSnack('خطأ في اختيار الملف', AppColors.failRed);
    }
  }

  Future<void> _uploadLecture() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      _showSnack('اختر مادة من فضلك', AppColors.amber);
      return;
    }
    if (_selectedFile == null) {
      _showSnack('اختر ملف من فضلك', AppColors.amber);
      return;
    }

    setState(() => _uploadingFile = true);

    try {
      // استدعاء API لرفع المحاضرة
      final res = await ApiService.uploadLectureFile(
        courseId: _selectedCourseId!,
        title: _titleController.text.trim(),
        academicYear: _academicYearController.text.trim(),
        file: _selectedFile!,
      );

      if (res['status'] == 'success') {
        _showSnack('تم رفع المحاضرة بنجاح ✓', AppColors.teal);
        _resetForm();
      } else {
        _showSnack(res['message'] ?? 'حدث خطأ', AppColors.failRed);
      }
    } catch (e) {
      _showSnack('خطأ في الرفع: ${e.toString()}', AppColors.failRed);
    } finally {
      setState(() => _uploadingFile = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _academicYearController.clear();
    setState(() {
      _selectedCourseId = null;
      _selectedFile = null;
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اختيار المادة
                      const Text('المادة الدراسية *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildCourseDropdown(),
                      const SizedBox(height: 18),

                      // عنوان المحاضرة
                      const Text('عنوان المحاضرة *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'مثال: محاضرة 1 - مقدمة عن البرمجة',
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 18),

                      // السنة الأكاديمية
                      const Text('السنة الأكاديمية *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _academicYearController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'مثال: 2025-2026',
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 18),

                      // اختيار الملف
                      const Text('ملف المحاضرة *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildFilePicker(),
                      const SizedBox(height: 24),

                      // زر الرفع
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                          _uploadingFile ? null : _uploadLecture,
                          icon: _uploadingFile
                              ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                          )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: Text(
                              _uploadingFile
                                  ? 'جاري الرفع...'
                                  : 'رفع المحاضرة',
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
          ),
          const Text('رفع محاضرة جديدة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        isExpanded: true,
        value: _selectedCourseId,
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('اختر مادة',
              style: TextStyle(color: AppColors.textHint)),
        ),
        items: _courses.map((c) {
          return DropdownMenuItem<int>(
            value: c['id'] as int,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(c['name'] ?? '',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => _selectedCourseId = v),
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedFile != null ? AppColors.teal : AppColors.border,
            width: _selectedFile != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedFile != null
              ? AppColors.teal.withOpacity(0.05)
              : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null
                  ? Icons.check_circle_rounded
                  : Icons.file_upload_outlined,
              color: _selectedFile != null ? AppColors.teal : AppColors.textHint,
              size: 40,
            ),
            const SizedBox(height: 8),
            if (_selectedFile != null) ...[
              Text(_selectedFile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
            ] else ...[
              const Text('اضغط لاختيار ملف',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('PDF, Word, PowerPoint أو ضغط',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ],
        ),
      ),
    );
  }
}