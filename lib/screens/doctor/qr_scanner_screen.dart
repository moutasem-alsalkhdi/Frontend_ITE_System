import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // هنا يمكنك الاتصال بواجهة API لتسجيل الحضور (مثال):
      // final res = await ApiService.recordAttendanceByQr(raw, courseId: ...);
      // TODO: استبدل الكود أعلاه بالمنطق الحقيقي الذي تريد: تحليل نص الـ QR ثم إرسال POST إلى السيرفر.

      // مؤقتاً نعرض إشعار نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم مسح: $raw'), backgroundColor: AppColors.teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تسجيل الحضور: ${e.toString()}'), backgroundColor: AppColors.failRed),
        );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ماسح الحضور'),
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
          ],
        ),
      ),
    );
  }
}