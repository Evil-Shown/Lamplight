import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

enum AuthMode { signIn, register }

/// Aurora backdrop with a floating glass sign-in panel.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

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

  void _toggleMode(AuthMode mode) {
    if (_mode == mode) return;
    AppFeedback.select();
    setState(() {
      _mode = mode;
      _formError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

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

    Haptics.tap();
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
    Haptics.tap();
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
          style: AppText.body(13, color: AppColors.textInverse, w: FontWeight.w500),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.base),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        title: Text(
          'Reset password',
          style: AppText.title(18, w: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your campus email and we’ll send a reset link.',
              style: AppText.body(14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Campus email',
                hintText: 'student@sliit.lk',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppText.label(13, color: AppColors.textFaint),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final to = resetController.text.trim().isEmpty
                  ? 'your email'
                  : resetController.text.trim();
              _showSnackBar('Reset link sent to $to');
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }

  InputDecoration _field({
    required String hint,
    required IconData icon,
    String? error,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(AppRadii.lg);
    OutlineInputBorder side(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      errorText: error,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceMuted,
      hintStyle: AppText.body(14, color: AppColors.textFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: side(AppColors.border),
      enabledBorder: side(AppColors.border),
      focusedBorder: side(AppColors.primary, 1.6),
      errorBorder: side(AppColors.error),
      focusedErrorBorder: side(AppColors.error, 1.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signingIn = _mode == AuthMode.signIn;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final dark = AppColors.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AuroraBackground(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.base,
                  AppSpacing.screenMargin,
                  AppSpacing.xl + bottomInset,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthHeader(signingIn: signingIn),
                      const SizedBox(height: AppSpacing.xl),
                      GlassSurface(
                        radius: AppRadii.xl,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            AnimatedSwitcher(
                              duration: AppMotion.fast,
                              switchInCurve: Curves.easeOutCubic,
                              child: Text(
                                signingIn ? 'Sign in' : 'Register',
                                key: ValueKey(signingIn),
                                style: AppText.title(
                                  24,
                                  w: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              signingIn
                                  ? 'Use your campus email to continue.'
                                  : 'Takes less than a minute.',
                              style: AppText.body(13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 18),
                            _RoleRow(
                              role: _role,
                              onChanged: (role) {
                                AppFeedback.select();
                                setState(() => _role = role);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (_formError != null) ...[
                              Callout(
                                tone: CalloutTone.danger,
                                icon: Icons.error_outline_rounded,
                                title: signingIn
                                    ? "We couldn't sign you in"
                                    : "We couldn't create your account",
                                message: _formError!,
                              ),
                              const SizedBox(height: 14),
                            ],
                            AnimatedSize(
                              duration: AppMotion.fast,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: Column(
                                children: [
                                  if (!signingIn) ...[
                                    TextField(
                                      controller: _fullNameController,
                                      style: AppText.body(15, color: AppColors.textPrimary),
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _emailFocus.requestFocus(),
                                      decoration: _field(
                                        hint: 'Full name',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    style: AppText.body(15, color: AppColors.textPrimary),
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: signingIn
                                        ? const [AutofillHints.username]
                                        : const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                    decoration: _field(
                                      hint: 'Email address',
                                      icon: Icons.mail_outline_rounded,
                                      error: _emailError,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    style: AppText.body(15, color: AppColors.textPrimary),
                                    obscureText: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: signingIn
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    onSubmitted: (_) {
                                      if (signingIn) {
                                        _handleEmailAuth();
                                      } else {
                                        _confirmPasswordFocus.requestFocus();
                                      }
                                    },
                                    decoration: _field(
                                      hint: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      error: _passwordError,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!signingIn) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      focusNode: _confirmPasswordFocus,
                                      style: AppText.body(15, color: AppColors.textPrimary),
                                      obscureText: _obscureConfirmPassword,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _handleEmailAuth(),
                                      decoration: _field(
                                        hint: 'Confirm password',
                                        icon: Icons.lock_outline_rounded,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (signingIn) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _remember,
                                      activeColor: AppColors.primary,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide(
                                        color: AppColors.border,
                                        width: 1.4,
                                      ),
                                      onChanged: (value) {
                                        AppFeedback.toggle();
                                        setState(
                                          () => _remember = value ?? false,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      AppFeedback.toggle();
                                      setState(() => _remember = !_remember);
                                    },
                                    child: Text(
                                      'Remember me',
                                      style: AppText.body(13, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Flexible(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Forgot Password?',
                                            style: AppText.label(
                                              13,
                                              w: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                                onPressed: (_busy || _googleBusy)
                                    ? null
                                    : () {
                                        AppFeedback.tap();
                                        _handleEmailAuth();
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textInverse,
                                  disabledBackgroundColor: AppColors.primary
                                      .withValues(alpha: 0.45),
                                  minimumSize: const Size.fromHeight(56),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.lg),
                                  ),
                                ),
                                child: _busy
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.textInverse,
                                        ),
                                      )
                                    : Text(
                                        signingIn
                                            ? 'Sign in'
                                            : 'Create account',
                                        style: AppText.title(
                                          15,
                                          w: FontWeight.w700,
                                          color: AppColors.textInverse,
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'or continue with',
                                    style: AppText.body(12, color: AppColors.textSecondary),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColors.border)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _GoogleSignInRow(
                              busy: _googleBusy,
                              enabled: !_busy && !_googleBusy,
                              onTap: _handleGoogleAuth,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  signingIn
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: AppText.body(13, color: AppColors.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => _toggleMode(
                                    signingIn
                                        ? AuthMode.register
                                        : AuthMode.signIn,
                                  ),
                                  child: Text(
                                    signingIn ? 'Sign up' : 'Sign in',
                                    style: AppText.title(
                                      13,
                                      w: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SLIIT campus library · secure sign-in',
                              textAlign: TextAlign.center,
                              style: AppText.body(11, color: AppColors.textSecondary),
                            ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatefulWidget {
  const _AuthHeader({required this.signingIn});

  final bool signingIn;

  @override
  State<_AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<_AuthHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gentle logo float; stays still when animations are disabled.
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signingIn = widget.signingIn;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _float,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -4 * Curves.easeInOut.transform(_float.value)),
            child: child,
          ),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppGlass.rim, width: 1.2),
              boxShadow: AppShadows.layered(AppColors.primary),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: AppColors.textInverse,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: Curves.easeOutCubic,
          child: Text(
            signingIn
                ? 'Welcome back to Library+'
                : 'Create your Library+ account',
            key: ValueKey(signingIn),
            textAlign: TextAlign.center,
            style: AppText.display(30, w: FontWeight.w800, ls: -0.8, height: 1.12),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Text(
            signingIn
                ? 'Sign in to pick up where you left off.'
                : 'Join with your campus email in a few taps.',
            key: ValueKey('sub-$signingIn'),
            textAlign: TextAlign.center,
            style: AppText.body(14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RolePill(
            label: 'Student',
            icon: Icons.school_rounded,
            selected: role == UserRole.student,
            onTap: () => onChanged(UserRole.student),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RolePill(
            label: 'Staff',
            icon: Icons.badge_rounded,
            selected: role == UserRole.staff,
            onTap: () => onChanged(UserRole.staff),
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.press,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.label(
                13,
                w: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInRow extends StatelessWidget {
  const _GoogleSignInRow({
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: enabled ? onTap : () {},
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const _GoogleLogoIcon(),
                const SizedBox(width: 10),
                Text(
                  'Google',
                  style: AppText.title(
                    14,
                    w: FontWeight.w600,
                    color: AppColors.textPrimary,
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

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    canvas.drawArc(
        rect, -0.5, 1.8, true, Paint()..color = const Color(0xFFEA4335));
    canvas.drawArc(
        rect, 1.3, 1.2, true, Paint()..color = const Color(0xFF34A853));
    canvas.drawArc(
        rect, 2.5, 0.8, true, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawArc(
        rect, 3.3, 1.5, true, Paint()..color = const Color(0xFF4285F4));
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.32,
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.48, h * 0.24),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
