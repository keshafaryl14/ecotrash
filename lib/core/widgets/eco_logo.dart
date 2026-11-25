import 'package:ecotrash/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

enum EcoLogoVariant { icon, horizontal, mono }

class EcoLogo extends StatelessWidget {
  const EcoLogo({
    this.size = 48,
    this.variant = EcoLogoVariant.icon,
    this.semanticLabel = 'Logo EcoTrash',
    this.color,
    this.hero = false,
    super.key,
  });

  final double size;
  final EcoLogoVariant variant;
  final String semanticLabel;
  final Color? color;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHorizontal = variant == EcoLogoVariant.horizontal;
    final imagePath = switch (variant) {
      EcoLogoVariant.icon => AppAssets.logoIcon,
      EcoLogoVariant.horizontal =>
        isDark ? AppAssets.logoHorizontalDark : AppAssets.logoHorizontal,
      EcoLogoVariant.mono => AppAssets.logoMono,
    };
    final displayColor = color ?? theme.colorScheme.primary;
    final width = isHorizontal ? size * (16 / 9) : size;
    final image = Image.asset(
      imagePath,
      width: width,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: size,
        child: Icon(Icons.eco, size: size * 0.62, color: displayColor),
      ),
    );
    final logo = variant == EcoLogoVariant.mono
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(displayColor, BlendMode.srcIn),
            child: image,
          )
        : image;

    return Semantics(
      key: const Key('eco-logo-semantics'),
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: hero ? Hero(tag: 'eco_logo', child: logo) : logo,
      ),
    );
  }
}
