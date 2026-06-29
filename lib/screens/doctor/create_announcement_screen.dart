import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  PlatformFile? _selectedFile;
  int? _selectedCourseId;
  int? _targetYear;
  bool _isPermanent = false;
  DateTime? _expiresAt;
  List _courses = [];
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiService.getMyCourses();
      setState(() => _courses = res['data'] ?? []);
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.navy,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _publishAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _publishing = true);

    try {
      final res = await ApiService.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        courseId: _selectedCourseId,
        targetYear: _targetYear,
        isPermanent: _isPermanent,
        expiresAt: _expiresAt?.toIso8601String(),
        mediaFile: _selectedFile,
      );

      if (res['status'] == 'success') {
        _showSnack('تم نشر الإعلان بنجاح ✓', AppColors.teal);
        Navigator.pop(context);
      } else {
        _showSnack(res['message'] ?? 'حدث خطأ', AppColors.failRed);
      }
    } catch (e) {
      _showSnack('خطأ: ${e.toString()}', AppColors.failRed);
    } finally {
      setState(() => _publishing = false);
    }
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
    _contentController.dispose();
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
                      _buildLabel('عنوان الإعلان'),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'مثال: إلغاء المحاضرة غداً',
                        validator: (v) =>
                        v?.isEmpty ?? true ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('المحتوى'),
                      TextFormField(
                        controller: _contentController,
                        textDirection: TextDirection.rtl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                          'اكتب تفاصيل الإعلان (اختياري)',
                          hintStyle:
                          const TextStyle(color: AppColors.textHint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('المادة (اختياري)'),
                      _buildCourseDropdown(),
                      const SizedBox(height: 18),
                      _buildLabel('السنة الدراسية المستهدفة (اختياري)'),
                      _buildYearDropdown(),
                      const SizedBox(height: 18),
                      _buildLabel('صورة أو ملف (اختياري)'),
                      _buildFilePicker(),
                      const SizedBox(height: 18),
                      _buildLabel('خيارات النشر'),
                      _buildPermanentToggle(),
                      const SizedBox(height: 12),
                      if (!_isPermanent) _buildExpiryDatePicker(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _publishing
                              ? null
                              : _publishAnnouncement,
                          icon: _publishing
                              ? SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                          )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                              _publishing
                                  ? 'جاري النشر...'
                                  : 'نشر الإعلان',
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
          const Text('إعلان جديد',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
      );

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
          child: Text('غير محدد - إعلان عام',
              style: TextStyle(color: AppColors.textHint)),
        ),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('غير محدد - إعلان عام',
                  textDirection: TextDirection.rtl),
            ),
          ),
          ..._courses.map((c) {
            return DropdownMenuItem<int>(
              value: c['id'] as int,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(c['name'] ?? '',
                    textDirection: TextDirection.rtl),
              ),
            );
          }).toList(),
        ],
        onChanged: (v) => setState(() => _selectedCourseId = v),
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        isExpanded: true,
        value: _targetYear,
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('غير محدد - للجميع',
              style: TextStyle(color: AppColors.textHint)),
        ),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('غير محدد - للجميع',
                  textDirection: TextDirection.rtl),
            ),
          ),
          ...List.generate(5, (i) => i + 1).map((y) {
            return DropdownMenuItem<int>(
              value: y,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('السنة الدراسية $y',
                    textDirection: TextDirection.rtl),
              ),
            );
          }).toList(),
        ],
        onChanged: (v) => setState(() => _targetYear = v),
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
                  ? Icons.image_rounded
                  : Icons.image_outlined,
              color: _selectedFile != null ? AppColors.teal : AppColors.textHint,
              size: 40,
            ),
            const SizedBox(height: 8),
            if (_selectedFile != null)
              Text(_selectedFile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))
            else
              const Text('اضغط لإضافة صورة أو ملف PDF'),
          ],
        ),
      ),
    );
  }

  Widget _buildPermanentToggle() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إعلان دائم',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(_isPermanent ? 'سيبقى الإعلان للأبد' : 'سينتهي الإعلان',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
          Switch(
            value: _isPermanent,
            onChanged: (v) => setState(() => _isPermanent = v),
            activeColor: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDatePicker() {
    return GestureDetector(
      onTap: _selectExpiryDate,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: _expiresAt != null ? AppColors.teal : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تاريخ انتهاء الإعلان',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (_expiresAt != null)
                  Text(
                    '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.teal),
                  )
                else
                  const Text('لم يتم تحديد تاريخ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
              ],
            ),
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.teal, size: 20),
          ],
        ),
      ),
    );
  }
}