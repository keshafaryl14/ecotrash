import 'package:ecotrash/core/animations/earth_globe.dart';
import 'package:ecotrash/core/animations/falling_leaves.dart';
import 'package:ecotrash/core/animations/growing_plant.dart';
import 'package:ecotrash/core/animations/points_burst.dart';
import 'package:ecotrash/core/animations/recycle_loader.dart';
import 'package:ecotrash/core/animations/scan_pulse.dart';
import 'package:ecotrash/core/animations/sun_cloud_banner.dart';
import 'package:ecotrash/core/animations/truck_route.dart';
import 'package:ecotrash/core/animations/water_ripple.dart';
import 'package:ecotrash/core/theme/app_shapes.dart';
import 'package:ecotrash/core/theme/color_schemes.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/core/widgets/eco_components.dart';
import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:ecotrash/core/widgets/eco_states.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StyleGuidePage extends ConsumerStatefulWidget {
  const StyleGuidePage({super.key});

  @override
  ConsumerState<StyleGuidePage> createState() => _StyleGuidePageState();
}

class _StyleGuidePageState extends ConsumerState<StyleGuidePage> {
  var _playing = true;
  var _points = 180;
  var _switchValue = true;
  var _sliderValue = 0.6;
  final _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eco = Theme.of(context).extension<EcoColors>()!;
    final preferences =
        ref.watch(themeControllerProvider).asData?.value ??
        const ThemePreferences();
    final fallback = AppColorSchemes.resolve(
      brightness: Theme.of(context).brightness,
      style: ThemeColorStyle.earth,
      dynamicScheme: null,
      customSeed: preferences.customSeed,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _changePoints,
        icon: const Icon(Icons.add),
        label: const Text('Simulasi poin'),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.medium(
            title: const Text('Style Guide EcoTrash'),
            actions: [
              IconButton(
                tooltip: _playing ? 'Jeda animasi' : 'Putar animasi',
                onPressed: () => setState(() => _playing = !_playing),
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
            ],
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (kDebugMode) ...[
              Text(
                'Logo EcoTrash',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              for (final (label, brightness) in const <(String, Brightness)>[
                ('Terang', Brightness.light),
                ('Gelap', Brightness.dark),
              ])
                Card(
                  child: Theme(
                    data: ThemeData(
                      useMaterial3: true,
                      brightness: brightness,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: const Color(0xFF2E7D32),
                        brightness: brightness,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode $label'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const EcoLogo(
                                size: 48,
                                variant: EcoLogoVariant.icon,
                              ),
                              const EcoLogo(
                                size: 36,
                                variant: EcoLogoVariant.horizontal,
                              ),
                              EcoLogo(size: 48, variant: EcoLogoVariant.mono),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            Text(
              'Skema warna',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Warna aktif (dinamis atau palet pilihan)'),
            _ColorRoleGrid(scheme: scheme, eco: eco),
            const SizedBox(height: 12),
            Text('Fallback Hijau Bumi'),
            _ColorRoleGrid(scheme: fallback, eco: EcoColors.from(fallback)),
            const SizedBox(height: 24),
            Text('Tipografi', style: Theme.of(context).textTheme.headlineSmall),
            for (final (label, style) in <(String, TextStyle?)>[
              ('Display', Theme.of(context).textTheme.displaySmall),
              ('Headline', Theme.of(context).textTheme.headlineMedium),
              ('Title', Theme.of(context).textTheme.titleLarge),
              ('Body', Theme.of(context).textTheme.bodyLarge),
              ('Label', Theme.of(context).textTheme.labelLarge),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(label, style: style),
              ),
            const SizedBox(height: 24),
            Text(
              'Bentuk dan komponen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Kartu ${AppShapes.cardRadius.round()} px · input '
              '${AppShapes.inputRadius.round()} px · pill ${AppShapes.pillRadius.round()} px',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EcoButton(
                  label: 'Aksi utama',
                  icon: Icons.eco_outlined,
                  onPressed: () => _changePoints(),
                ),
                EcoButton(
                  label: 'Aksi tonal',
                  tonal: true,
                  onPressed: () => _changePoints(),
                ),
                const PointsChip(points: 240),
                const StatusBadge(label: 'Berhasil', tone: StatusTone.success),
              ],
            ),
            const SizedBox(height: 12),
            SearchAnchor(
              builder: (context, controller) => SearchBar(
                controller: controller,
                hintText: 'SearchBar — cari fitur',
                leading: const Icon(Icons.search),
                onTap: controller.openView,
                onChanged: (_) => controller.openView(),
              ),
              suggestionsBuilder: (context, controller) => [
                for (final suggestion in const [
                  'Smart Scan',
                  'Bank sampah',
                  'Rewards',
                ])
                  ListTile(
                    leading: const Icon(Icons.eco_outlined),
                    title: Text(suggestion),
                    onTap: () => controller.closeView(suggestion),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const ActionChip(
                  avatar: Icon(Icons.recycling_outlined),
                  label: Text('AssistChip'),
                  onPressed: null,
                ),
                FilterChip(
                  label: const Text('FilterChip'),
                  selected: _switchValue,
                  onSelected: (value) => setState(() => _switchValue = value),
                ),
                const InputChip(label: Text('InputChip'), onDeleted: null),
                Badge(
                  label: const Text('3'),
                  child: IconButton(
                    tooltip: 'Badge',
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Switch dengan status'),
              secondary: Icon(_switchValue ? Icons.eco_outlined : Icons.eco),
              value: _switchValue,
              onChanged: (value) => setState(() => _switchValue = value),
            ),
            Slider(
              value: _sliderValue,
              label: '${(_sliderValue * 100).round()}%',
              onChanged: (value) => setState(() => _sliderValue = value),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: ListTile(
                        leading: Icon(Icons.water_drop_outlined),
                        title: Text('Bottom sheet dengan drag handle'),
                        subtitle: Text('Komponen Material 3'),
                      ),
                    ),
                  ),
                  child: const Text('Bottom sheet'),
                ),
                OutlinedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Dialog Material 3'),
                      content: const Text('Radius dan warna mengikuti tema.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Dialog'),
                ),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Snackbar Material 3')),
                  ),
                  child: const Text('Snackbar'),
                ),
                OutlinedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => SizedBox(
                      height: 260,
                      child: NavigationDrawer(
                        selectedIndex: 0,
                        onDestinationSelected: (_) => Navigator.pop(context),
                        children: const [
                          Padding(
                            padding: EdgeInsets.fromLTRB(28, 16, 16, 8),
                            child: Text('NavigationDrawer'),
                          ),
                          NavigationDrawerDestination(
                            icon: Icon(Icons.home_outlined),
                            label: Text('Beranda'),
                          ),
                          NavigationDrawerDestination(
                            icon: Icon(Icons.eco_outlined),
                            label: Text('Rewards'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('Navigation drawer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            EcoCard(
              variant: CardVariant.outlined,
              child: const ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('Kartu outlined'),
                subtitle: Text(
                  'Permukaan tonal, radius besar, tanpa bayangan tebal',
                ),
              ),
            ),
            const SizedBox(height: 10),
            EcoTextField(
              label: 'Contoh input',
              prefixIcon: const Icon(Icons.search),
            ),
            const SizedBox(height: 24),
            Text(
              'Galeri animasi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                EarthGlobe(size: 112, enabled: _playing),
                FallingLeaves(width: 130, height: 100, enabled: _playing),
                GrowingPlant(progress: 0.8, stage: 2, enabled: _playing),
                RecycleLoader(enabled: _playing),
                ScanPulse(size: 120, enabled: _playing),
                TruckRoute(progress: 0.65, enabled: _playing),
              ],
            ),
            PointsBurst(
              points: _points,
              enabled: _playing,
              child: Card(
                color: scheme.tertiaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.stars_rounded),
                  title: Text('$_points poin'),
                  trailing: IconButton(
                    tooltip: 'Simulasikan poin masuk',
                    onPressed: _changePoints,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            WaterRipple(
              enabled: _playing,
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Riak air aktif'))),
              child: const Card(
                child: ListTile(
                  leading: Icon(Icons.water_drop_outlined),
                  title: Text('Sentuh untuk riak air'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SunCloudBanner(
              title: 'Hai, Sahabat Bumi!',
              subtitle: 'Setiap langkah kecil ikut merawat bumi.',
              enabled: _playing,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: EcoEmptyState(
                title: 'Belum ada data',
                message: 'Contoh ilustrasi kosong yang ramah dan tenang.',
                enabled: _playing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePoints() => setState(() => _points += 20);
}

class _ColorRoleGrid extends StatelessWidget {
  const _ColorRoleGrid({required this.scheme, required this.eco});

  final ColorScheme scheme;
  final EcoColors eco;

  @override
  Widget build(BuildContext context) {
    final roles = <(String, Color)>[
      ('Primary', scheme.primary),
      ('On primary', scheme.onPrimary),
      ('Primary container', scheme.primaryContainer),
      ('On primary container', scheme.onPrimaryContainer),
      ('Secondary', scheme.secondary),
      ('On secondary', scheme.onSecondary),
      ('Secondary container', scheme.secondaryContainer),
      ('On secondary container', scheme.onSecondaryContainer),
      ('Tertiary', scheme.tertiary),
      ('On tertiary', scheme.onTertiary),
      ('Tertiary container', scheme.tertiaryContainer),
      ('On tertiary container', scheme.onTertiaryContainer),
      ('Error', scheme.error),
      ('On error', scheme.onError),
      ('Error container', scheme.errorContainer),
      ('On error container', scheme.onErrorContainer),
      ('Surface', scheme.surface),
      ('On surface', scheme.onSurface),
      ('On surface variant', scheme.onSurfaceVariant),
      ('Surface dim', scheme.surfaceDim),
      ('Surface bright', scheme.surfaceBright),
      ('Surface lowest', scheme.surfaceContainerLowest),
      ('Surface low', scheme.surfaceContainerLow),
      ('Surface container', scheme.surfaceContainer),
      ('Surface high', scheme.surfaceContainerHigh),
      ('Surface highest', scheme.surfaceContainerHighest),
      ('Outline', scheme.outline),
      ('Outline variant', scheme.outlineVariant),
      ('Shadow', scheme.shadow),
      ('Scrim', scheme.scrim),
      ('Inverse surface', scheme.inverseSurface),
      ('On inverse surface', scheme.onInverseSurface),
      ('Inverse primary', scheme.inversePrimary),
      ('Surface tint', scheme.surfaceTint),
      ('Organik', eco.organic),
      ('Anorganik', eco.inorganic),
      ('B3', eco.hazardous),
      ('Poin', eco.points),
      ('Sukses', eco.success),
      ('Peringatan', eco.warning),
      ('Info', eco.info),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: roles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.15,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final (label, color) = roles[index];
        return Card(
          color: color,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      EcoColors.contrastRatio(color, Colors.white) >
                          EcoColors.contrastRatio(color, Colors.black)
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
