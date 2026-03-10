import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

// --- FIXED IMPORTS ---
import 'package:rentals/views/home/home_page.dart';
import 'package:rentals/views/chat/chat_page.dart';
import 'package:rentals/views/rent/rent_page.dart';
import 'package:rentals/views/my_rentals/myrent_page.dart';
import 'package:rentals/views/profile/acc_page.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with SingleTickerProviderStateMixin {
  int selectIndex = 0;
  bool isMenuOpen = false;
  late AnimationController _animationController;

  double wheelRotation = 0.0;
  double targetRotation = 0.0;

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

  // --- UPDATED: Removed RentPage to decouple it from the bottom navbar ---
  final List<Widget> pages = [
    const HomePage(), // Index 0
    const ChatPage(), // Index 1
    const MyrentPage(), // Index 2 (Shifted from 3)
    const AccPage(), // Index 3 (Shifted from 4)
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      }
    });
  }

  void _snapToClosest() {
    double segmentAngle = (2 * math.pi) / 6;
    double newTarget = (wheelRotation / segmentAngle).round() * segmentAngle;

    setState(() {
      targetRotation = newTarget;
      wheelRotation = targetRotation;
    });
    HapticFeedback.mediumImpact();
  }

  int _getActiveIndex(double rotation) {
    double segmentAngle = (2 * math.pi) / 6;
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
                // --- UPDATED INDICES FOR REMAINING TABS ---
                _navItem('assets/icons/MyRent_icon.png', "My Rent", 2),
                _navItem('assets/icons/account_icon.png', "Account", 3),
              ],
            ),
          ),
          Positioned(
            bottom: 62,
            child: GestureDetector(
              onTap: toggleMenu,
              onLongPress: () {
                // --- UPDATED: Use Navigator.push instead of changing selectIndex ---
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
                  child: Icon(
                    isMenuOpen ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: 28,
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
    bool isActive = selectIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectIndex = index;
          isMenuOpen = false;
          _animationController.reverse();
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 24,
            height: 24,
            color: isActive ? Colors.blueAccent : Colors.white,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blueAccent : Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallFanMenu() {
    double wheelSize = 200.0;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        int activeIndex = _getActiveIndex(targetRotation);
        int currentSet = activeIndex ~/ 6;

        return Stack(
          children: [
            if (isMenuOpen)
              GestureDetector(
                onTap: toggleMenu,
                child: Container(color: Colors.black.withOpacity(0.05)),
              ),
            Positioned(
              bottom: 92,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animationController,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: wheelRotation,
                      end: targetRotation,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.5,
                          child: SizedBox(
                            width: wheelSize,
                            height: wheelSize,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  wheelRotation -= details.delta.dx * 0.007;
                                  targetRotation = wheelRotation;
                                });
                              },
                              onPanEnd: (_) => _snapToClosest(),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: value,
                                    child: CustomPaint(
                                      size: Size(wheelSize, wheelSize),
                                      painter: FanWheelPainter(
                                        itemCount: 6,
                                        activeIndex: activeIndex % 6,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(6, (i) {
                                    int actualIndex = (currentSet * 6) + i;
                                    double segmentAngle = (2 * math.pi / 6);
                                    double angle = segmentAngle * i + value;

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

                                    bool isActive = actualIndex == activeIndex;

                                    return Transform.rotate(
                                      angle: angle,
                                      child: Transform.translate(
                                        offset: Offset(0, isActive ? -75 : -70),
                                        child: Transform.rotate(
                                          angle: -angle,
                                          child: GestureDetector(
                                            onTap: () {
                                              // --- UPDATED: Use Navigator.push here too ---
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
                      );
                    },
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        Image.asset(
          assetPath,
          width: isActive ? 24 : 26,
          height: isActive ? 24 : 26,
          color: Colors.white,
        ),
      ],
    );
  }
}

class WaveBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint fillPaint = Paint()
      ..color = const Color(0xFF113F67)
      ..style = PaintingStyle.fill;

    Path path = Path();
    double center = size.width / 2;
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
    const double spacing = 0.04;

    for (int i = 0; i < itemCount; i++) {
      final bool isActive = i == activeIndex;
      final paint = Paint()
        ..color = isActive ? const Color(0xFF113F67) : const Color(0xFF00C2FF);

      double startAngle =
          (sweepAngle * i) - (math.pi / 2) - (sweepAngle / 2) + (spacing / 2);
      double drawSweep = sweepAngle - spacing;
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
