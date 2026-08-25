import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({super.key});

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A much slower, consistent 2-second rotation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RotationTransition(
        turns: _controller,
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: 0.25, // Fixed arc size prevents the 'sweep' stutter
            strokeWidth: 3.0,
            color: Theme.of(context).colorScheme.primary,
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );
  }
}
