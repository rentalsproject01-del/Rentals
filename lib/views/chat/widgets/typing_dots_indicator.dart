import 'package:flutter/material.dart';

class TypingDotsIndicator extends StatefulWidget {
  const TypingDotsIndicator({super.key});

  @override
  State<TypingDotsIndicator> createState() => _TypingDotsIndicatorState();
}

class _TypingDotsIndicatorState extends State<TypingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(3, (index) {
              final progress = (_controller.value - (index * 0.18)).clamp(
                0.0,
                1.0,
              );
              final opacity = progress < 0.5
                  ? 0.35 + (progress * 1.1)
                  : 0.9 - ((progress - 0.5) * 0.8);
              final translateY = progress < 0.5
                  ? -2.0 * progress
                  : -1.0 + ((progress - 0.5) * 2.0);

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.white54,
                      Colors.greenAccent,
                      opacity.clamp(0.0, 1.0),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
