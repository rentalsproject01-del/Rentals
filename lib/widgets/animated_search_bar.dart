import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({
    super.key,
    this.onTap,
    this.actionIcon,
    this.onActionTap,
  });

  final VoidCallback? onTap;
  final Widget? actionIcon;
  final VoidCallback? onActionTap;

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  final List<String> _searchHints = const [
    'Camera',
    'Speaker',
    'Book',
    'Jacket',
    'Sneaker',
    'Necklace',
    'PS5',
    'Subscription',
  ];

  int _currentHintIndex = 0;
  String _displayedText = '';
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    const typingSpeed = Duration(milliseconds: 150);
    const deleteSpeed = Duration(milliseconds: 100);
    const pauseDuration = Duration(seconds: 2);

    _typingTimer = Timer.periodic(_isDeleting ? deleteSpeed : typingSpeed, (
      timer,
    ) {
      if (!mounted || _searchHints.isEmpty) return;

      final currentFullText = _searchHints[_currentHintIndex];
      setState(() {
        if (!_isDeleting) {
          if (_charIndex < currentFullText.length) {
            _charIndex++;
            _displayedText = currentFullText.substring(0, _charIndex);
          } else {
            _isDeleting = true;
            _typingTimer?.cancel();
            Future.delayed(pauseDuration, _startTyping);
          }
        } else {
          if (_charIndex > 0) {
            _charIndex--;
            _displayedText = currentFullText.substring(0, _charIndex);
          } else {
            _isDeleting = false;
            _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
            _typingTimer?.cancel();
            Future.delayed(const Duration(milliseconds: 500), _startTyping);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/search_icon.png',
                    height: 20,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF113F67),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayedText,
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: widget.onActionTap,
          behavior: HitTestBehavior.opaque,
          child:
              widget.actionIcon ??
              Image.asset(
                'assets/icons/cart_icon.png',
                height: 24,
                width: 24,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
        ),
      ],
    );
  }
}
