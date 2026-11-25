import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef EcoPainterBuilder = CustomPainter Function(Animation<double> animation);

class EcoLoopPainter extends ConsumerStatefulWidget {
  const EcoLoopPainter({
    required this.painterBuilder,
    required this.width,
    required this.height,
    this.duration = const Duration(seconds: 12),
    this.enabled = true,
    this.semanticsLabel,
    super.key,
  });

  final EcoPainterBuilder painterBuilder;
  final double width;
  final double height;
  final Duration duration;
  final bool enabled;
  final String? semanticsLabel;

  @override
  ConsumerState<EcoLoopPainter> createState() => _EcoLoopPainterState();
}

class _EcoLoopPainterState extends ConsumerState<EcoLoopPainter>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final ProviderSubscription<bool> _motionSubscription;
  late bool _preferenceEnabled;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _preferenceEnabled = ref.read(earthAnimationsEnabledProvider);
    _motionSubscription = ref.listenManual<bool>(
      earthAnimationsEnabledProvider,
      (previous, next) {
        _preferenceEnabled = next;
        if (mounted) {
          _syncPlayback();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant EcoLoopPainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (mounted) {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    final canPlay =
        widget.enabled &&
        _preferenceEnabled &&
        !MediaQuery.of(context).disableAnimations &&
        TickerMode.valuesOf(context).enabled &&
        _lifecycleState == AppLifecycleState.resumed;
    if (canPlay) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionSubscription.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    image: widget.semanticsLabel != null,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              size: Size(widget.width, widget.height),
              painter: widget.painterBuilder(_controller),
            ),
          ),
        ),
      ),
    ),
  );
}
