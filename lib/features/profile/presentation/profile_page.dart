import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/theme/color_schemes.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/presentation/auth_error_message.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:ecotrash/features/profile/domain/entities/profile_stats.dart';
import 'package:ecotrash/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return authState.when(
      loading: () => const AppLoadingSkeleton(label: 'Memuat profil', rows: 2),
      error: (error, _) => AppMessageState(
        icon: Icons.error_outline,
        message: authErrorMessage(error),
        actionLabel: 'Coba lagi',
        onAction: () => ref.invalidate(authControllerProvider),
      ),
      data: (user) {
        if (user == null) {
          return AppMessageState(
            icon: Icons.person_outline,
            message: 'Tidak ada sesi aktif.',
            actionLabel: 'Masuk',
            onAction: () => context.go(AppRoutes.login),
          );
        }
        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);
    final themeState = ref.watch(themeControllerProvider);
    final preferences = themeState.asData?.value ?? const ThemePreferences();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    user.name.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  key: const Key('profile-name'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  key: const Key('profile-email'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('profile-edit-name'),
                  onPressed: () => _editName(context, ref, user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Ubah nama'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Statistik dampak', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        stats.when(
          loading: () => const AppLoadingSkeleton(
            label: 'Memuat statistik profil',
            rows: 2,
          ),
          error: (error, _) => AppMessageState(
            icon: Icons.error_outline,
            message: 'Statistik belum dapat dimuat: $error',
            actionLabel: 'Coba lagi',
            onAction: () => ref.invalidate(profileStatsProvider),
          ),
          data: (value) => _ProfileStats(stats: value),
        ),
        const SizedBox(height: 20),
        Text(
          'Tampilan aplikasi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (themeState.hasError)
          AppMessageState(
            icon: Icons.error_outline,
            message: 'Pengaturan tema gagal dimuat: ${themeState.error}',
            actionLabel: 'Coba lagi',
            onAction: () => ref.invalidate(themeControllerProvider),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode tema',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeModeChoice>(
                    key: const Key('profile-theme-selector'),
                    segments: const [
                      ButtonSegment(
                        value: ThemeModeChoice.system,
                        label: Text('Ikuti sistem'),
                        icon: Icon(Icons.settings_suggest_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeModeChoice.light,
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeModeChoice.dark,
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {
                      preferences.mode == ThemeModeChoice.amoled
                          ? ThemeModeChoice.dark
                          : preferences.mode,
                    },
                    onSelectionChanged: (selection) =>
                        _setMode(context, ref, selection.first),
                  ),
                  SwitchListTile.adaptive(
                    key: const Key('profile-amoled-mode'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hitam pekat (AMOLED)'),
                    subtitle: const Text('Aktif saat mode gelap dipilih'),
                    secondary: const Icon(Icons.brightness_2_outlined),
                    value: preferences.amoled,
                    onChanged: (enabled) => _setMode(
                      context,
                      ref,
                      enabled ? ThemeModeChoice.amoled : ThemeModeChoice.dark,
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Gaya warna',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<ThemeColorStyle>(
                      key: const Key('profile-color-style-selector'),
                      segments: const [
                        ButtonSegment(
                          value: ThemeColorStyle.dynamic,
                          label: Text('Dinamis'),
                        ),
                        ButtonSegment(
                          value: ThemeColorStyle.earth,
                          label: Text('Hijau Bumi'),
                        ),
                        ButtonSegment(
                          value: ThemeColorStyle.custom,
                          label: Text('Pilih sendiri'),
                        ),
                      ],
                      selected: {preferences.colorStyle},
                      onSelectionChanged: (selection) =>
                          _setColorStyle(context, ref, selection.first),
                    ),
                  ),
                  if (preferences.colorStyle == ThemeColorStyle.dynamic)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Mengikuti wallpaper jika perangkat mendukung; '
                        'selain itu memakai Hijau Bumi.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (preferences.colorStyle == ThemeColorStyle.custom)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final seed in AppColorSchemes.palettes)
                          ChoiceChip(
                            key: Key('profile-seed-${seed.name}'),
                            avatar: CircleAvatar(
                              backgroundColor: seed.color,
                              radius: 9,
                            ),
                            label: Text(seed.name),
                            selected:
                                preferences.customSeed == seed.color.toARGB32(),
                            onSelected: (_) =>
                                _setSeed(context, ref, seed.color.toARGB32()),
                          ),
                      ],
                    ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    key: const Key('profile-earth-animations'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Animasi Bumi'),
                    subtitle: const Text(
                      'Matikan animasi dekoratif kapan saja',
                    ),
                    secondary: const Icon(Icons.animation_outlined),
                    value: preferences.earthAnimationsEnabled,
                    onChanged: (enabled) =>
                        _setAnimations(context, ref, enabled),
                  ),
                ],
              ),
            ),
          ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('profile-style-guide'),
            onPressed: () => context.push(AppRoutes.styleGuide),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Buka Style Guide'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          key: const Key('profile-sign-out'),
          onPressed: () => _confirmSignOut(context, ref),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar dari akun'),
        ),
      ],
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    AuthUser user,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(initialName: user.name),
    );
    if (name == null || !context.mounted) {
      return;
    }

    final updated = await ref
        .read(authControllerProvider.notifier)
        .updateDisplayName(name);
    if (!context.mounted) {
      return;
    }
    if (updated == null) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? 'Nama tidak dapat diperbarui.'
                : authErrorMessage(error),
          ),
        ),
      );
    }
  }

  Future<void> _setMode(
    BuildContext context,
    WidgetRef ref,
    ThemeModeChoice mode,
  ) async {
    try {
      await ref.read(themeControllerProvider.notifier).setMode(mode);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _setColorStyle(
    BuildContext context,
    WidgetRef ref,
    ThemeColorStyle style,
  ) async {
    try {
      await ref.read(themeControllerProvider.notifier).setColorStyle(style);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _setSeed(BuildContext context, WidgetRef ref, int seed) async {
    try {
      await ref.read(themeControllerProvider.notifier).setCustomSeed(seed);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _setAnimations(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref
          .read(themeControllerProvider.notifier)
          .setEarthAnimationsEnabled(enabled);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk kembali untuk menggunakan EcoTrash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('profile-sign-out-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final signedOut = await ref.read(authControllerProvider.notifier).signOut();
    if (signedOut && context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ubah nama'),
    content: TextField(
      key: const Key('profile-name-input'),
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Nama pengguna'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        key: const Key('profile-save-name'),
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Simpan'),
      ),
    ],
  );
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ProfileStatTile(
        key: const Key('profile-total-weight'),
        icon: Icons.scale_outlined,
        label: 'Total berat disetor',
        value: '${stats.totalWeightKg.toStringAsFixed(1)} kg',
      ),
      _ProfileStatTile(
        key: const Key('profile-total-points'),
        icon: Icons.eco_outlined,
        label: 'Total poin diperoleh',
        value: '${stats.totalPoints} poin',
      ),
      _ProfileStatTile(
        key: const Key('profile-completed-pickups'),
        icon: Icons.local_shipping_outlined,
        label: 'Penjemputan selesai',
        value: '${stats.completedPickups}',
      ),
      _ProfileStatTile(
        key: const Key('profile-co2-saved'),
        icon: Icons.eco_outlined,
        label: 'Estimasi CO₂ dihemat',
        value: '${stats.co2SavedKg.toStringAsFixed(1)} kg CO₂',
      ),
    ],
  );
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
