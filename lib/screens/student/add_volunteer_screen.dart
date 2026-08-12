import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class AddVolunteerScreen extends StatefulWidget {
  const AddVolunteerScreen({super.key});

  @override
  State<AddVolunteerScreen> createState() => _AddVolunteerScreenState();
}

class _AddVolunteerScreenState extends State<AddVolunteerScreen> {
  final _universityIdController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _lastAddedUser;

  Future<void> _submit() async {
    final id = _universityIdController.text.trim();
    if (id.isEmpty) {
      _showSnack('الرجاء إدخال الرقم الجامعي', AppColors.amber);
      return;
    }

    setState(() {
      _loading = true;
      _lastAddedUser = null;
    });

    try {
      final res = await ApiService.giveVolunteerRole(id);
      if (res['status'] == 'success') {
        setState(() => _lastAddedUser = res['data']);
        _showSnack('تم منح الطالب صلاحية الفريق التطوعي بنجاح ✓', AppColors.teal);
        _universityIdController.clear();
      } else {
        _showSnack(res['message'] ?? 'حدث خطأ', AppColors.failRed);
      }
    } catch (_) {
      _showSnack('تعذر الاتصال بالخادم', AppColors.failRed);
    } finally {
      setState(() => _loading = false);
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
    _universityIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إضافة عضو للفريق التطوعي',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text(
                        'أدخل الرقم الجامعي للطالب لمنحه صلاحيات الفريق التطوعي',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _universityIdController,
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'الرقم الجامعي',
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.badge_outlined,
                              color: AppColors.textHint),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                            _loading
                                ? 'جاري الإضافة...'
                                : 'منح صلاحية الفريق التطوعي',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (_lastAddedUser != null) ...[
                      const SizedBox(height: 20),
                      AppCard(
                        color: AppColors.passBg,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.passGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_lastAddedUser?['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  Text(
                                      'الرقم الجامعي: ${_lastAddedUser?['university_id'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint)),
                                  const SizedBox(height: 3),
                                  const Text(
                                      'أصبح الآن عضواً في الفريق التطوعي',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.passGreen,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
          const Text('إضافة عضو للفريق التطوعي',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}