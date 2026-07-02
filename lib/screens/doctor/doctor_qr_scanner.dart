import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class DoctorQrScannerScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String sessionType; 
  final String lectureNumber;

  const DoctorQrScannerScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.sessionType,
    required this.lectureNumber,
  });

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  Timer? _cooldownTimer;
  String? _lastCode;

  int? _sessionId;
  int _scannedCount = 0;
  int _totalEnrolled = 0;
  List<Map> _scannedStudents = [];
  bool _isSessionActive = false;

  @override
  void initState() {
    super.initState();
    _startSession();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _controller.start();
      } catch (e) {
        debugPrint('Camera start error: $e');
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    try {
      final res = await ApiService.startAttendanceSession(
        courseId: widget.courseId,
        sessionType: widget.sessionType,
        lectureNumber: widget.lectureNumber,
      );

      if (res['status'] == 'success') {
        setState(() {
          _sessionId = res['data']['session_id'];
          _totalEnrolled = res['data']['total_enrolled'];
          _isSessionActive = true;
        });
      }
    } catch (e) {
      _showSnack('خطأ في بدء الجلسة: ${e.toString()}', AppColors.failRed);
    }
  }

  // دالة تسجيل الحضور الموحدة باستخدام دالة recordAttendance المطلوبة
  Future<void> _recordAttendance(String qr_code) async {
    if (_sessionId == null) {
      _showSnack('الجلسة غير مفعّلة', AppColors.failRed);
      return;
    }

    try {
      final res = await ApiService.recordAttendance(
        sessionId: _sessionId!,
        qrcode: qr_code,
      );

      if (res['status'] == 'success') {
        setState(() {
          _scannedCount++;
          _scannedStudents.insert(0, {
            'name': res['student_name'] ?? qr_code,
            'scanned_at': DateTime.now(),
          });
        });
        _showSnack('تم تسجيل حضور: ${res['student_name'] ?? qr_code} ✓', AppColors.passGreen);
      } else {
        _showSnack(res['message'] ?? 'فشل تسجيل الحضور', AppColors.failRed);
      }
    } catch (e) {
      _showSnack('خطأ: ${e.toString()}', AppColors.failRed);
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;

    try {
      final res = await ApiService.endAttendanceSession(_sessionId!);

      if (res['status'] == 'success') {
        _showSnack('تم إنهاء الجلسة وإرسال الإشعارات بنجاح ✓', AppColors.passGreen);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(res['message'] ?? 'خطأ أثناء إنهاء الجلسة', AppColors.failRed);
      }
    } catch (e) {
      _showSnack('خطأ: ${e.toString()}', AppColors.failRed);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing || _sessionId == null) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    if (raw == _lastCode && _cooldownTimer != null && _cooldownTimer!.isActive) {
      return;
    }

    if (_sessionId == null) {
      _showSnack('تنبيه: الجلسة لم تفعّل بعد ⚠️', AppColors.amber);
      return;
    }

    setState(() {
      _processing = true;
      _lastCode = raw;
    });

    try {
      // 🚀 تم الاستدعاء هنا باستخدام الـ API المطلوب recordAttendance مباشرة
      final res = await ApiService.recordAttendance(
        sessionId: _sessionId!,
        qrcode: raw.trim(), //
      );

      if (res['status'] == 'success') {
        setState(() {
          _scannedCount++;
          _scannedStudents.insert(0, {
            'name': res['student_name'] ?? 'طالب مجهول',
            'scanned_at': DateTime.now(),
          });
        });
        if (mounted) {
          _showSnack('تم تسجيل حضور الطالب بنجاح ✅', AppColors.teal);
        }
      } else {
        final errorMsg = res['message'] ?? 'فشل التحقق من البيانات';
        if (mounted) _showSnack('تنبيه: $errorMsg ⚠️', AppColors.amber);
      }
    } catch (e) {
      if (mounted) _showSnack('خطأ أثناء الاتصال بالسيرفر ❌', AppColors.failRed);
    } finally {
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _processing = false);
        }
      });
    }
  }

  void _openManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إدخال الرقم الجامعي'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'أدخل الرقم الجامعي',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _recordAttendance(controller.text.trim());
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white70, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
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
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _isSessionActive
                ? Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            )
                : const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.teal),
                    SizedBox(height: 12),
                    Text('جاري بدء الجلسة وجلب البيانات...',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            _buildOverlay(),

            // المحتوى العلوي: الهيدر وكارد الإحصائيات
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.courseName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                              ),
                              Text(
                                '${widget.sessionType == 'theoretical' ? 'نظري' : 'عملي'} - ${widget.lectureNumber}',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: ValueListenableBuilder<TorchState>(
                              valueListenable: _controller.torchState,
                              builder: (context, state, child) {
                                final on = state == TorchState.on;
                                return Icon(on ? Icons.flash_on : Icons.flash_off, color: Colors.white);
                              },
                            ),
                            onPressed: () => _controller.toggleTorch(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                            onPressed: () => _controller.switchCamera(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statCol('المسجلون', '$_totalEnrolled'),
                        Container(width: 1, height: 35, color: Colors.white24),
                        _statCol('الممسوحون', '$_scannedCount'),
                        Container(width: 1, height: 35, color: Colors.white24),
                        _statCol('الباقيون', '${_totalEnrolled - _scannedCount}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // قائمة الطلاب الممسوحين في المنتصف
            Positioned(
              top: MediaQuery.of(context).padding.top + 160,
              bottom: 240,
              left: 16,
              right: 16,
              child: _scannedStudents.isEmpty
                  ? const Center(
                child: Text(
                  'لم يتم مسح أي طالب بعد',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _scannedStudents.length,
                itemBuilder: (_, i) {
                  final student = _scannedStudents[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.passBg.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.passGreen.withOpacity(0.4), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.passGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            student['name'],
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${student['scanned_at'].hour}:${student['scanned_at'].minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // الفوتر والأزرار السفلية
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _endSession,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('الانتهاء من التسجيل وإرسال الإشعارات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.failRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}