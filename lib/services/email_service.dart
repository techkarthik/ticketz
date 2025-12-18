import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // EmailJS Credentials
  static const String _backendUrl = 'http://72.60.23.223:3000'; // VPS URL

  /// Returns null on success, or an error message string on failure.
  Future<String?> sendVerificationCode(String email, String code) async {
    final url = Uri.parse('$_backendUrl/auth/send-code');
    print('[EmailService] Requesting Backend to send code $code to: $email');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true) {
             print('Backend Email Success');
             return null;
        } else {
             return 'Backend Error: ${res['error'] ?? 'Unknown'}';
        }
      } else {
        return 'Failed to reach backend: ${response.statusCode}';
      }
    } catch (e) {
      print('Email Exception: $e');
      return 'Connection Error: $e';
    }
  }
}
