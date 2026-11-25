import 'package:animations/animations.dart';
import 'package:ecotrash/core/theme/app_shapes.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EcoButton extends ConsumerWidget {
  const EcoButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool tonal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animate =
        ref.watch(earthAnimationsEnabledProvider) &&
        !MediaQuery.of(context).disableAnimations;
    final button = tonal
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon ?? Icons.eco_outlined),
            label: Text(label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon ?? Icons.eco_outlined),
            label: Text(label),
          );
    if (!animate) {
      return button;
    }
    return button
        .animate()
        .fadeIn(duration: 260.ms)
        .slideY(begin: 0.04, end: 0, duration: 260.ms);
  }
}

class EcoCard extends StatelessWidget {
  const EcoCard({
    required this.child,
    this.onTap,
    this.openBuilder,
    this.color,
    this.variant = CardVariant.filled,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final WidgetBuilder? openBuilder;
  final Color? color;
  final CardVariant variant;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      elevation: variant == CardVariant.elevated ? 1 : 0,
      shape: variant == CardVariant.outlined
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.cardRadius),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            )
          : AppShapes.card,
      child: onTap == null
          ? child
          : InkWell(
              borderRadius: BorderRadius.circular(AppShapes.cardRadius),
              onTap: onTap,
              child: child,
            ),
    );
    if (openBuilder == null) {
      return card;
    }
    return OpenContainer<void>(
      closedColor: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
      closedShape: AppShapes.card,
      closedElevation: 0,
      transitionDuration: const Duration(milliseconds: 380),
      openBuilder: (context, action) => openBuilder!(context),
      closedBuilder: (context, action) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          onTap: action,
          child: child,
        ),
      ),
    );
  }
}

class EcoTextField extends StatelessWidget {
  const EcoTextField({
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.maxLines = 1,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, prefixIcon: prefixIcon),
  );
}

class WasteCategoryBadge extends StatelessWidget {
  const WasteCategoryBadge({required this.category, super.key});

  final WasteCategory category;

  @override
  Widget build(BuildContext context) {
    final eco = Theme.of(context).extension<EcoColors>()!;
    final (label, foreground, background) = switch (category) {
      WasteCategory.organic => ('Organik', eco.organic, eco.organicContainer),
      WasteCategory.inorganic => (
        'Anorganik',
        eco.inorganic,
        eco.inorganicContainer,
      ),
      WasteCategory.hazardous => ('B3', eco.hazardous, eco.hazardousContainer),
    };
    final onBackground = switch (category) {
      WasteCategory.organic => eco.onOrganicContainer,
      WasteCategory.inorganic => eco.onInorganicContainer,
      WasteCategory.hazardous => eco.onHazardousContainer,
    };
    return Chip(
      avatar: Icon(
        switch (category) {
          WasteCategory.organic => Icons.compost_outlined,
          WasteCategory.inorganic => Icons.recycling_outlined,
          WasteCategory.hazardous => Icons.warning_amber_outlined,
        },
        size: 18,
        color: foreground,
      ),
      backgroundColor: background,
      label: Text(label, style: TextStyle(color: onBackground)),
    );
  }
}

class PointsChip extends StatelessWidget {
  const PointsChip({required this.points, super.key});

  final int points;

  @override
  Widget build(BuildContext context) {
    final eco = Theme.of(context).extension<EcoColors>()!;
    return Chip(
      avatar: Icon(Icons.stars_rounded, color: eco.points),
      backgroundColor: eco.pointsContainer,
      label: Text(
        '$points poin',
        style: TextStyle(color: eco.onPointsContainer),
      ),
    );
  }
}

enum StatusTone { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final eco = Theme.of(context).extension<EcoColors>()!;
    final (color, foreground) = switch (tone) {
      StatusTone.success => (eco.success, eco.onSuccess),
      StatusTone.warning => (eco.warning, eco.onWarning),
      StatusTone.error => (
        Theme.of(context).colorScheme.error,
        Theme.of(context).colorScheme.onError,
      ),
      StatusTone.info => (eco.info, eco.onInfo),
    };
    return Badge(
      backgroundColor: color,
      textColor: foreground,
      label: Text(label),
    );
  }
}

enum CardVariant { filled, elevated, outlined }

class EcoLoadingSkeleton extends ConsumerWidget {
  const EcoLoadingSkeleton({
    this.width = double.infinity,
    this.height = 72,
    this.enabled = true,
    super.key,
  });

  final double width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    final animate =
        enabled &&
        ref.watch(earthAnimationsEnabledProvider) &&
        !MediaQuery.of(context).disableAnimations;
    final skeleton = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
    );
    if (!animate) {
      return skeleton;
    }
    return skeleton
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1800.ms,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        );
  }
}
