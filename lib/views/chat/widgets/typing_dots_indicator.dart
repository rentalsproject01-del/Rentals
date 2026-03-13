import 'dart:math' as math;

import 'package:flutter/material.dart';

class TypingDotsIndicator extends StatefulWidget {
  const TypingDotsIndicator({
    super.key,
    this.activeColor = const Color(0xFF16BCE6),
    this.inactiveColor = const Color(0x553F6E8F),
    this.dotSize = 6,
    this.spacing = 4,
    this.bounceOffset = 2.5,
    this.minScale = 0.72,
    this.maxScale = 1.0,
  });

  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;
  final double bounceOffset;
  final double minScale;
  final double maxScale;

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
      duration: const Duration(milliseconds: 1180),
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
      child: SizedBox(
        height: widget.dotSize + widget.bounceOffset + 4,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (index) {
                var progress = (_controller.value - (index * 0.18)) % 1;
                if (progress < 0) {
                  progress += 1;
                }

                final wave = math.sin(progress * math.pi);
                final eased = Curves.easeOut.transform(wave.clamp(0.0, 1.0));
                final opacity = 0.34 + (eased * 0.66);
                final scale =
                    widget.minScale +
                    ((widget.maxScale - widget.minScale) * eased);
                final translateY = -widget.bounceOffset * eased;

                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: widget.dotSize,
                        height: widget.dotSize,
                        margin: EdgeInsets.only(
                          right: index == 2 ? 0 : widget.spacing,
                        ),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            widget.inactiveColor,
                            widget.activeColor,
                            eased,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
