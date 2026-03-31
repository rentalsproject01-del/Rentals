import 'dart:async';

import 'package:flutter/material.dart';

enum AppFeedbackType { success, info, error }

class AppFeedback {
  static OverlayEntry? _currentEntry;

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(
      context,
      type: AppFeedbackType.success,
      title: title,
      message: message,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(context, type: AppFeedbackType.info, title: title, message: message);
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(context, type: AppFeedbackType.error, title: title, message: message);
  }

  static void _show(
    BuildContext context, {
    required AppFeedbackType type,
    required String title,
    required String message,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopFeedbackBanner(
        title: title,
        message: message,
        type: type,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _TopFeedbackBanner extends StatefulWidget {
  const _TopFeedbackBanner({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final AppFeedbackType type;
  final VoidCallback onDismissed;

  @override
  State<_TopFeedbackBanner> createState() => _TopFeedbackBannerState();
}

class _TopFeedbackBannerState extends State<_TopFeedbackBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0, -0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  late final Animation<double> _opacityAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _dismissTimer = Timer(
      Duration(
        milliseconds: widget.type == AppFeedbackType.error ? 2400 : 1600,
      ),
      _dismiss,
    );
  }

  Future<void> _dismiss() async {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topInset + 10,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          bottom: false,
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: _FeedbackCard(
                    title: widget.title,
                    message: widget.message,
                    type: widget.type,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final AppFeedbackType type;

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (type) {
      AppFeedbackType.success => const Color(0xFF16BCE6),
      AppFeedbackType.info => const Color(0xFF52C7FF),
      AppFeedbackType.error => const Color(0xFFFF7B8A),
    };

    final icon = switch (type) {
      AppFeedbackType.success => Icons.check_circle_rounded,
      AppFeedbackType.info => Icons.info_rounded,
      AppFeedbackType.error => Icons.error_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF113F67), Color(0xFF1B5F94)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF113F67).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(width: 5, height: 72, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.18),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
