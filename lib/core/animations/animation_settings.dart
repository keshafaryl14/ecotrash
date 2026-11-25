import 'package:flutter/material.dart';

bool shouldPlayEcoAnimation(BuildContext context, {required bool enabled}) {
  return enabled &&
      !MediaQuery.of(context).disableAnimations &&
      TickerMode.valuesOf(context).enabled;
}
