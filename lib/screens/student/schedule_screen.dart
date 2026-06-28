import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List _schedules = [];
  bool _loading = true;
  int? _targetYear;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _user = await ApiService.getUser();
    _targetYear = (_user?['year_of_study'] as int?) ?? 1;
    setState(() {});
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getSchedules(targetYear: _targetYear);
      setState(() {
        _schedules = res['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int get _maxYear => (_user?['year_of_study'] as int?) ?? 5;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            _buildYearPicker(),
            Expanded(
              child: _loading
                  ? const LoadingWidget()
                  : _schedules.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: AppColors.textHint, size: 52),
                    SizedBox(height: 12),
                    Text('لا يوجد جدول لهذه السنة بعد',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.teal,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      16, 16, 16, 100),
                  itemCount: _schedules.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _buildScheduleCard(_schedules[i]),
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
          const Text('الجداول الدراسية',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('السنة الدراسية',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: List.generate(5, (i) => i + 1).map((y) {
                final active = _targetYear == y;
                final isMyYear = y == _maxYear;
                return GestureDetector(
                  onTap: () {
                    setState(() => _targetYear = y);
                    _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.navy : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AppColors.navy
                            : isMyYear
                            ? AppColors.teal
                            : AppColors.border,
                        width: active || isMyYear ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('السنة $y',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                        if (isMyYear && !active) ...[
                          const SizedBox(width: 4),
                          const Text('• سنتي',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map s) {
    final semesterMap = {1: 'الأول', 2: 'الثاني', 3: 'الصيفي'};
    final semester = semesterMap[s['semester']] ?? '${s['semester']}';
    final imageUrl = s['image_url'] ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هيدر الكارد
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s['title'] ?? 'جدول دراسي',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.passBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('فصل $semester',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.passGreen)),
                ),
              ],
            ),
          ),
          // صورة الجدول
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.background,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.teal,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.background,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            color: AppColors.textHint, size: 40),
                        SizedBox(height: 8),
                        Text('تعذر تحميل الصورة',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 160,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.calendar_month_rounded,
                    color: AppColors.textHint, size: 48),
              ),
            ),
          const SizedBox(height: 4),
          // معلومات المرفوع
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              'رُفع بواسطة: ${s['uploaded_by_name'] ?? '—'}  ·  ${s['academic_year'] ?? ''}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}