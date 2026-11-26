import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/domain/use_cases/auth_validation.dart';
import 'package:ecotrash/features/auth/presentation/otp_page.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  var _emailMode = true;
  var _otpMode = false;
  var _obscurePassword = true;
  var _remember = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  UserRole get _role => (GoRouterState.of(context).extra is UserRole)
      ? GoRouterState.of(context).extra! as UserRole
      : UserRole.pengguna;

  Future<void> _sendOtp() async {
    final phone = normalizePhone(_phoneController.text);
    if (phone == null) return;
    final code = await ref
        .read(otpServiceProvider)
        .sendCode(destination: phone);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpPage(
          destination: phone,
          initialCode: code,
          onVerified: (otp) async {
            final service = ref.read(otpServiceProvider);
            if (!await service.verifyCode(destination: phone, code: otp)) {
              return false;
            }
            final user = await ref
                .read(authControllerProvider.notifier)
                .signInWithOtp(phone: phone, role: _role, remember: _remember);
            if (user != null && mounted) {
              if (mounted) Navigator.of(context).pop();
              context.go(
                _role == UserRole.mitra
                    ? AppRoutes.mitraDashboard
                    : AppRoutes.home,
              );
            }
            return user != null;
          },
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final role = _role;
    final user = _emailMode
        ? await ref
              .read(authControllerProvider.notifier)
              .signIn(
                email: _emailController.text,
                password: _passwordController.text,
                role: role,
                remember: _remember,
              )
        : await ref
              .read(authControllerProvider.notifier)
              .signIn(
                phone: _phoneController.text,
                password: _passwordController.text,
                role: role,
                remember: _remember,
              );
    if (user != null && mounted) {
      context.go(
        role == UserRole.mitra ? AppRoutes.mitraDashboard : AppRoutes.home,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final roleTitle = role == UserRole.mitra
        ? 'Masuk sebagai Mitra'
        : 'Masuk sebagai Pengguna';

    return Scaffold(
      key: const Key('auth-login-page'),
      appBar: AppBar(
        title: const EcoLogo(size: 28, variant: EcoLogoVariant.horizontal),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        roleTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        key: const Key('login-method'),
                        segments: const [
                          ButtonSegment(value: true, label: Text('Email')),
                          ButtonSegment(value: false, label: Text('Nomor')),
                        ],
                        selected: {_emailMode},
                        onSelectionChanged: (value) =>
                            setState(() => _emailMode = value.first),
                      ),
                      const SizedBox(height: 16),
                      if (authState.hasError)
                        Padding(
                          key: const Key('auth-error'),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            authState.error.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_emailMode)
                        TextFormField(
                          key: const Key('login-email'),
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) => isValidEmail(value ?? '')
                              ? null
                              : 'Email tidak valid',
                        )
                      else
                        Column(
                          children: [
                            TextFormField(
                              key: const Key('login-phone'),
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor telepon',
                                prefixText: '+62 ',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              validator: (value) =>
                                  normalizePhone(value ?? '') == null
                                  ? 'Nomor telepon tidak valid'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Kata sandi'),
                                ),
                                ButtonSegment(value: true, label: Text('OTP')),
                              ],
                              selected: {_otpMode},
                              onSelectionChanged: (value) =>
                                  setState(() => _otpMode = value.first),
                            ),
                          ],
                        ),
                      if (!_otpMode || _emailMode) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login-password'),
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) => (value ?? '').isEmpty
                              ? 'Kata sandi wajib diisi'
                              : null,
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _remember,
                          onChanged: (value) =>
                              setState(() => _remember = value ?? true),
                          title: const Text('Ingat saya'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Atur ulang kata sandi'),
                                content: const Text(
                                  'Jika akun terdaftar, kode pemulihan akan dikirim '
                                  'ke email atau nomor terdaftar.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tutup'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key('login-submit'),
                        onPressed: isLoading
                            ? null
                            : _otpMode
                            ? _sendOtp
                            : _signIn,
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_otpMode ? 'Kirim kode OTP' : 'Masuk'),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.register, extra: role),
                        child: const Text('Belum punya akun? Daftar'),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.roleSelection),
                        child: const Text('Bukan peran ini?'),
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
