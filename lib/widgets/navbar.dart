import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rentals/services/chat_service.dart';
import 'package:rentals/views/chat/chat_page.dart';
import 'package:rentals/views/home/home_page.dart';
import 'package:rentals/views/home/near_me_page.dart';
import 'package:rentals/views/map/map_page.dart';
import 'package:rentals/views/my_rentals/myrent_page.dart';
import 'package:rentals/views/profile/acc_page.dart';
import 'package:rentals/views/rent/rent_page.dart';
import 'package:rentals/widgets/pressable_scale.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with TickerProviderStateMixin {
  int selectIndex = 0;
  bool isMenuOpen = false;
  late AnimationController _animationController;
  late AnimationController _wheelSnapController;
  Animation<double>? _wheelSnapAnimation;

  double wheelRotation = 0.0;
  double targetRotation = 0.0;
  double _dragStartAngle = 0.0;
  double _dragStartRotation = 0.0;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': 'assets/icons/fashion_icon.png', 'label': 'Fashion'},
    {'icon': 'assets/icons/jwellery_icon.png', 'label': 'Jewellery'},
    {'icon': 'assets/icons/vehicle_icon.png', 'label': 'Vehicle'},
    {'icon': 'assets/icons/house_icon.png', 'label': 'House'},
    {'icon': 'assets/icons/electronic_icon.png', 'label': 'Electronics'},
    {'icon': 'assets/icons/books_icon.png', 'label': 'Books'},
    {'icon': 'assets/icons/fashion_icon.png', 'label': 'Fashion'},
    {'icon': 'assets/icons/game_icon.png', 'label': 'Game'},
    {'icon': 'assets/icons/gym_icon.png', 'label': 'GYM'},
    {'icon': 'assets/icons/travel_icon.png', 'label': 'Travel'},
    {'icon': 'assets/icons/decore_icon.png', 'label': 'Decor'},
    {'icon': 'assets/icons/books_icon.png', 'label': 'Books'},
    {'icon': 'assets/icons/fashion_icon.png', 'label': 'Fashion'},
    {'icon': 'assets/icons/furniture_icon.png', 'label': 'Furniture'},
    {'icon': 'assets/icons/subscription_icon.png', 'label': 'Subscription'},
    {'icon': 'assets/icons/game_icon.png', 'label': 'Game'},
    {'icon': 'assets/icons/other_icon.png', 'label': 'Other'},
    {'icon': 'assets/icons/books_icon.png', 'label': 'Books'},
  ];

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    ChatService.initializePresence();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wheelSnapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          final animation = _wheelSnapAnimation;
          if (animation == null || !mounted) {
            return;
          }

          setState(() {
            wheelRotation = animation.value;
          });
        });

    pages = [
      HomePage(
        onMapTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          );
        },
        onNearMeTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NearMePage()),
          );
        },
        onCategorySelected: (category) {
          // HomePage handles routing internally
        },
      ),
      const ChatPage(),
      const MyrentPage(),
      const AccPage(),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _wheelSnapController.dispose();
    super.dispose();
  }

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _animationController.forward();
        HapticFeedback.lightImpact();
      } else {
        _animationController.reverse();
        _wheelSnapController.stop();
      }
    });
  }

  void _selectTab(int index) {
    if (selectIndex == index && !isMenuOpen) {
      return;
    }

    setState(() {
      selectIndex = index;
      isMenuOpen = false;
      _animationController.reverse();
    });

    HapticFeedback.selectionClick();
  }

  void _snapToClosest({double velocity = 0}) {
    const segmentAngle = (2 * math.pi) / 6;
    final projectedRotation = wheelRotation - (velocity * 0.0012);
    final newTarget = (projectedRotation / segmentAngle).round() * segmentAngle;

    setState(() {
      targetRotation = newTarget;
    });
    _wheelSnapAnimation =
        Tween<double>(begin: wheelRotation, end: targetRotation).animate(
          CurvedAnimation(
            parent: _wheelSnapController,
            curve: Curves.easeOutCubic,
          ),
        );
    _wheelSnapController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  double _normalizeAngleDelta(double angle) {
    var normalized = angle;
    while (normalized > math.pi) {
      normalized -= 2 * math.pi;
    }
    while (normalized < -math.pi) {
      normalized += 2 * math.pi;
    }
    return normalized;
  }

  double _pointerAngle(Offset localPosition, double wheelSize) {
    final center = Offset(wheelSize / 2, wheelSize / 2);
    return math.atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );
  }

  int _getActiveIndex(double rotation) {
    const segmentAngle = (2 * math.pi) / 6;
    int index = ((-rotation) / segmentAngle).round() % 18;
    return index < 0 ? index + 18 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(index: selectIndex, children: pages),
          if (isMenuOpen || _animationController.value > 0)
            _buildSmallFanMenu(),
        ],
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 92),
            painter: WaveBarPainter(),
          ),
          Container(
            height: 72,
            padding: const EdgeInsets.only(bottom: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _navItem('assets/icons/home_icon.png', "Home", 0),
                _navItem('assets/icons/chat_icon.png', "Chat", 1),
                const SizedBox(width: 50),
                _navItem('assets/icons/MyRent_icon.png', "My Rent", 2),
                _navItem('assets/icons/account_icon.png', "Account", 3),
              ],
            ),
          ),
          Positioned(
            bottom: 62,
            child: PressableScale(
              onTap: toggleMenu,
              onLongPress: () {
                setState(() {
                  isMenuOpen = false;
                  _animationController.reverse();
                });
                HapticFeedback.heavyImpact();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RentPage()),
                );
              },
              scaleDown: 0.93,
              child: AnimatedScale(
                scale: isMenuOpen ? 1.04 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00C2FF), Color(0xFF007AFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: isMenuOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            isMenuOpen ? Icons.close : Icons.add,
                            key: ValueKey<bool>(isMenuOpen),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 26,
            child: Text(
              "Rent",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String assetPath, String label, int index) {
    final isActive = selectIndex == index;
    final activeColor = isActive ? Colors.blueAccent : Colors.white;

    return PressableScale(
      onTap: () => _selectTab(index),
      scaleDown: 0.94,
      child: AnimatedSlide(
        offset: Offset(0, isActive ? -0.08 : 0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: isActive ? 1.05 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  final iconSize = 24 + value;
                  return Image.asset(
                    assetPath,
                    width: iconSize,
                    height: iconSize,
                    color: activeColor,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image, color: activeColor, size: iconSize),
                  );
                },
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallFanMenu() {
    const wheelSize = 200.0;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final activeIndex = _getActiveIndex(wheelRotation);
        final currentSet = activeIndex ~/ 6;

        return Stack(
          children: [
            if (isMenuOpen)
              GestureDetector(
                onTap: toggleMenu,
                child: Container(color: Colors.black.withValues(alpha: 0.05)),
              ),
            Positioned(
              bottom: 92,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animationController,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  ).drive(Tween<double>(begin: 0.94, end: 1)),
                  child: Center(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.5,
                        child: SizedBox(
                          width: wheelSize,
                          height: wheelSize,
                          child: GestureDetector(
                            onPanStart: (details) {
                              _wheelSnapController.stop();
                              _dragStartAngle = _pointerAngle(
                                details.localPosition,
                                wheelSize,
                              );
                              _dragStartRotation = wheelRotation;
                            },
                            onPanUpdate: (details) {
                              final currentAngle = _pointerAngle(
                                details.localPosition,
                                wheelSize,
                              );
                              final delta = _normalizeAngleDelta(
                                currentAngle - _dragStartAngle,
                              );
                              setState(() {
                                wheelRotation =
                                    _dragStartRotation + (delta * 0.92);
                                targetRotation = wheelRotation;
                              });
                            },
                            onPanEnd: (details) {
                              _snapToClosest(
                                velocity: details.velocity.pixelsPerSecond.dx,
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: wheelRotation,
                                  child: CustomPaint(
                                    size: const Size(wheelSize, wheelSize),
                                    painter: FanWheelPainter(
                                      itemCount: 6,
                                      activeIndex: activeIndex % 6,
                                    ),
                                  ),
                                ),
                                ...List.generate(6, (i) {
                                  final actualIndex = (currentSet * 6) + i;
                                  final segmentAngle = 2 * math.pi / 6;
                                  final angle =
                                      segmentAngle * i + wheelRotation;

                                  double norm =
                                      (angle + math.pi / 2) % (2 * math.pi);
                                  if (norm < 0) norm += 2 * math.pi;

                                  if (norm > math.pi * 0.9 &&
                                      norm < math.pi * 1.1) {
                                    return const SizedBox.shrink();
                                  }
                                  if (norm > math.pi && norm < 2 * math.pi) {
                                    return const SizedBox.shrink();
                                  }

                                  final isActive = actualIndex == activeIndex;

                                  return Transform.rotate(
                                    angle: angle,
                                    child: Transform.translate(
                                      offset: Offset(0, isActive ? -75 : -70),
                                      child: Transform.rotate(
                                        angle: -angle,
                                        child: PressableScale(
                                          scaleDown: 0.92,
                                          onTap: () {
                                            RentPage.categoryController.text =
                                                menuItems[actualIndex]['label'];
                                            setState(() {
                                              isMenuOpen = false;
                                              _animationController.reverse();
                                            });
                                            HapticFeedback.mediumImpact();

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const RentPage(),
                                              ),
                                            );
                                          },
                                          child: _fanOption(
                                            menuItems[actualIndex]['icon'],
                                            menuItems[actualIndex]['label'],
                                            isActive,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fanOption(String assetPath, String label, bool isActive) {
    return AnimatedScale(
      scale: isActive ? 1.06 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: isActive
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, isActive ? -2 : 0, 0),
            child: Image.asset(
              assetPath,
              width: isActive ? 24 : 26,
              height: isActive ? 24 : 26,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image,
                color: Colors.white,
                size: isActive ? 24 : 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF113F67)
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = size.width / 2;
    path.moveTo(0, 0);
    path.lineTo(center - 55, 0);
    path.quadraticBezierTo(center - 45, 0, center - 40, 12);
    path.arcToPoint(
      Offset(center + 40, 12),
      radius: const Radius.circular(42),
      clockwise: false,
    );
    path.quadraticBezierTo(center + 45, 0, center + 55, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FanWheelPainter extends CustomPainter {
  final int itemCount;
  final int activeIndex;

  FanWheelPainter({required this.itemCount, required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepAngle = (2 * math.pi) / itemCount;
    const spacing = 0.04;

    for (int i = 0; i < itemCount; i++) {
      final isActive = i == activeIndex;
      final paint = Paint()
        ..color = isActive ? const Color(0xFF113F67) : const Color(0xFF00C2FF);

      final startAngle =
          (sweepAngle * i) - (math.pi / 2) - (sweepAngle / 2) + (spacing / 2);
      final drawSweep = sweepAngle - spacing;
      canvas.drawArc(rect, startAngle, drawSweep, true, paint);

      if (!isActive) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;

        canvas.drawArc(rect, startAngle, drawSweep, true, borderPaint);
      }
    }

    canvas.drawCircle(center, radius * 0.35, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant FanWheelPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex;
}
