import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/turso_service.dart';
import '../services/email_service.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; // No longer needed

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  
  final _tursoService = TursoService();
  final _emailService = EmailService();

  int _step = 1; // 1: Email, 2: Code, 3: Details, 4: Success
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedOrgId;

  // Step 1: Send Code
  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Invalid validation email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if Email already exists (Prevent Duplicate Org Creation)
    final existingOrgs = await _tursoService.getOrganizationIdsByEmail(email);
    if (existingOrgs.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email already registered with Org ID: ${existingOrgs.first}. Please use Forgot Password.';
      });
      return;
    }

    // Generate 6 digit code
    final code = (100000 + Random().nextInt(900000)).toString();
    
    // Store in DB
    final stored = await _tursoService.storeVerificationCode(email, code);
    if (!stored) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate verification code. Check connection.';
      });
      return;
    }

    // Send Email
    final error = await _emailService.sendVerificationCode(email, code);
    
    setState(() {
      _isLoading = false;
      if (error == null) {
        _step = 2;
      } else {
        _errorMessage = error;
      }
    });
  }

  // Step 2: Verify Code
  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isValid = await _tursoService.verifyCode(email, code);

    setState(() {
      _isLoading = false;
      if (isValid) {
        _step = 3;
      } else {
        _errorMessage = 'Invalid or expired code.';
      }
    });
  }

  // Step 3: Register
  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Username and Password required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the new method that handles Defaults (Dept, Expense Type, Admin)
      final orgId = await _tursoService.registerNewOrganization(
        username, 
        password, 
        email, 
        mobile
      );

      setState(() {
        _isLoading = false;
        if (orgId != null) {
          _generatedOrgId = orgId.toString();
          // Save Org ID to SharedPreferences for auto-fill
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('saved_org_id', _generatedOrgId!);
          });
          _step = 4; // Final Success Screen
        } else {
          _errorMessage = 'Registration failed. Try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Reusing Login Screen Style)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1497215728101-856f4ea42174?ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6A11CB).withOpacity(0.3),
                  const Color(0xFF2575FC).withOpacity(0.3),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _step == 4 ? 'Registration Successful!' : 'Register',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_step == 1) ...[
                            _buildTextField(_emailController, 'Email Address', Icons.email),
                            const SizedBox(height: 20),
                            _buildButton('SEND VERIFICATION CODE', _sendCode),
                          ],

                          if (_step == 2) ...[
                            Text(
                              'Code sent to ${_emailController.text}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(_codeController, 'Verification Code', Icons.lock_clock),
                            const SizedBox(height: 20),
                            _buildButton('VERIFY CODE', _verifyCode),
                          ],

                          if (_step == 3) ...[
                            _buildTextField(_usernameController, 'Username', Icons.person),
                            const SizedBox(height: 10),
                            _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
                            const SizedBox(height: 10),
                            _buildTextField(_mobileController, 'Mobile (Optional)', Icons.phone),
                            const SizedBox(height: 20),
                            _buildButton('REGISTER', _register),
                          ],

                          if (_step == 4) ...[
                            const Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
                            const SizedBox(height: 20),
                            const Text(
                              'Your Organization ID is:',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _generatedOrgId ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Please save this ID. You will need it to login.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 30),
                            _buildButton('GO TO LOGIN', () {
                              Navigator.pop(context);
                            }),
                          ],

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          if (_step < 4) ...[
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2575FC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
