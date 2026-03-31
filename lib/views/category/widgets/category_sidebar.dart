import 'package:flutter/material.dart';
import 'package:rentals/widgets/pressable_scale.dart';

class CategorySidebar extends StatefulWidget {
  const CategorySidebar({
    super.key,
    required this.subCategories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> subCategories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<CategorySidebar> createState() => _CategorySidebarState();
}

class _CategorySidebarState extends State<CategorySidebar> {
  static const double _sidebarWidth = 85;
  static const double _itemExtent = 92;
  static const double _topPadding = 25;
  static const double _bottomPadding = 20;
  static const double _itemVerticalPadding = 12;
  static const double _highlightSize = 50;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelection());
  }

  @override
  void didUpdateWidget(covariant CategorySidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.subCategories.length != widget.subCategories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelection());
    }
  }

  void _scrollToSelection() {
    if (!_scrollController.hasClients) {
      return;
    }

    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = (widget.selectedIndex * _itemExtent) - 24;
    _scrollController.animateTo(
      targetOffset.clamp(0, maxExtent).toDouble(),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentHeight =
        _topPadding +
        _bottomPadding +
        (widget.subCategories.length * _itemExtent);
    final highlightTop =
        _topPadding +
        (widget.selectedIndex * _itemExtent) +
        _itemVerticalPadding;

    return Container(
      width: _sidebarWidth,
      decoration: const BoxDecoration(
        color: Color(0xFFDDF3FA),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(35)),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          height: contentHeight,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: (_sidebarWidth - _highlightSize) / 2,
                top: highlightTop,
                child: IgnorePointer(
                  child: Container(
                    height: _highlightSize,
                    width: _highlightSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A2FF), Color(0xFF16BCE6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF16BCE6,
                          ).withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: _topPadding),
                  ...List.generate(widget.subCategories.length, (index) {
                    final subCat = widget.subCategories[index];
                    final isSelected = widget.selectedIndex == index;

                    final formattedAssetName = subCat
                        .toLowerCase()
                        .replaceAll(' ', '_')
                        .replaceAll('/', '_')
                        .replaceAll('ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢', '')
                        .replaceAll('Ã¢â‚¬â„¢', '')
                        .replaceAll('-', '_');

                    return SizedBox(
                      height: _itemExtent,
                      child: PressableScale(
                        onTap: () => widget.onSelected(index),
                        scaleDown: 0.94,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: _itemVerticalPadding,
                          ),
                          child: Column(
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.06 : 1,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  height: _highlightSize,
                                  width: _highlightSize,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.transparent
                                        : const Color(0xFF70C6E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: Image.asset(
                                        'assets/icons/$formattedAssetName.png',
                                        key: ValueKey<String>(
                                          '$formattedAssetName-$isSelected',
                                        ),
                                        height: 40,
                                        width: 40,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  isSelected
                                                      ? Icons.check_circle
                                                      : Icons.image,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF113F67)
                                      : const Color(0xFF00A2FF),
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                child: Text(
                                  subCat,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: _bottomPadding),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
