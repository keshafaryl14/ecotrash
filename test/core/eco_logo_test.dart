import 'package:ecotrash/core/constants/app_assets.dart';
import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final variant in EcoLogoVariant.values) {
    testWidgets('$variant logo renders with its semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EcoLogo(variant: variant, size: 64)),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byKey(const Key('eco-logo-semantics')),
      );
      expect(semantics.label, 'Logo EcoTrash');
      expect(find.byType(Image), findsOneWidget);
    });
  }

  testWidgets('horizontal logo uses the dark asset in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: EcoLogo(variant: EcoLogoVariant.horizontal)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    final resizeImage = image.image as ResizeImage;
    expect(resizeImage.imageProvider, isA<AssetImage>());
    expect(
      (resizeImage.imageProvider as AssetImage).assetName,
      AppAssets.logoHorizontalDark,
    );
  });

  testWidgets('shows a leaf fallback if the image asset fails', (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _BrokenAssetBundle(),
        child: const MaterialApp(home: Scaffold(body: EcoLogo(size: 64))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.eco), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _BrokenAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key == 'AssetManifest.bin' || key == 'AssetManifest.json') {
      return rootBundle.load(key);
    }
    throw FlutterError('Test asset load failure: $key');
  }
}
