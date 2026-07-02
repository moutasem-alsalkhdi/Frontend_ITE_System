import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  /// عنوان السيرفر — عدّله مرة واحدة هنا فقط:
  /// - Android emulator : 10.0.2.2
  /// - iOS simulator    : 127.0.0.1
  /// - جهاز حقيقي      : IP جهاز الكمبيوتر على الشبكة المحلية (مثال: 192.168.1.5)
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '', // يُعيَّن عبر --dart-define=API_HOST=192.168.1.5 عند البناء
  );

  static String get baseUrl {
    // إذا تم تحديد host عبر --dart-define استخدمه مباشرة
    if (_host.isNotEmpty) return 'http://$_host:8000/api';
    // fallback تلقائي حسب المنصة
    final defaultHost = '127.0.0.1';
    //final defaultHost = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$defaultHost:8000/api';
  }

  // ── جلب التوكن المحفوظ ──
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ── حفظ التوكن ──
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ── حفظ بيانات المستخدم ──
  static Future<void> saveUser(Map<String, dynamic> user, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
    await prefs.setString('role', role);
  }

  // ── جلب بيانات المستخدم ──
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  // ── جلب الدور ──
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ── تسجيل خروج ──
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Headers مع التوكن ──
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ════════════════════════════════════════
  // AUTH APIs
  // ════════════════════════════════════════

  static Future<Map<String, dynamic>> studentLogin(String universityId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/student/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'university_id': universityId}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> requestOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/doctor/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> doctorLogin(
      String otpToken, String otpCode) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/doctor/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'otp_token': otpToken, 'otp_code': otpCode}),
    );
    return jsonDecode(res.body);
  }

  static Future<void> logout() async {
    final headers = await _authHeaders();
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: headers);
    await clearSession();
  }

  // ════════════════════════════════════════
  // STUDENT APIs
  // ════════════════════════════════════════

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/student/profile'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getWalletBalance() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/student/wallet/balance'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getWalletTransactions() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/student/wallet/transactions'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getAcademicRecord({
    String? academicYear,
    int? semester,
    String? status,
    int? yearOfStudy,
  }) async {
    final headers = await _authHeaders();
    final params = <String, String>{};
    if (academicYear != null) params['academic_year'] = academicYear;
    if (semester != null) params['semester'] = semester.toString();
    if (status != null) params['status'] = status;
    if (yearOfStudy != null) params['year_of_study'] = yearOfStudy.toString();

    String url = '$baseUrl/student/academic-record';
    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    final res = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getAttendance({int? courseId}) async {
    final headers = await _authHeaders();
    String url = '$baseUrl/student/attendance';
    if (courseId != null) url += '?course_id=$courseId';
    final res = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getSchedules({int? targetYear}) async {
    final headers = await _authHeaders();
    String url = '$baseUrl/student/schedules';
    if (targetYear != null) url += '?target_year=$targetYear';
    final res = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getStudentRequests() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/student/requests'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> submitRequest({
    required String requestType,
    int? courseId,
    String? objectionType,

  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'request_type': requestType};
    if (courseId != null) body['course_id'] = courseId;
    if (objectionType != null) body['objection_type'] = objectionType;
    final res = await http.post(
      Uri.parse('$baseUrl/student/requests'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> payForService(
      int serviceRequestId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/student/wallet/pay'),
      headers: headers,
      body: jsonEncode({'service_request_id': serviceRequestId}),
    );
    return jsonDecode(res.body);
  }

  // ════════════════════════════════════════
  // SHARED APIs
  // ════════════════════════════════════════

  static Future<Map<String, dynamic>> getAnnouncements() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/announcements'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> markAllRead() async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteNotification(String id) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getLectureFiles(int courseId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/LectureFile?course_id=$courseId'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getCourses() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/courses/info'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }
  static Future<Map<String, dynamic>> getMyCourses() async {
    final headers = await _authHeaders();
    final res = await http.get(
        Uri.parse('$baseUrl/courses/assignments'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load courses');
    }
  }

  static Future<dynamic> getEligibleCourses(String requestType) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/student/eligible-courses?request_type=$requestType'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  // Add these methods to ApiService clas
// ════════════════════════════════════════
// DOCTOR APIs - محاضرات
// ════════════════════════════════════════

  static Future<Map<String, dynamic>> uploadLectureFile({
    required int courseId,
    required String title,
    required String academicYear,
    required PlatformFile file,
  }) async {
    final token = await getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/LectureFile/upload-lecfile'),
    );

    request.headers.addAll(headers);
    request.fields['course_id'] = courseId.toString();
    request.fields['title'] = title;
    request.fields['academic_year'] = academicYear;
    request.files.add(
      http.MultipartFile.fromBytes(
        'lecture_file',
        file.bytes ?? [],
        filename: file.name,
      ),
    );

    final response = await request.send();
    final res = await http.Response.fromStream(response);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    String? content,
    int? courseId,
    int? targetYear,
    bool isPermanent = false,
    String? expiresAt,
    PlatformFile? mediaFile,
  }) async {
    final token = await getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/academic/announcements'),
    );

    request.headers.addAll(headers);
    request.fields['title'] = title;
    if (content != null) request.fields['content'] = content;
    if (courseId != null) request.fields['course_id'] = courseId.toString();
    if (targetYear != null) request.fields['target_year'] = targetYear.toString();
    request.fields['is_permanent'] = isPermanent ? '1' : '0';
    if (expiresAt != null) request.fields['expires_at'] = expiresAt;

    if (mediaFile != null && mediaFile.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'media_file',
          mediaFile.bytes ?? [],
          filename: mediaFile.name,
        ),
      );
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getLectureAttendance({
    required int courseId,
    required String sessionType,
    required String lectureNumber,
    String scope = 'all',
  }) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(
        '$baseUrl/doctor/attendance/list?course_id=$courseId&session_type=$sessionType&lecture_number=$lectureNumber&scope=$scope',
      ),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> recordAttendanceByQr({
    required int courseId,
    required String sessionType,
    required String lectureNumber,
    required String qrCode,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/record-qr'), // تأكد من مطابقة هذا الرابط مع الـ Routes في Laravel
      headers: headers,
      body: jsonEncode({
        'qr_code': qrCode,
        'course_id': courseId,
        'session_type': sessionType,
        'lecture_number': lectureNumber,
      }),
    );
    return jsonDecode(response.body);
  }


  // أضف هذه الدوال:

  static Future<Map> startAttendanceSession({
    required int courseId,
    required String sessionType,
    required String lectureNumber,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/session/start'),
      headers: headers,
      body: jsonEncode({
        'course_id': courseId,
        'session_type': sessionType,
        'lecture_number': lectureNumber,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> recordAttendance({
    required int sessionId,
    required String qrcode,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/record'),
      headers: headers,
      body: jsonEncode({
        'session_id': sessionId,
        'qr_code': qrcode,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> endAttendanceSession(int sessionId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/session/end'),
      headers: headers,
      body: jsonEncode({'session_id': sessionId}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> getDetailedAttendance({
    required int courseId,
    String? sessionType,
  }) async {
    final headers = await _authHeaders();
    String url = '$baseUrl/student/attendance/detailed?course_id=$courseId';
    if (sessionType != null) url += '&session_type=$sessionType';

    final res = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getStudentAttendance() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/student/attendance'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  // أضف هذه الدالة

  static Future<Map> getDoctorCourseAssignment(int courseId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/doctor/course-assignment?course_id=$courseId'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

}