import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class DoctorQrScanner extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String sessionType;
  final String lectureNumber;
  final int totalSessions;

  const DoctorQrScanner({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.sessionType,
    required this.lectureNumber,
    required this.totalSessions,
  });

  @override
  State<DoctorQrScanner> createState() => _DoctorQrScannerState();
}

class _DoctorQrScannerState extends State<DoctorQrScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  Timer? _cooldownTimer;
  String? _lastCode; // للاختبار/العرض
  String _log = ''; // سجل سريع للطباعة في الواجهة (debug)

  @override
  void initState() {
    super.initState();
    // حاول بدء الكاميرا فور فتح الشاشة (بعض الأجهزة تحتاج start صريح)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _controller.start();
        _appendLog('Camera started');
      } catch (e) {
        _appendLog('Camera start error: $e');
      }
    });
  }

  void _appendLog(String s) {
    setState(() => _log = '${DateTime.now().toIso8601String().substring(11,19)} | $s\n' + _log);
    // أيضا اطبع في اللوق العام
    // ignore: avoid_print
    print('DoctorQrScanner: $s');
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _lastCode = code;
    });
    _appendLog('Detected code: $code');

    try {
      final qrCode = code.trim();
      _appendLog('Calling API recordAttendanceByQr with uniId=$qrCode');
      final res = await ApiService.recordAttendanceByQr(
        qrCode: qrCode,
        courseId: widget.courseId,
        sessionType: widget.sessionType,
        totalSessions: widget.totalSessions,
        lectureNumber: widget.lectureNumber,
      );
      _appendLog('API response: ${res.toString()}');

      if (mounted) {
        if (res['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'تم تسجيل الحضور'), backgroundColor: AppColors.teal),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'فشل تسجيل الحضور'), backgroundColor: AppColors.failRed),
          );
        }
      }
    } catch (e) {
      _appendLog('API error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.failRed),
        );
      }
    } finally {
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(const Duration(milliseconds: 800), () async {
        try {
          await _controller.start();
          _appendLog('Camera restarted after cooldown');
        } catch (e) {
          _appendLog('Error restarting camera: $e');
        }
        if (mounted) setState(() => _processing = false);
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    // منع معالجة نفس الكود مرتين متتاليتين في أجزاء من الثانية
    if (raw == _lastCode && _cooldownTimer != null && _cooldownTimer!.isActive) {
      return;
    }

    setState(() {
      _processing = true;
      _lastCode = raw;
    });
    _appendLog('تم التقاط الرمز: $raw');

    try {
      // 🚀 الاتصال بالسيرفر وإرسال البيانات الحية
      final res = await ApiService.recordAttendanceByQr(
        courseId: widget.courseId,
        sessionType: widget.sessionType,
        totalSessions: widget.totalSessions,
        lectureNumber: widget.lectureNumber,
        qrCode: raw, // النص الممسوح من الـ QR
      );

      if (res['status'] == 'success') {
        _appendLog('نجاح: تم تسجيل الحضور بنجاح!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تسجيل حضور الطالب بنجاح ✅'),
              backgroundColor: AppColors.teal,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final errorMsg = res['message'] ?? 'فشل التحقق من البيانات';
        _appendLog('تنبيه من السيرفر: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تنبيه: $errorMsg ⚠️'),
              backgroundColor: AppColors.amber,
            ),
          );
        }
      }
    } catch (e) {
      _appendLog('خطأ في الاتصال: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الاتصال بالسيرفر ❌'),
            backgroundColor: AppColors.failRed,
          ),
        );
      }
    } finally {
      // إيقاف مؤقت (Cooldown) لمدة ثانية ونصف قبل السماح بمسح كود طالب آخر
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _processing = false);
        }
      });
    }
  }

  // زر محاكاة لاختبار الـ API بدون كاميرا
  // Future<void> _simulateScan() async {
  //   const sample = 'QR-1721145705-rgZ3I'; // غيّر إلى رقم جامعي حقيقي لتجربة واقعية
  //   _appendLog('Simulate pressed, sample=$sample');
  //   await _processCode(sample);
  // }
  Widget _buildOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white70, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
          ),
          child: Stack(children: [
            // شريط متحرك بسيط داخل المربع ليوضح مكان المسح
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                height: 2,
                color: AppColors.teal.withOpacity(0.9),
              ),
            ),
          ]),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('مسح — ${widget.courseName} • محاضرة ${widget.lectureNumber}'),
          actions: [
            IconButton(
              icon: ValueListenableBuilder<TorchState>(
                valueListenable: _controller.torchState,
                builder: (context, state, child) {
                  final on = state == TorchState.on;
                  return Icon(on ? Icons.flash_on : Icons.flash_off);
                },
              ),
              onPressed: () async {
                try {
                  await _controller.toggleTorch();
                } catch (e) {
                  _appendLog('toggleTorch error: $e');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded),
              onPressed: () async {
                try {
                  await _controller.switchCamera();
                } catch (e) {
                  _appendLog('switchCamera error: $e');
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              // لا تمرر allowDuplicates إذا إصدار الحزمة لا يدعمه
              onDetect: _onDetect,
            ),
            _buildOverlay(),
            // معلومات debug صغيرة أعلى الواجهة
            Positioned(
              top: 8 + MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black38,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last: ${_lastCode ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Status: ${_processing ? 'processing' : 'ready'}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
            // زر محاكاة وفوتر نصي
            Positioned(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        Text('وجه الكاميرا إلى رمز الطالب داخل المربع.', style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: ElevatedButton.icon(
                        //         onPressed: _simulateScan,
                        //         icon: const Icon(Icons.play_arrow),
                        //         label: const Text('محاكاة مسح (اختبار API)'),
                        //         style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: ElevatedButton.icon(
                        //         onPressed: () async {
                        //           // إعادة تشغيل الكاميرا يدوياً
                        //           try {
                        //             await _controller.start();
                        //             _appendLog('Manual start pressed');
                        //           } catch (e) {
                        //             _appendLog('Manual start error: $e');
                        //           }
                        //         },
                        //         icon: const Icon(Icons.refresh),
                        //         label: const Text('إعادة الكاميرا'),
                        //         style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // منطقة عرض لوج صغيرة قابلة للتمرير لعرض النصوص debug
            Positioned(
              right: 8, left: 8, bottom: 160,
              child: SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black26,
                    child: Text(_log, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}