import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )
      ..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);
  }

  Future<void> _loadUser() async {
    try {
      // طلب بيانات الملف الشخصي مباشرة من الـ API الحية بدلاً من الكاش المحلي
      final response = await ApiService.getProfile(); // أو اسم دالة جلب البروفايل لديك في ApiService

      setState(() {
        _user = response;
      });
    } catch (e) {
      // إذا فشل الاتصال المباشر، نقرأ من الكاش كخيار احتياطي
      final cachedUser = await ApiService.getUser();
      setState(() {
        _user = cachedUser;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. حماية الصفحة: إذا كانت البيانات لم تُحمل بعد، أظهر مؤشر تحميل بدلاً من الشاشة الحمراء
    if (_user == null) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Column(
            children: [
              // هيدر الصفحة
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('بطاقة الحضور الرقمية',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 24),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // إطار QR مع نبضة الانيميشن
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, child) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal
                                    .withOpacity(_pulseAnimation.value * 0.5),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _buildQrCode(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // اسم الطالب (ندعم الاحتمالين: سواء كانت البيانات داخل كائن 'data' أو مباشرة)
                      Text(
                        _user?['data']?['name'] ?? _user?['name'] ?? '...',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _user?['data']?['university_id'] ?? _user?['university_id'] ?? '',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'اعرض هذا الرمز للدكتور لتسجيل حضورك',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12),
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

  Widget _buildQrCode() {
    // فحص دقيق لجميع الاحتمالات داخل الـ JSON لضمان الوصول إلى القيمة النصية الصحيحة
    String? exactQrText;

    if (_user != null) {
      if (_user!['data'] != null) {
        exactQrText = _user!['data']['qr_code_text']?.toString() ;
      } else {
        exactQrText = _user!['qr_code_text']?.toString() ;
      }
    }

    // إذا لم يجد أي شيء (حماية ضد الـ null) يضع قيمة افتراضية بدلاً من الشاشة الحمراء
    final String finalData = exactQrText ?? "NO_DATA";

    return QrImageView(
      data: finalData,
      version: QrVersions.auto,
      size: 200.0,
      gapless: false,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0F1B35),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0F1B35),
      ),
    );
  }
}
// رسام QR بسيط
class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0F1B35);
    final teal = Paint()..color = AppColors.teal;
    final s = size.width / 21;

    // توليد matrix بسيط من hash النص
    final hash = data.codeUnits.fold(0, (p, c) => p * 31 + c);
    final matrix = List.generate(
      21,
          (i) => List.generate(21, (j) {
        // زوايا ثابتة
        if (_isFinderPattern(i, j)) return true;
        // باقي الخلايا بناءً على hash
        return ((hash >> ((i * 21 + j) % 32)) & 1) == 1;
      }),
    );

    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        if (matrix[i][j]) {
          final isAccent = (i + j) % 7 == 0 && !_isFinderPattern(i, j);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(j * s + 1, i * s + 1, s - 2, s - 2),
              const Radius.circular(2),
            ),
            isAccent ? teal : paint,
          );
        }
      }
    }
  }

  bool _isFinderPattern(int i, int j) {
    // زاوية يمين أعلى
    if (i < 7 && j < 7) return true;
    // زاوية يسار أعلى
    if (i < 7 && j > 13) return true;
    // زاوية يمين أسفل
    if (i > 13 && j < 7) return true;
    return false;
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data;
}