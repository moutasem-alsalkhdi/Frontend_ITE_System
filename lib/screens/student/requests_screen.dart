import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getStudentRequests();
      setState(() {
        _requests = res['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pay(int requestId) async {
    try {
      final res = await ApiService.payForService(requestId);
      if (res['status'] == 'success') {
        _showSnack('تم الدفع بنجاح ✓', AppColors.teal);
        _load();
      } else {
        _showSnack(res['message'] ?? 'حدث خطأ', AppColors.failRed);
      }
    } catch (_) {
      _showSnack('تعذر الاتصال بالخادم', AppColors.failRed);
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

  // ── عند الضغط على نوع الطلب ──
  void _onRequestTypeTapped(String type, String label) {
    if (type == 'grade_sheet' || type == 'life_cert') {
      // لا يحتاج مادة — نقدم مباشرة بعد تأكيد
      _showSimpleConfirmDialog(type, label);
    } else if (type == 'objection') {
      // يحتاج: نوع الاعتراض أولاً ثم اختيار المادة
      _showObjectionTypeSheet(label);
    } else if (type == 'lab_redo') {
      // يحتاج: اختيار المادة مباشرة (فقط المواد المؤهلة)
      _showCoursePicker(type: type, label: label, objectionType: null);
    }
  }

  // ── حوار تأكيد بسيط (بدون مادة) ──
  void _showSimpleConfirmDialog(String type, String label) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد الطلب',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          content: Text('هل تريد تقديم طلب: $label؟',
              style: const TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final res =
                await ApiService.submitRequest(requestType: type);
                if (res['status'] == 'success') {
                  _showSnack('تم تقديم الطلب بنجاح ✓', AppColors.teal);
                } else {
                  _showSnack(
                      res['message'] ?? 'حدث خطأ', AppColors.failRed);
                }
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تأكيد',
                  style:
                  TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  // ── اختيار نوع الاعتراض (نظري / عملي) ──
  void _showObjectionTypeSheet(String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('نوع الاعتراض',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              _objTypeBtn(Icons.menu_book_rounded, 'اعتراض نظري',
                  'theoretical', label),
              const SizedBox(height: 10),
              _objTypeBtn(Icons.science_outlined, 'اعتراض عملي',
                  'practical', label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _objTypeBtn(
      IconData icon, String text, String objType, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showCoursePicker(
            type: 'objection', label: label, objectionType: objType);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.navy, size: 22),
            const SizedBox(width: 12),
            Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }

  // ── اختيار المادة (يجلب المواد المؤهلة من الـ API) ──
  Future<void> _showCoursePicker({
    required String type,
    required String label,
    required String? objectionType,
  }) async {
    // نعرض loading بسيط
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.teal)),
    );

    List courses = [];
    try {
      final res = await ApiService.getEligibleCourses(type);
      // الـ API يرجع List مباشرة أو Map فيها data
      if (res is List) {
        courses = res;
      } else {
        courses = res['data'] ?? [];
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // أغلق loading

    if (courses.isEmpty) {
      _showSnack('لا توجد مواد مؤهلة لهذا الطلب حالياً', AppColors.amber);
      return;
    }

    int? selectedCourseId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text('اختر المادة — $label',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo')),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: courses.length,
                      itemBuilder: (_, i) {
                        final c = courses[i];
                        final id = c['id'] as int;
                        final isSelected = selectedCourseId == id;
                        return GestureDetector(
                          onTap: () =>
                              setSheet(() => selectedCourseId = id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.navy.withOpacity(0.06)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.navy
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(c['name'] ?? '',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Cairo')),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.teal, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedCourseId == null
                          ? null
                          : () async {
                        Navigator.pop(ctx);
                        final submitRes =
                        await ApiService.submitRequest(
                          requestType: type,
                          courseId: selectedCourseId,
                          objectionType: objectionType,
                        );
                        if (submitRes['status'] == 'success') {
                          _showSnack(
                              'تم تقديم الطلب بنجاح ✓', AppColors.teal);
                        } else {
                          _showSnack(
                              submitRes['message'] ?? 'حدث خطأ',
                              AppColors.failRed);
                        }
                        _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        disabledBackgroundColor: AppColors.border,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('تقديم الطلب',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
              child: _loading
                  ? const LoadingWidget()
                  : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.teal,
                child: ListView(
                  padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _buildRequestTypes(),
                    const SizedBox(height: 16),
                    const SectionTitle(title: 'طلباتي الحالية'),
                    if (_requests.isEmpty)
                      const AppCard(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('لا توجد طلبات بعد',
                                style: TextStyle(
                                    color: AppColors.textHint)),
                          ),
                        ),
                      )
                    else
                      ..._requests.map((r) => Padding(
                        padding:
                        const EdgeInsets.only(bottom: 10),
                        child: _buildRequestCard(r),
                      )),
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
      child: const Row(
        children: [
          Text('الطلبات الجامعية',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildRequestTypes() {
    final types = [
      {
        'icon': Icons.description_outlined,
        'label': 'كشف علامات',
        'type': 'grade_sheet',
        'color': const Color(0xFFE6F1FB),
        'iconColor': const Color(0xFF185FA5)
      },
      {
        'icon': Icons.warning_amber_rounded,
        'label': 'اعتراض على علامة',
        'type': 'objection',
        'color': AppColors.pendingBg,
        'iconColor': AppColors.pendingText
      },
      {
        'icon': Icons.science_outlined,
        'label': 'إعادة العملي',
        'type': 'lab_redo',
        'color': const Color(0xFFE1F5EE),
        'iconColor': const Color(0xFF0F6E56)
      },
      {
        'icon': Icons.verified_outlined,
        'label': 'شهادة حياة جامعية',
        'type': 'life_cert',
        'color': const Color(0xFFEEEDFE),
        'iconColor': const Color(0xFF534AB7)
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: types.map((t) {
        return AppCard(
          onTap: () =>
              _onRequestTypeTapped(t['type'] as String, t['label'] as String),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t['color'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(t['icon'] as IconData,
                    color: t['iconColor'] as Color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(t['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRequestCard(Map r) {
    final status = r['status'] ?? 'pending';
    final statusMap = {
      'pending': {'label': 'قيد المراجعة', 'bg': AppColors.pendingBg, 'color': AppColors.pendingText},
      'awaiting_payment': {'label': 'بانتظار الدفع', 'bg': const Color(0xFFE6F1FB), 'color': const Color(0xFF185FA5)},
      'ready': {'label': 'جاهز للاستلام', 'bg': AppColors.passBg, 'color': AppColors.passGreen},
      'completed': {'label': 'مكتمل', 'bg': AppColors.passBg, 'color': AppColors.passGreen},
      'rejected': {'label': 'مرفوض', 'bg': AppColors.failBg, 'color': AppColors.failRed},
      'paid': {'label': 'مدفوع', 'bg': AppColors.passBg, 'color': AppColors.passGreen},
    };
    final typeMap = {
      'grade_sheet': 'كشف علامات',
      'objection': 'اعتراض على علامة',
      'lab_redo': 'إعادة العملي',
      'life_cert': 'شهادة حياة جامعية',
    };
    final st = statusMap[status] ?? statusMap['pending']!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(typeMap[r['request_type']] ?? r['request_type'],
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: st['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(st['label'] as String,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: st['color'] as Color)),
              ),
            ],
          ),
          if (r['course_name'] != null) ...[
            const SizedBox(height: 6),
            Text(r['course_name'],
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (r['admin_note'] != null) ...[
            const SizedBox(height: 6),
            Text('ملاحظة: ${r['admin_note']}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (status == 'awaiting_payment' && r['fee_amount'] != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الرسوم: ${r['fee_amount']} ل.س',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                ElevatedButton(
                  onPressed: () => _pay(r['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('ادفع الآن',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Cairo')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}