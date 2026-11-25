import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const fontFamily = 'Roboto';

  static TextTheme apply(TextTheme base) =>
      base.apply(fontFamily: fontFamily, displayColor: null, bodyColor: null);
}
