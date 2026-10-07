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

  /// [requireIdentifier] is only set for the email/password path — the
  /// smartcard and SSO buttons have no identifier to check.
  Future<void> _signIn(
    UserRole role, {
    bool requireIdentifier = false,
  }) async {
    if (requireIdentifier && _identifierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter your university email to continue')),
      );
      return;
    }

    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    AppScope.read(context).signIn(
      identifier: _identifierController.text.trim(),
      role: role,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
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
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        _signIn(UserRole.student, requireIdentifier: true),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: AppText.label(
                          12.5,
                          w: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    value: _remember,
                    onChanged: (value) =>
                        setState(() => _remember = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: Text(
                      'Keep signed in on campus Wi-Fi & scan room',
                      style: AppText.body(
                        13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: _busy ? 'Signing in…' : 'Sign in to Portal',
                    onPressed: _busy
                        ? null
                        : () => _signIn(UserRole.student,
                            requireIdentifier: true),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Sign in with Student Smartcard / Face ID',
                    icon: Icons.contactless_rounded,
                    tone: ButtonTone.secondary,
                    onPressed: _busy ? null : () => _signIn(UserRole.student),
                  ),
                  const SizedBox(height: 22),
                  const _DividerLabel('OR INSTITUTIONAL SSO'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'University Single Sign-On',
                    icon: Icons.shield_outlined,
                    tone: ButtonTone.neutral,
                    onPressed: _busy ? null : () => _signIn(UserRole.student),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : () => _signIn(UserRole.staff),
                      child: Text(
                        'Library staff sign-in',
                        style: AppText.label(
                          13,
                          w: FontWeight.w600,
                          color: AppColors.textFaint,
                        ),
                      ),
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: AppText.overline(10.5, color: AppColors.textFaint),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
