import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'student/home_screen.dart';
import 'doctor/doctor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedRole = 0;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _otpToken;

  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _studentIdController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHero(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      _buildRoleTabs(),
                      const SizedBox(height: 28),
                      _selectedRole == 0
                          ? _buildStudentForm()
                          : _buildDoctorForm(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.teal.withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.school_rounded,
                color: AppColors.teal, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('المنصة الجامعية الذكية',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('كلية تقنية المعلومات والهندسة',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _tab('طالب', 0),
        _tab('دكتور / معيد', 1),
      ]),
    );
  }

  Widget _tab(String label, int index) {
    final active = _selectedRole == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = index;
          _otpSent = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.navy : AppColors.textHint)),
        ),
      ),
    );
  }

  Widget _buildStudentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('الرقم الجامعي'),
        _field(
            controller: _studentIdController,
            hint: 'أدخل رقمك الجامعي',
            icon: Icons.badge_outlined),
        const SizedBox(height: 28),
        _loginBtn('دخول', _handleStudentLogin),
        const SizedBox(height: 12),
        Center(
          child: Text('الطلاب يدخلون برقمهم الجامعي فقط',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDoctorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('البريد الإلكتروني'),
        _field(
            controller: _emailController,
            hint: 'أدخل بريدك الإلكتروني',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        if (_otpSent) ...[
          _label('رمز OTP'),
          _field(
              controller: _otpController,
              hint: 'أدخل الرمز المرسل لبريدك',
              icon: Icons.lock_outline_rounded,
              keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          _loginBtn('دخول', _handleDoctorLogin),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _handleRequestOtp,
              child: const Text('إعادة إرسال الرمز',
                  style: TextStyle(
                      color: AppColors.teal, fontFamily: 'Cairo')),
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          _loginBtn('إرسال رمز OTP', _handleRequestOtp),
        ],
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569))),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            prefixIcon:
            Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      );

  Widget _loginBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2))
          : Text(label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );

  // ── API Handlers ──

  Future<void> _handleStudentLogin() async {
    if (_studentIdController.text.trim().isEmpty) {
      _snack('الرجاء إدخال الرقم الجامعي');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res =
      await ApiService.studentLogin(_studentIdController.text.trim());
      if (res['token'] != null) {
        await ApiService.saveToken(res['token']);
        await ApiService.saveUser(res['user'], 'student');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          );
        }
      } else {
        _snack(res['message'] ?? 'الرقم الجامعي غير صحيح');
      }
    } catch (_) {
      _snack('تعذر الاتصال بالخادم');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleRequestOtp() async {
    if (_emailController.text.trim().isEmpty) {
      _snack('الرجاء إدخال البريد الإلكتروني');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res =
      await ApiService.requestOtp(_emailController.text.trim());
      if (res['otp_token'] != null) {
        setState(() {
          _otpToken = res['otp_token'];
          _otpSent = true;
        });
        _snack('تم إرسال رمز OTP على بريدك');
      } else {
        _snack(res['message'] ?? 'البريد الإلكتروني غير مسجل');
      }
    } catch (_) {
      _snack('تعذر الاتصال بالخادم');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleDoctorLogin() async {
    if (_otpController.text.trim().isEmpty || _otpToken == null) {
      _snack('الرجاء إدخال رمز OTP');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.doctorLogin(
          _otpToken!, _otpController.text.trim());
      if (res['token'] != null) {
        await ApiService.saveToken(res['token']);
        await ApiService.saveUser(res['user'], 'doctor');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
          );
        }
      } else {
        _snack(res['message'] ?? 'رمز OTP غير صحيح');
      }
    } catch (_) {
      _snack('تعذر الاتصال بالخادم');
    }
    setState(() => _isLoading = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}