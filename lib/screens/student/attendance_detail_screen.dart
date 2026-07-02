import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String sessionType; // theoretical / practical
  final String sessionTypeLabel;

  const AttendanceDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.sessionType,
    required this.sessionTypeLabel,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  bool _loading = true;
  List _records = [];
  Map _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getDetailedAttendance(
        courseId: widget.courseId,
        sessionType: widget.sessionType,
      );
      setState(() {
        _records = res['data'] ?? [];
        _stats = res['stats'] ?? {};
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('${widget.courseName} — ${widget.sessionTypeLabel}')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : RefreshIndicator(
          onRefresh: _load,
          color: AppColors.teal,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsCard(),
              const SizedBox(height: 16),
              if (_records.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('لا توجد جلسات منتهية بعد', style: TextStyle(color: AppColors.textHint)),
                  ),
                )
              else
                ..._records.map((r) => _buildLectureCard(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final present = _stats['present_count'] ?? 0;
    final total = _stats['total_sessions'] ?? 0;
    final pct = _stats['percentage'] ?? 0;
    return AppCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نسبة الحضور', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text('$present / $total محاضرة',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          Text('$pct%',
              style: const TextStyle(color: AppColors.teal, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildLectureCard(Map r) {
    final isPresent = r['status'] == 'حاضر';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isPresent ? AppColors.teal : AppColors.failRed).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isPresent ? AppColors.teal : AppColors.failRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('محاضرة ${r['lecture_number']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text('د. ${r['doctor_name'] ?? '—'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            Text(
              r['status'] ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPresent ? AppColors.teal : AppColors.failRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}