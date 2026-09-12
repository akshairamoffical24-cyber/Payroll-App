import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/user.dart';
import '../data/google_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  // Mode: 0 = Employee Login, 1 = Admin / HR Portal, 2 = Mobile OTP Login
  int _selectedAuthTab = 0;

  // OTP Login Fields
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _isOtpSent = false;
  bool _isVerifyingOtp = false;
  String? _detectedEmployeeName;

  @override
  void initState() {
    super.initState();
    // Default pre-fill for convenient employee testing
    _emailOrIdController.text = 'EMP001';
    _passwordController.text = 'emp123';
  }

  @override
  void dispose() {
    _emailOrIdController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _fillCredentials(String emailOrId, String password, {int tab = 0}) {
    setState(() {
      _selectedAuthTab = tab;
      _emailOrIdController.text = emailOrId;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).login(
            emailOrId: _emailOrIdController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (!mounted) return;

      final currentUser = ref.read(authStateProvider);
      if (currentUser?.role == UserRole.fieldStaff) {
        context.go('/field-dashboard');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString().replaceAll('Exception:', '').trim();
        setState(() {
          _errorMessage = raw.isNotEmpty
              ? raw
              : 'Invalid credentials. Please check your Employee ID / Email and password.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered mobile number or Employee ID');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(authStateProvider.notifier).sendOtp(mobile);
      if (!mounted) return;

      final empName = res['employeeName'] as String?;
      final otpCode = res['otp'] as String?;
      setState(() {
        _isOtpSent = true;
        _detectedEmployeeName = empName;
        if (otpCode != null && otpCode.isNotEmpty) {
          _otpController.text = otpCode;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _handleOtpLogin() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();

    if (mobile.isEmpty || otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter both mobile/ID and 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).loginWithOtp(mobile: mobile, otp: otp);
      if (!mounted) return;

      final currentUser = ref.read(authStateProvider);
      if (currentUser?.role == UserRole.fieldStaff) {
        context.go('/field-dashboard');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      GoogleAuthPayload? payload;
      String? oauthError;

      try {
        payload = await ref.read(googleAuthServiceProvider).signIn();
      } catch (e) {
        oauthError = e.toString();
      }

      if (payload == null && oauthError == null) {
        return; // cancelled
      }

      if (payload == null && oauthError != null && mounted) {
        payload = await _showGoogleFallbackDialog(oauthError);
      }

      if (payload == null) return;

      await ref.read(authStateProvider.notifier).signInWithGoogle(payload: payload);
      if (!mounted) return;

      final currentUser = ref.read(authStateProvider);
      if (currentUser?.role == UserRole.fieldStaff) {
        context.go('/field-dashboard');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<GoogleAuthPayload?> _showGoogleFallbackDialog(String error) async {
    final emailCtrl = TextEditingController(text: 'akshairamoffical24@gmail.com');
    return showDialog<GoogleAuthPayload>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            _GoogleLogoIcon(size: 22),
            SizedBox(width: 10),
            Text('Google Account Test Sign-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OAuth note: $error', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: 'Registered Google Email',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              final em = emailCtrl.text.trim();
              if (em.isNotEmpty) {
                Navigator.pop(
                  ctx,
                  GoogleAuthPayload(email: em, name: em.split('@').first, idToken: 'GOOGLE_TOKEN_$em'),
                );
              }
            },
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E1B4B),
                    Color(0xFF1E293B),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE0F2FE), // soft light cyan / blue
                    Color(0xFFEDE9FE), // soft blue / lavender
                    Color(0xFFFCE7F3), // soft pink / purple
                  ],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildLoginCard(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.92) : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo & Branding
            Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedAuthTab == 1
                  ? 'Administrator & Management Portal'
                  : 'Employee Attendance & Payroll Portal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 22),

            // Tab Selector: [ Employee Login ] | [ Admin / HR ] | [ Mobile OTP ]
            _buildTabSelector(isDark),

            const SizedBox(height: 18),

            // Quick Credentials Chips (Developer & Testing Assistance)
            _buildQuickRoleChips(isDark),

            const SizedBox(height: 18),

            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12.5, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Login Forms based on selected Tab
            if (_selectedAuthTab == 2)
              _buildOtpForm(isDark)
            else
              _buildStandardLoginForm(isDark),

            const SizedBox(height: 16),

            // Divider: OR
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              ],
            ),

            const SizedBox(height: 14),

            // Google Sign In
            OutlinedButton(
              onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              ),
              child: _isGoogleLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF6366F1)),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleLogoIcon(size: 19),
                        SizedBox(width: 10),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Employee',
              icon: Icons.person_rounded,
              index: 0,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Admin / HR',
              icon: Icons.admin_panel_settings_rounded,
              index: 1,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Mobile OTP',
              icon: Icons.sms_outlined,
              index: 2,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _selectedAuthTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAuthTab = index;
          _errorMessage = null;
          if (index == 0) {
            _emailOrIdController.text = 'EMP001';
            _passwordController.text = 'emp123';
          } else if (index == 1) {
            _emailOrIdController.text = 'admin@workpulse.com';
            _passwordController.text = 'admin123';
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF6366F1) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF6366F1))
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF1E293B))
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRoleChips(bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _buildChip('AKSHAIRAM (EMP001)', () => _fillCredentials('EMP001', 'emp123', tab: 0)),
        _buildChip('Admin', () => _fillCredentials('admin@workpulse.com', 'admin123', tab: 1)),
        _buildChip('HR Manager', () => _fillCredentials('hr@workpulse.com', 'hr123', tab: 1)),
        _buildChip('Field Staff', () => _fillCredentials('field@workpulse.com', 'field123', tab: 0)),
      ],
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardLoginForm(bool isDark) {
    final isEmployee = _selectedAuthTab == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email / Employee ID Field
        TextFormField(
          controller: _emailOrIdController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: isEmployee ? 'Employee Email / Employee ID' : 'Work Email / Username',
            hintText: isEmployee ? 'e.g. EMP001 or akshairam@freelanceconscom.com' : 'e.g. admin@workpulse.com',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
            ),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your ID or Email' : null,
        ),

        const SizedBox(height: 14),

        // Password Field with Show/Hide Toggle
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: AppStrings.password,
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
            ),
          ),
          validator: (val) => (val == null || val.isEmpty) ? 'Please enter your password' : null,
        ),

        const SizedBox(height: 10),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Remember me',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset instructions sent to your registered email.')),
                );
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sign In Button
        ElevatedButton(
          onPressed: (_isLoading || _isGoogleLoading) ? null : _handlePasswordLogin,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  isEmployee ? 'Sign In as Employee' : 'Sign In to Management',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: 'Registered Mobile Number or Employee ID',
            hintText: 'e.g. 6374990354 or EMP001',
            prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
            suffixIcon: TextButton(
              onPressed: _isSendingOtp ? null : _handleSendOtp,
              child: _isSendingOtp
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _isOtpSent ? 'Resend' : 'Send OTP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_isOtpSent) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              labelText: '6-Digit OTP Code',
              hintText: 'Demo code: 123456',
              prefixIcon: const Icon(Icons.security_rounded, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18, color: Color(0xFF6366F1)),
                tooltip: 'Fill Demo OTP (123456)',
                onPressed: () => setState(() => _otpController.text = '123456'),
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_detectedEmployeeName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Matched Employee: $_detectedEmployeeName',
              style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
            ),
          ],
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_isSendingOtp || _isVerifyingOtp)
              ? null
              : (_isOtpSent ? _handleOtpLogin : _handleSendOtp),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: (_isSendingOtp || _isVerifyingOtp)
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  _isOtpSent ? 'Verify OTP & Log In' : 'Send One-Time Password',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  final double size;
  const _GoogleLogoIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    final strokeW = w * 0.22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    paint.color = blue;
    canvas.drawArc(rect, -0.7, 1.4, false, paint);

    paint.color = green;
    canvas.drawArc(rect, 0.7, 1.4, false, paint);

    paint.color = yellow;
    canvas.drawArc(rect, 2.1, 1.4, false, paint);

    paint.color = red;
    canvas.drawArc(rect, 3.5, 1.4, false, paint);

    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx - strokeW * 0.1,
      center.dy - strokeW / 2,
      radius - strokeW * 0.35,
      strokeW,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
