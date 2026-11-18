import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/services/waste_bank_distance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WasteBankListPanel extends StatefulWidget {
  const WasteBankListPanel({
    required this.banks,
    required this.center,
    required this.onBankSelected,
    this.scrollController,
    super.key,
  });

  final List<WasteBank> banks;
  final GeoPoint center;
  final ValueChanged<WasteBank> onBankSelected;
  final ScrollController? scrollController;

  @override
  State<WasteBankListPanel> createState() => _WasteBankListPanelState();
}

class _WasteBankListPanelState extends State<WasteBankListPanel> {
  static const _wasteTypes = [
    'Semua',
    'Plastik',
    'Kertas',
    'Kardus',
    'Kaca',
    'Logam',
    'Elektronik',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedWasteType = 'Semua';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleBanks = filterAndSortWasteBanks(
      banks: widget.banks,
      center: widget.center,
      query: _query,
      wasteType: _selectedWasteType,
    );

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Peta Bank Sampah Terdekat',
                  key: const Key('waste-bank-list-title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${visibleBanks.length} lokasi · diurutkan dari yang terdekat',
                  key: const Key('waste-bank-result-count'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('waste-bank-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Cari nama bank sampah',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedWasteType),
                  initialValue: _selectedWasteType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis sampah diterima',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final wasteType in _wasteTypes)
                      DropdownMenuItem(
                        value: wasteType,
                        child: Text(wasteType),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedWasteType = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (visibleBanks.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Tidak ada bank sampah yang cocok. Coba ubah pencarian atau filter.',
                    key: Key('waste-bank-empty'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverList.builder(
              itemCount: visibleBanks.length,
              itemBuilder: (context, index) {
                final bank = visibleBanks[index];
                final distance = distanceBetweenMeters(
                  widget.center,
                  bank.location,
                );
                return _WasteBankListTile(
                  bank: bank,
                  distanceLabel: _formatDistance(distance),
                  onTap: () => widget.onBankSelected(bank),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _WasteBankListTile extends StatelessWidget {
  const _WasteBankListTile({
    required this.bank,
    required this.distanceLabel,
    required this.onTap,
  });

  final WasteBank bank;
  final String distanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        key: Key('waste-bank-${bank.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.recycling_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bank.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: -8,
                      children: [
                        for (final type in bank.acceptedWasteTypes.take(3))
                          Chip(
                            label: Text(type),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.star, color: colorScheme.tertiary, size: 18),
                  Text(bank.rating.toStringAsFixed(1)),
                  const SizedBox(height: 5),
                  Text(
                    distanceLabel,
                    key: Key('waste-bank-distance-${bank.id}'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${NumberFormat('0.0', 'id_ID').format(meters / 1000)} km';
}
