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
  int? _currentUserId;
  String? _courseName;
  String? _sessionType;
  List<String> _availableTypes = [];
  final _lectureNumberCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadCurrentUser(); // لازم يخلص أول قبل تحميل الكورسات
    await _loadCourses();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ApiService.getUser();
    setState(() => _currentUserId = user?['id']);
  }


  Future<void> _loadCourses() async {
    try {
      final res = await ApiService.getMyCourses();
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
    if (_sessionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('اختر نوع الجلسة (نظري/عملي)'), backgroundColor: AppColors.failRed),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorQrScannerScreen(
          courseId: _courseId!,
          courseName: _courseName ?? '',
          sessionType: _sessionType!,
          lectureNumber: lectureNumber,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lectureNumberCtrl.dispose();
    super.dispose();
  }

  List<String> _computeAvailableTypes(dynamic course) {
    if (course == null || _currentUserId == null) return [];
    final assignments = course['staff_assignments'];
    if (assignments == null) return [];

    final types = <String>[];
    final theoretical = (assignments['theoretical'] as List?) ?? [];
    final practical = (assignments['practical'] as List?) ?? [];

    if (theoretical.any((s) => s['id'] == _currentUserId)) types.add('theoretical');
    if (practical.any((s) => s['id'] == _currentUserId)) types.add('practical');

    return types;
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
                                  _availableTypes = _computeAvailableTypes(selected);
                                  // إذا نوع وحد بس متاح، اختاره تلقائياً. إذا الاثنين، خلي المستخدم يختار.
                                  _sessionType = _availableTypes.length == 1 ? _availableTypes.first : null;
                                });
                              },
                            ),
                          ),
                        ),
                        if (_availableTypes.length > 1) ...[
                          const SizedBox(height: 16),
                          const Text('نوع الجلسة', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('نظري'),
                                selected: _sessionType == 'theoretical',
                                onSelected: (_) => setState(() => _sessionType = 'theoretical'),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('عملي'),
                                selected: _sessionType == 'practical',
                                onSelected: (_) => setState(() => _sessionType = 'practical'),
                              ),
                            ],
                          ),
                        ],
                        if (_availableTypes.length == 1) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'نوع الجلسة: ${_availableTypes.first == 'theoretical' ? 'نظري' : 'عملي'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lectureNumberCtrl,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'رقم المحاضرة (مثال: 1 أو 2)',
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