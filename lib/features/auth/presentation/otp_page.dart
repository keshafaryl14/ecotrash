import 'dart:async';

import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({
    required this.destination,
    required this.onVerified,
    this.initialCode,
    super.key,
  });

  final String destination;
  final String? initialCode;
  final Future<bool> Function(String code) onVerified;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  var _seconds = 60;
  var _resends = 0;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) _seconds--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  Future<void> _verify() async {
    if (_code.length != 6 || _busy) return;
    setState(() => _busy = true);
    final verified = await widget.onVerified(_code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP salah atau kedaluwarsa.')),
      );
    }
  }

  void _resend() {
    if (_seconds > 0 || _resends >= 3) return;
    setState(() {
      _resends++;
      _seconds = 60;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verifikasi OTP')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const EcoLogo(size: 48, variant: EcoLogoVariant.horizontal),
            const SizedBox(height: 24),
            Text(
              'Masukkan 6 digit kode',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kode dikirim ke ${widget.destination}',
              textAlign: TextAlign.center,
            ),
            if (widget.initialCode != null &&
                const bool.fromEnvironment('dart.vm.product') == false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'MODE DEMO: ${widget.initialCode}',
                  key: const Key('otp-demo-code'),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            const SizedBox(height: 24),
            AutofillGroup(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      key: Key('otp-$index'),
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (_code.length == 6) _verify();
                      },
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            if (_seconds > 0)
              Text('Kirim ulang dalam $_seconds detik')
            else
              TextButton(
                onPressed: _resends >= 3 ? null : _resend,
                child: const Text('Kirim ulang kode'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _code.length == 6 && !_busy ? _verify : null,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    ),
  );
}
