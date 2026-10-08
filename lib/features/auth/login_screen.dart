import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

/// P-01 Login–Register.
///
/// A Material 3 sign-in: the campus mark and a display-size headline on
/// the tonal surface, filled rounded fields, stadium buttons, and a
/// tonal switcher for the alternate sign-in paths. The bottom of the
/// screen doubles as the staff entry point, which is what makes the
/// prototype's two navigation bars reachable.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  UserRole _role = UserRole.student;
  bool _obscure = true;
  bool _remember = true;
  bool _busy = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_identifierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter your university email to continue')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await AppScope.read(context).signIn(
            identifier: _identifierController.text.trim(),
            role: _role,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email or password is incorrect — try again')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleHelper = _role == UserRole.staff
        ? 'Staff access is verified against your librarian account.'
        : 'Access seats, books, and your QR pass.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            Column(
              children: [
                const CampusMark(size: 68),
                const SizedBox(height: 24),
                StaggeredEntrance(
                  index: 1,
                  child: Text(
                    'Reserve books and study seats.',
                    textAlign: TextAlign.center,
                    style: AppText.display(
                      28,
                      w: FontWeight.w800,
                      ls: -0.7,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                StaggeredEntrance(
                  index: 2,
                  child: Text(
                    AppStrings.portalName,
                    textAlign: TextAlign.center,
                    style: AppText.label(
                      13,
                      w: FontWeight.w700,
                      ls: 1.6,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            StaggeredEntrance(
              index: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // "Sign in as" — the role is chosen here, inside the
                  // form, with an honest note about how staff access is
                  // verified (D-01).
                  Semantics(
                    label: 'Sign in as',
                    child: SegmentedTabs(
                      options: const ['Student', 'Staff'],
                      selected: _role == UserRole.staff
                          ? 'Staff'
                          : 'Student',
                      onSelected: (value) {
                        Haptics.selection();
                        setState(() => _role = value == 'Staff'
                            ? UserRole.staff
                            : UserRole.student);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleHelper,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'University ID / Institutional Email',
                      hintText: '2023-CS-084',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password / PIN',
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Remember me',
                          style: AppText.body(
                            13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Contact the library desk to reset your password'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot?',
                          style: AppText.label(
                            12.5,
                            w: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: _busy ? 'Signing in…' : 'Sign in',
                    onPressed: _busy ? null : _signIn,
                  ),
                  const SizedBox(height: 12),
                  // Honest auto-provision note — there is no register
                  // screen by design, so say so (D-12).
                  Text(
                    'First time? Your account is created automatically.',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      12.5,
                      color: AppColors.textFaint,
                    ),
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
