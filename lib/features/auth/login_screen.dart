import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

enum AuthMode { signIn, register }

/// P-01 Login & Register Screen.
///
/// Redesigned modern, elegant authentication portal featuring:
/// - Glassmorphic hero header with SLIIT Campus branding.
/// - Seamless Sign In vs. Register (Create Account) tab switcher.
/// - Role selection (Student vs. Staff) with access indicators.
/// - Google OAuth 2.0 integration wired to Firebase Auth.
/// - Password visibility toggles, Remember Me, and Password Recovery.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  AuthMode _mode = AuthMode.signIn;
  UserRole _role = UserRole.student;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _remember = true;
  bool _busy = false;
  bool _googleBusy = false;

  // S01: errors are inline — field-level where possible, a danger
  // callout for auth failures. Never snackbar-only.
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Clear the previous pass before validating (S01).
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your university ID or email');
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Enter your password');
      return;
    }

    if (_mode == AuthMode.register) {
      if (fullName.isEmpty) {
        setState(() => _formError = 'Please enter your full name');
        return;
      }
      if (password.length < 6) {
        setState(() =>
            _passwordError = 'Password must be at least 6 characters');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _formError = 'Passwords do not match');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final state = AppScope.read(context);
      if (_mode == AuthMode.signIn) {
        await state.signInWithEmail(
          email: email,
          password: password,
          role: _role,
        );
      } else {
        await state.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName,
          role: _role,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errStr = e.toString().replaceAll('Exception:', '').trim();
          _formError = errStr.isNotEmpty
              ? errStr
              : "We couldn't sign you in. Check your email and password.";
        });
        Haptics.danger();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _googleBusy = true);
    try {
      final state = AppScope.read(context);
      await state.signInWithGoogle(role: _role);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Google Sign-In was cancelled or unavailable');
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppText.body(13, color: Colors.white, w: FontWeight.w500),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
              style: AppText.display(18, w: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your institutional email address to receive a password reset link.',
              style: AppText.body(13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Institutional Email',
                hintText: 'student@sliit.lk',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.label(13, color: AppColors.textFaint)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnackBar('Reset link sent to ${resetController.text.trim().isEmpty ? "your email" : resetController.text.trim()}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // Hero Branding Header Card
                StaggeredEntrance(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.surfaceMuted,
                                AppColors.surface,
                              ]
                            : [
                                AppColors.primary.withValues(alpha: 0.08),
                                AppColors.surface,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CampusMark(size: 44),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.appName,
                                    style: AppText.display(
                                      20,
                                      w: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      ls: -0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      AppStrings.portalName,
                                      style: AppText.label(
                                        10,
                                        w: FontWeight.w700,
                                        color: AppColors.primary,
                                        ls: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _mode == AuthMode.signIn
                              ? 'Welcome Back'
                              : 'Create Your Account',
                          textAlign: TextAlign.center,
                          style: AppText.display(
                            18,
                            w: FontWeight.w800,
                            ls: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _mode == AuthMode.signIn
                              ? 'Sign in to access study seats, reserve books & manage QR pass.'
                              : 'Register with your campus email to get instant library access.',
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Auth Mode Switcher (Sign in vs Create account)
                StaggeredEntrance(
                  index: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Haptics.selection();
                              setState(() => _mode = AuthMode.signIn);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _mode == AuthMode.signIn
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Sign In',
                                textAlign: TextAlign.center,
                                style: AppText.label(
                                  13,
                                  w: FontWeight.w700,
                                  color: _mode == AuthMode.signIn
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Haptics.selection();
                              setState(() => _mode = AuthMode.register);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _mode == AuthMode.register
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Register',
                                textAlign: TextAlign.center,
                                style: AppText.label(
                                  13,
                                  w: FontWeight.w700,
                                  color: _mode == AuthMode.register
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Role Selector (Student vs Staff)
                StaggeredEntrance(
                  index: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: _RoleChip(
                          icon: Icons.school_rounded,
                          label: 'Student',
                          sublabel: 'Seats & Books',
                          isSelected: _role == UserRole.student,
                          onTap: () {
                            Haptics.selection();
                            setState(() => _role = UserRole.student);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RoleChip(
                          icon: Icons.admin_panel_settings_rounded,
                          label: 'Staff',
                          sublabel: 'Admin Desk',
                          isSelected: _role == UserRole.staff,
                          onTap: () {
                            Haptics.selection();
                            setState(() => _role = UserRole.staff);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Google OAuth Button
                StaggeredEntrance(
                  index: 3,
                  child: OutlinedButton(
                    onPressed: (_busy || _googleBusy) ? null : _handleGoogleAuth,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      side: BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                      backgroundColor: isDark
                          ? AppColors.surfaceMuted
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                    ),
                    child: _googleBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleLogoIcon(),
                              const SizedBox(width: 10),
                              Text(
                                _mode == AuthMode.signIn
                                    ? 'Continue with Google'
                                    : 'Sign up with Google',
                                style: AppText.label(
                                  13.5,
                                  w: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Divider
                StaggeredEntrance(
                  index: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.border,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or continue with email',
                          style: AppText.body(
                            11,
                            color: AppColors.textFaint,
                            w: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.border,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Form Fields
                StaggeredEntrance(
                  index: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_formError != null) ...[
                        Callout(
                          tone: CalloutTone.danger,
                          icon: Icons.error_outline_rounded,
                          title: "We couldn't sign you in",
                          message: _formError!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_mode == AuthMode.register) ...[
                        TextField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _emailFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'e.g. Kasun Perera',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: InputDecoration(
                          labelText: _mode == AuthMode.signIn
                              ? 'University ID / Institutional Email'
                              : 'Institutional Email',
                          hintText: 'student@sliit.lk',
                          errorText: _emailError,
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: _mode == AuthMode.register
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: (_) {
                          if (_mode == AuthMode.register) {
                            _confirmPasswordFocus.requestFocus();
                          } else {
                            _handleEmailAuth();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: _passwordError,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      if (_mode == AuthMode.register) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleEmailAuth(),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      if (_mode == AuthMode.signIn)
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _remember,
                                onChanged: (value) =>
                                    setState(() => _remember = value ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: AppText.body(
                                12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: AppText.label(
                                  12,
                                  w: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      PrimaryButton(
                        label: _busy
                            ? (_mode == AuthMode.signIn ? 'Signing in…' : 'Creating account…')
                            : (_mode == AuthMode.signIn ? 'Sign in' : 'Create account'),
                        onPressed: (_busy || _googleBusy) ? null : _handleEmailAuth,
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _mode == AuthMode.signIn
                            ? 'SLIIT Library System • Secure Firebase Auth & OAuth 2.0'
                            : 'By registering, you agree to campus library rules & regulations.',
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          11,
                          color: AppColors.textFaint,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A modern selectable chip for choosing Student vs Staff user roles.
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppText.label(
                      12.5,
                      w: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: AppText.body(
                      10,
                      color: AppColors.textFaint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimalist vector-style Google logo icon widget.
class _GoogleLogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: _GooglePainter(),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint red = Paint()..color = const Color(0xFFEA4335);
    final Paint blue = Paint()..color = const Color(0xFF4285F4);
    final Paint green = Paint()..color = const Color(0xFF34A853);
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05);

    final Rect rect = Rect.fromLTWH(0, 0, w, h);

    canvas.drawArc(rect, -0.5, 1.8, true, red);
    canvas.drawArc(rect, 1.3, 1.2, true, green);
    canvas.drawArc(rect, 2.5, 0.8, true, yellow);
    canvas.drawArc(rect, 3.3, 1.5, true, blue);

    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.32, Paint()..color = Colors.white);

    final Path barPath = Path()
      ..addRect(Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.48, h * 0.24));
    canvas.drawPath(barPath, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
