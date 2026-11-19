import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_validation.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/providers/waste_bank_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PickupFormPrefill {
  const PickupFormPrefill({this.wasteType, this.address});

  final PickupWasteType? wasteType;
  final String? address;

  factory PickupFormPrefill.fromScannedType(String specificType) {
    final normalized = specificType.toLowerCase();
    final type = normalized.contains('plastik') || normalized.contains('pet')
        ? PickupWasteType.plastic
        : normalized.contains('kardus') || normalized.contains('kertas')
        ? PickupWasteType.paperCardboard
        : normalized.contains('kaca')
        ? PickupWasteType.glass
        : normalized.contains('logam') || normalized.contains('kaleng')
        ? PickupWasteType.metal
        : normalized.contains('elektronik') || normalized.contains('baterai')
        ? PickupWasteType.smallElectronics
        : null;
    return PickupFormPrefill(wasteType: type);
  }
}

class PickupOrderFormPage extends ConsumerStatefulWidget {
  const PickupOrderFormPage({this.prefill, super.key});

  final PickupFormPrefill? prefill;

  @override
  ConsumerState<PickupOrderFormPage> createState() =>
      _PickupOrderFormPageState();
}

class _PickupOrderFormPageState extends ConsumerState<PickupOrderFormPage> {
  static const _timeSlots = [
    '08.00-10.00',
    '10.00-12.00',
    '13.00-15.00',
    '15.00-17.00',
  ];

  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final Map<PickupWasteType, TextEditingController> _weightControllers = {
    for (final type in PickupWasteType.values) type: TextEditingController(),
  };
  final Set<PickupWasteType> _selectedWasteTypes = {};
  final Map<PickupWasteType, double> _weights = {};
  int _currentStep = 0;
  DateTime? _pickupDate;
  String? _selectedTimeSlot;
  String? _wasteError;
  String? _addressError;
  String? _dateError;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill?.address case final address?) {
      _addressController.text = address;
    }
    if (prefill?.wasteType case final type?) {
      _selectedWasteTypes.add(type);
      _weights[type] = 3;
      _weightControllers[type]!.text = '3';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalWeight =>
      _weights.values.fold(0, (total, weight) => total + weight);

  int get _estimatedPoints => estimatePickupPoints(_totalWeight);

  void _updateWeight(PickupWasteType type, String value) {
    final weight = double.tryParse(value);
    setState(() {
      if (weight == null || weight <= 0) {
        _weights.remove(type);
      } else {
        _weights[type] = weight;
      }
      _wasteError = null;
    });
  }

  bool _validateStep(int step) {
    setState(() {
      _wasteError = null;
      _addressError = null;
      _dateError = null;
    });
    if (step == 0) {
      final error = PickupValidation.validateWasteWeights(_weights);
      setState(() => _wasteError = error);
      return error == null;
    }
    if (step == 1) {
      final error = PickupValidation.validateAddress(_addressController.text);
      setState(() => _addressError = error);
      return error == null;
    }
    if (step == 2) {
      final error = PickupValidation.validatePickupDate(_pickupDate);
      setState(() => _dateError = error);
      if (error != null || _selectedTimeSlot == null) {
        if (error == null) {
          setState(() => _dateError = 'Pilih slot waktu penjemputan.');
        }
        return false;
      }
    }
    return true;
  }

  void _continue() {
    if (_isSubmitting) {
      return;
    }
    if (!_validateStep(_currentStep)) {
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitOrder();
    }
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting ||
        !_validateStep(0) ||
        !_validateStep(1) ||
        !_validateStep(2)) {
      return;
    }
    setState(() => _isSubmitting = true);

    final scheduledDate = _pickupDate!;
    final pickupAt = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      _startHour(_selectedTimeSlot!),
    );
    final order = PickupOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      wasteWeightsKg: Map<PickupWasteType, double>.of(_weights),
      address: _addressController.text.trim(),
      courierNote: _noteController.text.trim(),
      pickupAt: pickupAt,
      timeSlot: _selectedTimeSlot!,
      createdAt: DateTime.now(),
      status: PickupOrderStatus.waitingConfirmation,
    );

    try {
      final warning = await ref
          .read(pickupOrderControllerProvider.notifier)
          .createOrder(order);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      context.go(AppRoutes.pickup);
      if (warning != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          messenger.showSnackBar(SnackBar(content: Text(warning)));
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan gagal disimpan: $error')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  int _startHour(String slot) => int.parse(slot.substring(0, 2));

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? firstDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 90)),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih tanggal penjemputan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected != null && mounted) {
      setState(() {
        _pickupDate = selected;
        _dateError = null;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      if (!mounted) {
        return;
      }
      _addressController.text =
          'Titik GPS: ${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)}';
      setState(() => _addressError = null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lokasi saat ini gagal diambil: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwalkan Penjemputan'),
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Stepper(
        key: const Key('pickup-order-stepper'),
        currentStep: _currentStep,
        onStepTapped: (step) {
          if (step <= _currentStep || _validateStep(_currentStep)) {
            setState(() => _currentStep = step);
          }
        },
        onStepContinue: _continue,
        onStepCancel: _currentStep == 0
            ? null
            : () => setState(() => _currentStep--),
        controlsBuilder: (context, details) {
          if (!details.isActive) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: Key(
                    details.stepIndex == 3
                        ? 'pickup-submit-order'
                        : 'pickup-step-next-${details.stepIndex}',
                  ),
                  onPressed: _isSubmitting ? null : details.onStepContinue,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          details.stepIndex == 3 ? 'Buat pesanan' : 'Lanjut',
                        ),
                ),
                if (details.stepIndex > 0) ...[
                  TextButton(
                    onPressed: _isSubmitting ? null : details.onStepCancel,
                    child: const Text('Kembali'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Jenis & berat sampah'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildWasteStep(context),
          ),
          Step(
            title: const Text('Alamat penjemputan'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildAddressStep(context),
          ),
          Step(
            title: const Text('Tanggal & waktu'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildScheduleStep(context),
          ),
          Step(
            title: const Text('Ringkasan'),
            isActive: _currentStep >= 3,
            state: StepState.indexed,
            content: _buildSummary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih semua jenis yang akan disiapkan. Minimal total 3 kg.',
        ),
        const SizedBox(height: 8),
        for (final type in PickupWasteType.values)
          CheckboxListTile(
            key: Key('pickup-waste-${type.name}'),
            contentPadding: EdgeInsets.zero,
            value: _selectedWasteTypes.contains(type),
            title: Text(type.label),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedWasteTypes.add(type);
                  _weightControllers[type]!.text = '';
                  _weights.remove(type);
                } else {
                  _selectedWasteTypes.remove(type);
                  _weightControllers[type]!.clear();
                  _weights.remove(type);
                }
                _wasteError = null;
              });
            },
            secondary: _selectedWasteTypes.contains(type)
                ? SizedBox(
                    width: 105,
                    child: TextField(
                      key: Key('pickup-weight-${type.name}'),
                      controller: _weightControllers[type],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        suffixText: 'kg',
                        hintText: '0',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _updateWeight(type, value),
                    ),
                  )
                : null,
          ),
        Text(
          'Total: ${_totalWeight.toStringAsFixed(1)} kg',
          key: const Key('pickup-total-weight'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_wasteError != null) _ValidationMessage(message: _wasteError!),
      ],
    );
  }

  Widget _buildAddressStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('pickup-address'),
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Alamat lengkap',
            hintText: 'Nama jalan, nomor rumah, RT/RW, patokan',
            border: const OutlineInputBorder(),
            errorText: _addressError,
          ),
          onChanged: (_) {
            if (_addressError != null) {
              setState(() => _addressError = null);
            }
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('pickup-use-current-location'),
            onPressed: _isLoadingLocation ? null : _useCurrentLocation,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Gunakan lokasi saat ini'),
          ),
        ),
        TextField(
          key: const Key('pickup-courier-note'),
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Catatan untuk kurir (opsional)',
            hintText: 'Contoh: hubungi saat tiba',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep(BuildContext context) {
    final dateText = _pickupDate == null
        ? 'Pilih tanggal'
        : MaterialLocalizations.of(context).formatMediumDate(_pickupDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: const Key('pickup-select-date'),
          onPressed: _selectDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(dateText),
        ),
        if (_dateError != null) _ValidationMessage(message: _dateError!),
        const SizedBox(height: 12),
        Text('Slot waktu', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final slot in _timeSlots)
              ChoiceChip(
                key: Key('pickup-slot-${slot.substring(0, 2)}'),
                label: Text(slot),
                selected: _selectedTimeSlot == slot,
                onSelected: (selected) {
                  setState(() {
                    _selectedTimeSlot = selected ? slot : null;
                    _dateError = null;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final dateText = _pickupDate == null
        ? '-'
        : MaterialLocalizations.of(context).formatMediumDate(_pickupDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _weights.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.key.label),
            trailing: Text('${entry.value.toStringAsFixed(1)} kg'),
          ),
        const Divider(),
        _SummaryRow(
          label: 'Total berat',
          value: '${_totalWeight.toStringAsFixed(1)} kg',
        ),
        _SummaryRow(label: 'Alamat', value: _addressController.text),
        _SummaryRow(label: 'Tanggal', value: dateText),
        _SummaryRow(label: 'Waktu', value: _selectedTimeSlot ?? '-'),
        if (_noteController.text.trim().isNotEmpty)
          _SummaryRow(label: 'Catatan kurir', value: _noteController.text),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.eco_outlined),
            title: const Text('Estimasi poin'),
            subtitle: const Text('Poin diberikan setelah pesanan selesai.'),
            trailing: Text(
              '$_estimatedPoints',
              key: const Key('pickup-estimated-points'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
