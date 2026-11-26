import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/domain/use_cases/auth_validation.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _bankName = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  final _contact = TextEditingController();
  final _license = TextEditingController();
  var _emailMode = true;
  var _obscure = true;
  var _agree = false;
  var _step = 0;
  final _acceptedWaste = <String>{};

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirmation,
      _bankName,
      _address,
      _hours,
      _contact,
      _license,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  UserRole get _role => GoRouterState.of(context).extra is UserRole
      ? GoRouterState.of(context).extra! as UserRole
      : UserRole.pengguna;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_agree) return;
    final role = _role;
    MitraProfile? profile;
    if (role == UserRole.mitra) {
      profile = MitraProfile(
        userId: '',
        name: _bankName.text.trim(),
        address: _address.text.trim(),
        operatingHours: _hours.text.trim(),
        acceptedWasteTypes: _acceptedWaste.toList(),
        contactNumber:
            normalizePhone(_contact.text) ?? normalizePhone(_phone.text) ?? '',
        licenseNumber: _license.text.trim().isEmpty
            ? null
            : _license.text.trim(),
        status: VerificationStatus.menunggu,
      );
    }
    final user = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _name.text,
          email: _emailMode ? _email.text : null,
          phone: _emailMode ? null : _phone.text,
          password: _password.text,
          role: role,
          mitraProfile: profile,
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
    final strength = passwordStrength(_password.text);
    final accountFields = [
      TextFormField(
        key: const Key('register-name'),
        controller: _name,
        decoration: const InputDecoration(
          labelText: 'Nama lengkap',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (value) =>
            (value ?? '').trim().length >= 3 ? null : 'Nama minimal 3 karakter',
      ),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Email')),
          ButtonSegment(value: false, label: Text('Nomor Telepon')),
        ],
        selected: {_emailMode},
        onSelectionChanged: (value) => setState(() => _emailMode = value.first),
      ),
      const SizedBox(height: 12),
      if (_emailMode)
        TextFormField(
          key: const Key('register-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) =>
              isValidEmail(value ?? '') ? null : 'Email tidak valid',
        )
      else
        TextFormField(
          key: const Key('register-phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor telepon',
            prefixText: '+62 ',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) => normalizePhone(value ?? '') == null
              ? 'Nomor telepon tidak valid'
              : null,
        ),
      const SizedBox(height: 12),
      TextFormField(
        key: const Key('register-password'),
        controller: _password,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Kata sandi',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        onChanged: (_) => setState(() {}),
        validator: (value) => isValidPassword(value ?? '')
            ? null
            : 'Minimal 8 karakter, huruf dan angka',
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: strength / 4,
        borderRadius: BorderRadius.circular(8),
      ),
      const SizedBox(height: 12),
      TextFormField(
        key: const Key('register-password-confirmation'),
        controller: _confirmation,
        obscureText: _obscure,
        decoration: const InputDecoration(
          labelText: 'Konfirmasi kata sandi',
          prefixIcon: Icon(Icons.lock_outline),
        ),
        validator: (value) =>
            value == _password.text ? null : 'Konfirmasi kata sandi belum sama',
      ),
      if (role == UserRole.pengguna) ...[
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _agree,
          onChanged: (value) => setState(() => _agree = value ?? false),
          title: const Text('Saya menyetujui syarat dan kebijakan privasi'),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(role == UserRole.mitra ? 'Daftar Mitra' : 'Daftar'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: role == UserRole.mitra
              ? Stepper(
                  key: const Key('mitra-register-stepper'),
                  currentStep: _step,
                  onStepContinue: () {
                    if (_step < 2) {
                      setState(() => _step++);
                    } else {
                      _register();
                    }
                  },
                  onStepCancel: _step == 0
                      ? null
                      : () => setState(() => _step--),
                  controlsBuilder: (context, details) => Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: authState.isLoading
                              ? null
                              : details.onStepContinue,
                          child: Text(
                            _step == 2 ? 'Kirim pendaftaran' : 'Lanjut',
                          ),
                        ),
                        if (_step > 0) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Kembali'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  steps: [
                    Step(
                      title: const Text('Akun'),
                      isActive: _step >= 0,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: accountFields,
                      ),
                    ),
                    Step(
                      title: const Text('Data bank sampah'),
                      isActive: _step >= 1,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('mitra-bank-name'),
                            controller: _bankName,
                            decoration: const InputDecoration(
                              labelText: 'Nama bank sampah',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('mitra-address'),
                            controller: _address,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Alamat lengkap',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hours,
                            decoration: const InputDecoration(
                              labelText: 'Jam operasional',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final waste in const [
                                'Plastik',
                                'Kertas/Kardus',
                                'Kaca',
                                'Logam',
                                'Elektronik kecil',
                              ])
                                FilterChip(
                                  label: Text(waste),
                                  selected: _acceptedWaste.contains(waste),
                                  onSelected: (selected) => setState(
                                    () => selected
                                        ? _acceptedWaste.add(waste)
                                        : _acceptedWaste.remove(waste),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contact,
                            decoration: const InputDecoration(
                              labelText: 'Nomor kontak',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _license,
                            decoration: const InputDecoration(
                              labelText: 'Nomor izin/NIB (opsional)',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Ringkasan'),
                      isActive: _step >= 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Nama: ${_name.text}'),
                          Text('Bank: ${_bankName.text}'),
                          Text('Alamat: ${_address.text}'),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _agree,
                            onChanged: (value) =>
                                setState(() => _agree = value ?? false),
                            title: const Text(
                              'Saya menyetujui syarat dan kebijakan privasi',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const EcoLogo(
                          size: 48,
                          variant: EcoLogoVariant.horizontal,
                        ),
                        const SizedBox(height: 16),
                        if (authState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              authState.error.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ...accountFields,
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('register-submit'),
                          onPressed: authState.isLoading || !_agree
                              ? null
                              : _register,
                          child: authState.isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Daftar'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.login, extra: role),
                          child: const Text('Sudah punya akun? Masuk'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
