import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/aurora_background.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/user.dart';
import '../data/google_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  int _selectedAuthTab = 0; // 0 = Admin / HR Portal, 1 = Employee Login (OTP)
  final _employeeMobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _isOtpSent = false;
  bool _isVerifyingOtp = false;
  String? _detectedEmployeeName;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _employeeMobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final mobile = _employeeMobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your 10-digit registered mobile number'),
          backgroundColor: AppColors.absent,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OTP sent to $mobile${empName != null ? " ($empName)" : ""}! Demo code: ${otpCode ?? "123456"}',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.present,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isNotEmpty ? err : 'Failed to send OTP. Please check your mobile number.'),
          backgroundColor: AppColors.absent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _handleEmployeeOtpLogin() async {
    final mobile = _employeeMobileController.text.trim();
    final otp = _otpController.text.trim();

    if (mobile.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number and the 6-digit OTP code'),
          backgroundColor: AppColors.absent,
        ),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      await ref.read(authStateProvider.notifier).loginWithOtp(
            mobile: mobile,
            otp: otp,
          );

      if (!mounted) return;

      final currentUser = ref.read(authStateProvider);
      if (currentUser?.role == UserRole.fieldStaff) {
        context.go('/field-dashboard');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $err'),
          backgroundColor: AppColors.absent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).login(
            emailOrId: _emailController.text,
            password: _passwordController.text,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: AppColors.absent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      GoogleAuthPayload? payload;
      String? oauthError;

      try {
        payload = await ref.read(googleAuthServiceProvider).signIn();
      } catch (e) {
        oauthError = e.toString();
        debugPrint('[LoginScreen] Real Google Sign-In exception: $e');
      }

      // If sign-in was cancelled with no payload and no error
      if (payload == null && oauthError == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In was cancelled.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // If there was an OAuth configuration issue (e.g. Origin not allowed, invalid client id, or popup blocked)
      if (payload == null && oauthError != null && mounted) {
        payload = await _showGoogleOAuthTroubleshootDialog(oauthError);
      }

      if (payload == null) {
        return;
      }

      await ref.read(authStateProvider.notifier).signInWithGoogle(payload: payload);

      if (!mounted) return;

      final currentUser = ref.read(authStateProvider);
      if (currentUser?.role == UserRole.fieldStaff) {
        context.go('/field-dashboard');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception:', '').trim();
      final isUnauthorized = errorMessage.toLowerCase().contains('not authorized') ||
          errorMessage.toLowerCase().contains('unauthorized');

      if (isUnauthorized) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.g_mobiledata_rounded, color: AppColors.absent, size: 36),
                SizedBox(width: 8),
                Text('Access Restricted', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'Your Google account is not authorized to access this system. Please contact the administrator.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.absent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.absent.withOpacity(0.25)),
                  ),
                  child: const Text(
                    'Note: Only registered employees and enterprise staff accounts can log in.',
                    style: TextStyle(fontSize: 12, color: AppColors.absent, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.isNotEmpty ? errorMessage : 'Unable to sign in with Google. Please try again.'),
            backgroundColor: AppColors.absent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<GoogleAuthPayload?> _showGoogleOAuthTroubleshootDialog(String error) async {
    final customEmailCtrl = TextEditingController();
    return showDialog<GoogleAuthPayload>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            _GoogleLogoIcon(size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Google OAuth Setup & Fallback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google OAuth popup encountered:\n${error.length > 120 ? "${error.substring(0, 120)}..." : error}',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'To use your official Google Cloud credentials:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  '1. Add your Google OAuth Web Client ID in "lib/core/config/auth_config.dart"\n2. Add Authorized JavaScript origin: "http://localhost:7357" in Google Cloud Console.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const Divider(height: 24),
                const Text(
                  'Or test with registered enterprise accounts in development:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _googleAccountTile(
                  ctx,
                  name: 'Alexander Wright',
                  email: 'admin@workpulse.com',
                  roleTag: 'ADMIN',
                  avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                ),
                _googleAccountTile(
                  ctx,
                  name: 'Sarah Jenkins',
                  email: 'sarah.j@workpulse.io',
                  roleTag: 'HR',
                  avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
                ),
                _googleAccountTile(
                  ctx,
                  name: 'Rajesh Kumar',
                  email: 'rajesh.k@workpulse.io',
                  roleTag: 'FIELD STAFF',
                  avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customEmailCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter your real Google email to test',
                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    final email = customEmailCtrl.text.trim();
                    if (email.isNotEmpty) {
                      Navigator.pop(
                        ctx,
                        GoogleAuthPayload(
                          email: email,
                          name: email.split('@').first,
                          idToken: 'DIRECT_GOOGLE_TOKEN_$email',
                        ),
                      );
                    }
                  },
                  child: const Center(child: Text('Test with this Email')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _googleAccountTile(
    BuildContext ctx, {
    required String name,
    required String email,
    required String roleTag,
    required String avatar,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(avatar),
          radius: 18,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(email, style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            roleTag,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
        onTap: () {
          Navigator.pop(
            ctx,
            GoogleAuthPayload(
              email: email,
              name: name,
              avatarUrl: avatar,
              idToken: 'TOKEN_$email',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: isDesktop
                  ? Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Column: Enterprise Hero Showcase
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 48),
                                child: _buildHeroShowcase(isDark),
                              ),
                            ),
                            // Right Column: Glassmorphic Login Form Card
                            Expanded(
                              flex: 5,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: _buildLoginFormCard(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildLoginFormCard(isDark),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroShowcase(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Next-Gen Workforce & Attendance Platform',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Automated Staff Attendance\n& Payroll Capture System',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.2,
            letterSpacing: -0.8,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Geofenced mobile check-ins, biometric synchronization, multi-format Excel imports, and real-time analytical audit trails in a single unified dashboard.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 28),
        _buildFeatureItem(Icons.gps_fixed_rounded, 'Precision GPS Geofencing', 'Site-aware mobile punch verification with strict radius checks.', isDark),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.fingerprint_rounded, 'Biometric & Hybrid Capture', 'Instant terminal integration with live attendance streams.', isDark),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.assessment_rounded, '15 Exportable Report Categories', 'Instant Excel, CSV, and formatted PDF register downloads.', isDark),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormCard(bool isDark) {
    return GlassmorphicContainer(
      padding: Responsive.cardPadding(context),
      borderRadius: 24,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand Logo & Header
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 34,
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
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.appTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),

            const SizedBox(height: 18),

            // Mode Selector Tabs: [ Admin / HR Portal ] | [ Employee Login (OTP) ]
            _buildLoginModeSelector(isDark),

            const SizedBox(height: 18),

            if (_selectedAuthTab == 0) ...[
              // Quick Role Switcher Pills for Testing
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickRoleChip('Admin', 'admin@workpulse.com', 'admin123'),
                  _buildQuickRoleChip('HR Manager', 'hr@workpulse.com', 'hr123'),
                  _buildQuickRoleChip('Field Staff', 'field@workpulse.com', 'field123'),
                ],
              ),

              const SizedBox(height: 18),

              // Work Email / Emp ID Input
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Work Email ID (Admin / HR Login)',
                  hintText: 'e.g. admin@workpulse.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your Work Email ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password Input
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
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Remember Me & Forgot Password
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.rememberMe,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset instructions sent to your email.')),
                      );
                    },
                    child: const Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Manual Sign In Button
              ElevatedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        AppStrings.signIn,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
              ),

              const SizedBox(height: 16),

              // Divider "OR CONTINUE WITH"
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ],
              ),

              const SizedBox(height: 14),

              // Google Sign In Button
              OutlinedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.12),
                  ),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isGoogleLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Authenticating with Google...',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleLogoIcon(size: 18),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.signInWithGoogle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ] else ...[
              _buildEmployeeLoginForm(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              index: 0,
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin / HR',
              isSelected: _selectedAuthTab == 0,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTab(
              index: 1,
              icon: Icons.person_pin_circle_rounded,
              label: 'Employee (OTP)',
              isSelected: _selectedAuthTab == 1,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAuthTab = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 8,
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
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeLoginForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Employee Info Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Staff & Employee Portal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sign in with your registered phone number to mark attendance and access self-service.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Test Helper Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _buildQuickEmployeeChip('AKSHAIRAM (EMP001)', '6374990354'),
            _buildQuickEmployeeChip('Field Staff (EMP048)', '9876543210'),
          ],
        ),

        const SizedBox(height: 16),

        // Mobile Number Field
        TextFormField(
          controller: _employeeMobileController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Registered Mobile Number',
            hintText: 'e.g. 6374990354',
            prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton(
                onPressed: _isSendingOtp ? null : _handleSendOtp,
                child: _isSendingOtp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isOtpSent ? 'Resend' : 'Send OTP',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
              ),
            ),
          ),
        ),

        if (_isOtpSent) ...[
          const SizedBox(height: 14),

          // OTP Code Field
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              labelText: '6-Digit OTP Code',
              hintText: 'Enter 6-digit OTP (Demo: 123456)',
              prefixIcon: const Icon(Icons.key_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: 'Fill Demo OTP (123456)',
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18, color: AppColors.primary),
                onPressed: () {
                  setState(() => _otpController.text = '123456');
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Matched Employee Badge
          if (_detectedEmployeeName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.present),
                  const SizedBox(width: 4),
                  Text(
                    'Matched Employee: $_detectedEmployeeName',
                    style: const TextStyle(fontSize: 12, color: AppColors.present, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 20),

        // Action Button: Send OTP or Verify & Login
        ElevatedButton(
          onPressed: (_isSendingOtp || _isVerifyingOtp)
              ? null
              : (_isOtpSent ? _handleEmployeeOtpLogin : _handleSendOtp),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: (_isSendingOtp || _isVerifyingOtp)
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOtpSent ? Icons.login_rounded : Icons.sms_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOtpSent ? 'Verify & Login as Employee' : 'Send OTP via Mobile',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // Helper Note
        Center(
          child: Text(
            'In development mode, Demo OTP is 123456.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickEmployeeChip(String label, String mobile) {
    return InkWell(
      onTap: () {
        setState(() {
          _employeeMobileController.text = mobile;
          _otpController.text = '123456';
          _isOtpSent = true;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.present.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.present.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 13, color: AppColors.present),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.present),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRoleChip(String label, String email, String password) {
    return InkWell(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
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

    // Blue arc (Right & top-right)
    paint.color = blue;
    canvas.drawArc(rect, -0.7, 1.4, false, paint);

    // Green arc (Bottom)
    paint.color = green;
    canvas.drawArc(rect, 0.7, 1.4, false, paint);

    // Yellow arc (Left & Bottom-left)
    paint.color = yellow;
    canvas.drawArc(rect, 2.1, 1.4, false, paint);

    // Red arc (Top)
    paint.color = red;
    canvas.drawArc(rect, 3.5, 1.4, false, paint);

    // Center horizontal bar for Google G
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
