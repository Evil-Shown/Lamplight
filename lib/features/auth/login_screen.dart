import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_route.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/firebase/auth_failure.dart';
import '../../models/models.dart';
import '../help/legal_screens.dart';
import 'auth_style.dart';
import 'library_scenes.dart';

enum AuthMode { signIn, register }

/// Sign-in / register sheet over a bookshelf hero. Normally shown at the end
/// of [AuthFlow]; [onBack] adds the back arrow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialMode = AuthMode.signIn,
    this.onBack,
  });

  final AuthMode initialMode;
  final VoidCallback? onBack;

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

  late AuthMode _mode = widget.initialMode;
  UserRole _role = UserRole.student;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _consent = false;
  bool _busy = false;
  bool _googleBusy = false;

  String? _emailError;
  String? _passwordError;
  String? _formError;
  String? _consentError;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => AppRoute.push(context, const TermsScreen());
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => AppRoute.push(context, const PrivacyScreen());

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
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
      _consentError = null;
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
      _consentError = null;
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
      if (!_consent) {
        setState(() => _consentError =
            'Please accept the Terms and Privacy notice to continue');
        return;
      }
    }

    Haptics.tap();
    setState(() => _busy = true);
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
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
      _announceRole(state, messenger);
    } on AuthFailure catch (f) {
      if (mounted) _showFailure(f);
    } catch (_) {
      if (mounted) {
        setState(() => _formError = "We couldn't sign you in. Please try "
            'again.');
        Haptics.danger();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Puts an AuthFailure next to the field it concerns, or in the form-level
  /// callout when it is not about one field.
  void _showFailure(AuthFailure f) {
    Haptics.danger();
    FocusNode? focus;
    setState(() {
      switch (f.code) {
        case 'wrong-password':
        case 'weak-password':
          _passwordError = f.message;
          focus = _passwordFocus;
        case 'invalid-email':
        case 'email-in-use':
          _emailError = f.message;
          focus = _emailFocus;
        default:
          _formError = f.message;
      }
    });
    focus?.requestFocus();
  }

  /// Staff access comes from the server. If the user asked for staff but did
  /// not get it, say so plainly; the message outlives this screen.
  void _announceRole(AppState state, ScaffoldMessengerState messenger) {
    final notice = state.roleNotice;
    if (notice != null) {
      messenger.showSnackBar(SnackBar(content: Text(notice)));
    } else if (_role == UserRole.staff && state.role != UserRole.staff) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Signed in as a student. This account is not on the '
            'library staff list.'),
      ));
    }
  }

  Future<void> _handleGoogleAuth() async {
    Haptics.tap();
    setState(() {
      _googleBusy = true;
      _formError = null;
    });
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.signInWithGoogle(role: _role);
      _announceRole(state, messenger);
    } on AuthFailure catch (f) {
      if (mounted) {
        if (f.isCancelled) {
          _showSnackBar('Google sign-in was cancelled');
        } else {
          _showFailure(f);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Google sign-in is unavailable right now.');
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

  Future<void> _showForgotPasswordDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _emailController.text),
    );
    if (email == null || !mounted) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showSnackBar('If an account exists for $email, a reset link is on '
            'its way.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showSnackBar(AuthFailure.fromAuth(e).message);
    } catch (_) {
      if (mounted) {
        _showSnackBar("Couldn't send a reset link right now. Try again later.");
      }
    }
  }

  InputDecoration _field({
    required String hint,
    String? error,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(AppRadii.md);
    OutlineInputBorder side([Color color = Colors.transparent, double w = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: w),
        );

    return InputDecoration(
      hintText: hint,
      errorText: error,
      errorStyle: AppText.body(12, color: AuthPalette.error),
      suffixIcon: suffix,
      filled: true,
      fillColor: AuthPalette.field,
      hintStyle: AppText.body(14, color: AuthPalette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      border: side(),
      enabledBorder: side(),
      focusedBorder: side(AuthPalette.blue, 1.5),
      errorBorder: side(AuthPalette.error),
      focusedErrorBorder: side(AuthPalette.error, 1.5),
    );
  }

  TextStyle get _input => AppText.body(14.5, color: AuthPalette.ink);

  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              label,
              style: AppText.label(
                12.5,
                w: FontWeight.w700,
                color: AuthPalette.ink,
              ),
            ),
          ),
          field,
        ],
      );

  Widget _visibilityToggle(bool obscured, VoidCallback onTap) => IconButton(
        tooltip: obscured ? 'Show password' : 'Hide password',
        icon: Icon(
          obscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
          color: AuthPalette.muted,
        ),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final signingIn = _mode == AuthMode.signIn;
    final media = MediaQuery.of(context);
    final keyboardUp = media.viewInsets.bottom > 0;
    final heroH = keyboardUp
        ? 96.0
        : (media.size.height * 0.27).clamp(150.0, 260.0).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AuthPalette.navy,
        body: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 320,
              child: ShelfScene(),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                AnimatedContainer(
                  duration: AppMotion.base,
                  curve: Curves.easeOutCubic,
                  height: heroH,
                ),
                Expanded(child: _buildSheet(signingIn)),
              ],
            ),
            if (widget.onBack != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: widget.onBack,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(bool signingIn) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(24, 46, 24, 20 + bottomSafe),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(child: _buildForm(signingIn)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          top: -24,
          left: 0,
          right: 0,
          child: Center(child: LibraryWordmark()),
        ),
      ],
    );
  }

  Widget _buildForm(bool signingIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Text(
            signingIn ? 'Welcome Back!' : 'Join Library+',
            key: ValueKey(signingIn),
            textAlign: TextAlign.center,
            style: AppText.title(19, w: FontWeight.w800, color: AuthPalette.ink),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          signingIn
              ? 'Log in to reserve books, book your reading-room seat, and '
                  'pick up where you left off.'
              : 'Create your account to borrow books and book study seats '
                  'in a few taps.',
          textAlign: TextAlign.center,
          style: AppText.body(12.5, color: AuthPalette.muted),
        ),
        const SizedBox(height: 20),
        _RoleRow(
          role: _role,
          onChanged: (role) {
            AppFeedback.select();
            setState(() => _role = role);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Just a hint. Staff access is granted by the library, not chosen '
          'here.',
          textAlign: TextAlign.center,
          style: AppText.body(11, color: AuthPalette.muted),
        ),
        const SizedBox(height: 18),
        if (_formError != null) ...[
          _ErrorNote(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!signingIn) ...[
                _labeled(
                  'Full name',
                  TextField(
                    controller: _fullNameController,
                    style: _input,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                    decoration: _field(hint: 'Your full name'),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _labeled(
                signingIn ? 'Email' : 'University email',
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  style: _input,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: signingIn
                      ? const [AutofillHints.username]
                      : const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  decoration: _field(
                    hint: 'you@university.edu',
                    error: _emailError,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _labeled(
                'Password',
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  style: _input,
                  obscureText: _obscurePassword,
                  autofillHints: [
                    signingIn
                        ? AutofillHints.password
                        : AutofillHints.newPassword,
                  ],
                  textInputAction:
                      signingIn ? TextInputAction.done : TextInputAction.next,
                  onSubmitted: (_) {
                    if (signingIn) {
                      _handleEmailAuth();
                    } else {
                      _confirmPasswordFocus.requestFocus();
                    }
                  },
                  decoration: _field(
                    hint: signingIn ? 'Your password' : 'At least 6 characters',
                    error: _passwordError,
                    suffix: _visibilityToggle(
                      _obscurePassword,
                      () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              if (!signingIn) ...[
                const SizedBox(height: 14),
                _labeled(
                  'Confirm password',
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    style: _input,
                    obscureText: _obscureConfirmPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleEmailAuth(),
                    decoration: _field(
                      hint: 'Repeat your password',
                      suffix: _visibilityToggle(
                        _obscureConfirmPassword,
                        () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (signingIn)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                foregroundColor: AuthPalette.blue,
              ),
              child: Text(
                'Forgot Password?',
                style: AppText.label(
                  12.5,
                  w: FontWeight.w600,
                  color: AuthPalette.blue,
                ),
              ),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          _ConsentRow(
            value: _consent,
            error: _consentError,
            termsTap: _termsTap,
            privacyTap: _privacyTap,
            onChanged: (v) => setState(() {
              _consent = v;
              _consentError = null;
            }),
          ),
        ],
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AuthPalette.blue.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: (_busy || _googleBusy)
                ? null
                : () {
                    AppFeedback.tap();
                    _handleEmailAuth();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AuthPalette.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AuthPalette.blue.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    signingIn ? 'Sign in' : 'Create account',
                    style: AppText.title(
                      15,
                      w: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 22),
        _GoogleButton(
          busy: _googleBusy,
          enabled: !_busy && !_googleBusy,
          label: signingIn ? 'Login with Google' : 'Sign up with Google',
          onTap: _handleGoogleAuth,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              signingIn
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: AppText.body(12.5, color: AuthPalette.muted),
            ),
            InkWell(
              onTap: () => _toggleMode(
                signingIn ? AuthMode.register : AuthMode.signIn,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    signingIn ? 'Register here' : 'Sign in',
                    style: AppText.title(
                      12.5,
                      w: FontWeight.w700,
                      color: AuthPalette.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AuthPalette.errorSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 20, color: AuthPalette.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.title(
                        13,
                        w: FontWeight.w700,
                        color: AuthPalette.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppText.body(12.5, color: AuthPalette.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            label: "I'm a student",
            icon: Icons.school_rounded,
            selected: role == UserRole.student,
            onTap: () => onChanged(UserRole.student),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RolePill(
            label: "I'm staff",
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
    final tone = selected ? AuthPalette.blue : AuthPalette.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.press,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AuthPalette.blue.withValues(alpha: 0.12)
                : AuthPalette.field,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AuthPalette.blue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: tone),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppText.label(13, w: FontWeight.w600, color: tone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.busy,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool busy;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuthPalette.field,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthPalette.blue,
                    ),
                  )
                else
                  const GoogleMark(),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.title(
                      14,
                      w: FontWeight.w600,
                      color: AuthPalette.ink,
                    ),
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

/// Required terms/privacy consent shown on sign-up.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.termsTap,
    required this.privacyTap,
    this.error,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final GestureRecognizer termsTap;
  final GestureRecognizer privacyTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final base = AppText.body(12.5, color: AuthPalette.muted);
    final link =
        AppText.label(12.5, w: FontWeight.w600, color: AuthPalette.blue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              label: 'Accept Terms and Privacy notice',
              child: Checkbox(
                value: value,
                activeColor: AuthPalette.blue,
                checkColor: Colors.white,
                side: const BorderSide(color: AuthPalette.muted, width: 1.5),
                onChanged: (v) {
                  AppFeedback.toggle();
                  onChanged(v ?? false);
                },
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Terms', style: link, recognizer: termsTap),
                    const TextSpan(text: ' and '),
                    TextSpan(
                        text: 'Privacy notice',
                        style: link,
                        recognizer: privacyTap),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(error!,
                style: AppText.body(12, color: AuthPalette.error)),
          ),
      ],
    );
  }
}

/// Asks for the email to send a reset link to; pops it, or null on cancel.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final _controller = TextEditingController(text: widget.initialEmail);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _controller.text.trim();
    if (!v.contains('@') || v.startsWith('@') || v.endsWith('@')) {
      setState(() => _error = 'Enter the email you signed up with');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text('Reset password', style: AppText.title(18, w: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email and we will send a reset link.',
              style: AppText.body(14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _error,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Send link')),
      ],
    );
  }
}
