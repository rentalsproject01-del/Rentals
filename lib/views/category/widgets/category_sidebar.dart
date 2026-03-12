import 'package:flutter/material.dart';

class CategorySidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      decoration: const BoxDecoration(
        color: Color(0xFFDDF3FA),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(35)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 25, bottom: 20),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final subCat = subCategories[index];
          final isSelected = selectedIndex == index;

          final String formattedAssetName = subCat
              .toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll('/', '_')
              .replaceAll('â€™', '')
              .replaceAll('-', '_');

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF00A2FF), Color(0xFF16BCE6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF70C6E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/$formattedAssetName.png',
                        height: 40,
                        width: 40,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          isSelected ? Icons.check_circle : Icons.image,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subCat,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF113F67)
                          : const Color(0xFF00A2FF),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
