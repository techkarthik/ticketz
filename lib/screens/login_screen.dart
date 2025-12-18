import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/turso_service.dart';
import '../services/email_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _orgIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final _tursoService = TursoService();
  final _emailService = EmailService();

  @override
  void initState() {
    super.initState();
    _loadSavedOrgId();
  }

  Future<void> _loadSavedOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_org_id');
    if (savedId != null) {
      if (mounted) setState(() => _orgIdController.text = savedId);
    }
  }

  Future<void> _handleLogin() async {
    final orgIdStr = _orgIdController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (orgIdStr.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    int? orgId;
    try {
      orgId = int.parse(orgIdStr);
    } catch (_) {
      setState(() {
        _errorMessage = 'Invalid Organization ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _tursoService.login(orgId, username, password);

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(user));
      await prefs.setString('saved_org_id', orgId.toString()); // Save Org ID

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DashboardScreen(user: user)),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials or Organization ID';
      });
    }
  }

  // --- RECOVERY FLOWS ---

  // Reusable OTP Sender
  Future<String?> _sendOtp(String email) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    final stored = await _tursoService.storeVerificationCode(email, code);
    if (!stored) return 'Database Error';
    return await _emailService.sendVerificationCode(email, code);
  }

  // 1. Forgot Organization ID
  Future<void> _showForgotOrgIdDialog() async {
    final emailCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    int step = 1;
    String? error;
    bool loading = false;
    List<int>? retrievedIds;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Find Organization ID'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step == 1) ...[
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Enter Registered Email')),
                ],
                if (step == 2) ...[
                  TextField(controller: otpCtrl, decoration: const InputDecoration(labelText: 'Enter Verification Code')),
                ],
                if (step == 3) ...[
                  const Text('Your Organization ID(s):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SelectableText(
                    retrievedIds!.join(', '), 
                    style: const TextStyle(fontSize: 24, color: Colors.blueAccent, fontWeight: FontWeight.bold)
                  ),
                ],
                if (error != null) ...[
                   const SizedBox(height: 10),
                   Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                if (loading) ...[
                   const SizedBox(height: 10),
                   const CircularProgressIndicator(),
                ]
              ],
            ),
            actions: [
              if (step == 1)
                TextButton(
                  onPressed: loading ? null : () async {
                    if(emailCtrl.text.isEmpty) return;
                    setDialogState(() { loading = true; error = null; });
                    
                    // Check if email even exists
                    final ids = await _tursoService.getOrganizationIdsByEmail(emailCtrl.text.trim());
                    if (ids.isEmpty) {
                       setDialogState(() { loading = false; error = "Email not found."; });
                       return;
                    }

                    final err = await _sendOtp(emailCtrl.text.trim());
                    setDialogState(() { 
                      loading = false; 
                      if (err == null) { step = 2; } else { error = err; }
                    });
                  },
                  child: const Text('Send Code'),
                ),
              if (step == 2)
                 TextButton(
                  onPressed: loading ? null : () async {
                     setDialogState(() { loading = true; error = null; });
                     final valid = await _tursoService.verifyCode(emailCtrl.text.trim(), otpCtrl.text.trim());
                     if (valid) {
                        final ids = await _tursoService.getOrganizationIdsByEmail(emailCtrl.text.trim());
                        setDialogState(() { loading = false; step = 3; retrievedIds = ids; });
                     } else {
                        setDialogState(() { loading = false; error = "Invalid Code"; });
                     }
                  },
                  child: const Text('Verify'),
                ),
              if (step == 3)
                 TextButton(onPressed: () => Navigator.pop(context, retrievedIds!.first), child: const Text('Use this ID')),
            ],
          );
        }
      )
    );
    
    if (result != null) {
      setState(() => _orgIdController.text = result.toString());
    }
  }

  // 2. Forgot Password
  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    final orgIdCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    int step = 1;
    String? error;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: SingleChildScrollView( // Avoid overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (step == 1) ...[
                     TextField(controller: orgIdCtrl, decoration: const InputDecoration(labelText: 'Organization ID')),
                     TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Registered Email')),
                   ],
                   if (step == 2) ...[
                      TextField(controller: otpCtrl, decoration: const InputDecoration(labelText: 'Enter Verification Code')),
                   ],
                   if (step == 3) ...[
                      TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
                   ],
                   if (step == 4) ...[
                      const Icon(Icons.check_circle, color: Colors.green, size: 50),
                      const Text('Password Reset Successfully!'),
                   ],
                   if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                   ],
                   if (loading) ...[
                      const SizedBox(height: 10),
                      const CircularProgressIndicator(),
                   ]
                ],
              ),
            ),
            actions: [
              if (step == 1)
                 TextButton(
                  onPressed: loading ? null : () async {
                     final oid = int.tryParse(orgIdCtrl.text);
                     if (emailCtrl.text.isEmpty || oid == null) {
                        setDialogState(() => error = "Invalid Input");
                        return;
                     }
                     setDialogState(() { loading = true; error = null; });
                     
                     // Verify Org/Email match
                      final users = await _tursoService.getUsers(oid); // Not efficient but simple query
                      final userExists = users.any((u) => u['email'] == emailCtrl.text.trim());
                      
                      if (!userExists) {
                         setDialogState(() { loading = false; error = "User not found in this Org."; });
                         return;
                      }

                     final err = await _sendOtp(emailCtrl.text.trim());
                     setDialogState(() { 
                       loading = false; 
                       if (err == null) { step = 2; } else { error = err; }
                     });
                  },
                  child: const Text('Send Code'),
                ),
               if (step == 2)
                 TextButton(
                  onPressed: loading ? null : () async {
                     setDialogState(() { loading = true; error = null; });
                     final valid = await _tursoService.verifyCode(emailCtrl.text.trim(), otpCtrl.text.trim());
                     if (valid) {
                       setDialogState(() { loading = false; step = 3; });
                     } else {
                       setDialogState(() { loading = false; error = "Invalid Code"; });
                     }
                  },
                  child: const Text('Verify'),
                ),
               if (step == 3)
                 TextButton(
                  onPressed: loading ? null : () async {
                     if (newPassCtrl.text.isEmpty) return;
                     setDialogState(() { loading = true; error = null; });
                     final success = await _tursoService.resetPassword(
                        int.parse(orgIdCtrl.text), 
                        emailCtrl.text.trim(), 
                        newPassCtrl.text.trim()
                     );
                     setDialogState(() { 
                       loading = false; 
                       if (success) { step = 4; } else { error = "Failed to reset password."; }
                     });
                  },
                  child: const Text('Reset Password'),
                ),
                if (step == 4)
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          );
        }
      )
    );
  }

  // ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo / Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E8B57).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet,
                                size: 50, color: Color(0xFF2ECC71)),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Xpenze',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Login Form
                          TextField(
                            controller: _orgIdController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              hintText: 'Organization ID',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              prefixIcon:
                                  const Icon(Icons.business, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                           const SizedBox(height: 20),
                          
                           TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              hintText: 'Username',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              prefixIcon:
                                  const Icon(Icons.person, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              prefixIcon:
                                  const Icon(Icons.lock, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Recovery Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _showForgotOrgIdDialog,
                                child: const Text("Forgot Org ID?", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2ECC71),
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Register Link
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RegisterScreen())
                              );
                            },
                            child: const Text(
                              "Don't have an ID? Register here",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
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
}
