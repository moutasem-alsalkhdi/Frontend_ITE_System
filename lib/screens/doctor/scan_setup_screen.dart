import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'doctor_qr_scanner.dart';

class ScanSetupScreen extends StatefulWidget {
  const ScanSetupScreen({super.key});

  @override
  State<ScanSetupScreen> createState() => _ScanSetupScreenState();
}

class _ScanSetupScreenState extends State<ScanSetupScreen> {
  List _courses = [];
  int? _courseId;
  String? _courseName;
  String _sessionType = 'theory'; // theory or lab
  final _lectureNumberCtrl = TextEditingController();
  final _totalSessionsCtrl = TextEditingController(text: '0');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiService.getCourses();
      setState(() {
        _courses = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('فشل جلب المواد'), backgroundColor: AppColors.failRed),
      );
    }
  }

  void _openScanner() {
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('اختر مادة أولاً'), backgroundColor: AppColors.failRed),
      );
      return;
    }
    final lectureNumber = _lectureNumberCtrl.text.trim();
    if (lectureNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('أدخل رقم المحاضرة'), backgroundColor: AppColors.failRed),
      );
      return;
    }

    final totalSessions = int.tryParse(_totalSessionsCtrl.text) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorQrScanner(
          courseId: _courseId!,
          courseName: _courseName ?? '',
          sessionType: _sessionType,
          lectureNumber: lectureNumber,
          totalSessions: totalSessions,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lectureNumberCtrl.dispose();
    _totalSessionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('مسح الحضور — إعداد')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32, // لضمان بقاء الزر بالأسفل
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المادة', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              hint: const Text('اختر مادة'),
                              value: _courseId,
                              items: _courses.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c['id'] as int,
                                  child: Text(c['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (v) {
                                final selected = _courses.firstWhere((c) => c['id'] == v, orElse: () => null);
                                setState(() {
                                  _courseId = v;
                                  _courseName = selected != null ? selected['name'] : null;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('نوع الجلسة', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('نظري'),
                              selected: _sessionType == 'theory',
                              onSelected: (_) => setState(() => _sessionType = 'theory'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('عملي'),
                              selected: _sessionType == 'lab',
                              onSelected: (_) => setState(() => _sessionType = 'lab'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lectureNumberCtrl,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'رقم المحاضرة (مثال: 1 أو 01)',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _totalSessionsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'إجمالي عدد المحاضرات للمقرر (اختياري)',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),

                        const Spacer(), // الآن سيعمل الـ Spacer بأمان كامل
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openScanner,
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                            label: const Text('افتح الماسح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}