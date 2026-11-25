import 'package:flutter/material.dart';

abstract final class AppShapes {
  static const cardRadius = 26.0;
  static const largeRadius = 28.0;
  static const inputRadius = 16.0;
  static const smallRadius = 12.0;
  static const pillRadius = 999.0;

  static final card = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(cardRadius),
  );
  static final input = OutlineInputBorder(
    borderRadius: BorderRadius.circular(inputRadius),
  );
  static final dialog = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(largeRadius),
  );
}
