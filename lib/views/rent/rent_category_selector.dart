import 'package:flutter/material.dart';

class RentCategorySelector extends StatefulWidget {
  final TextEditingController categoryController;
  final TextEditingController subcategoryController;

  const RentCategorySelector({
    super.key,
    required this.categoryController,
    required this.subcategoryController,
  });

  @override
  State<RentCategorySelector> createState() => _RentCategorySelectorState();
}

class _RentCategorySelectorState extends State<RentCategorySelector> {
  final Map<String, List<String>> _categoriesMap = {
    'Fashion': ['Jacket', 'Dress', 'Kurta/Kurti', 'Footwear', 'Scarf', 'Other'],
    'Jewellery': [
      'Necklace',
      'Earrings',
      'Anklet',
      'Bangles/Bracelets',
      'Bridal set',
      'Other',
    ],
    'Vehicle': [
      'Cars',
      'Bike',
      'Scooter',
      'Bicycle',
      'Electric Bike/Scooter',
      'Other',
    ],
    'House': [
      'Apartment/Flat',
      'Independant Houses',
      'Rooms',
      'PG/Hostel',
      'Commerical Space',
      'Other',
    ],
    'Electronics': [
      'Speaker',
      'Camera',
      'Projector',
      'Laptop/Phone',
      'Watch',
      'Other',
    ],
    'Books': [
      'Story/Poetry',
      'Academic book',
      'Fiction Novel',
      'Non-Fictional',
      'Children’s book',
      'Other',
    ],
    'Game': [
      'VR Headset',
      'Playstation',
      'Gaming Console',
      'Game Equipment',
      'Other',
    ],
    'GYM': ['Dumbbells', 'yoga mats', 'gym equipment', 'Other'],
    'Travel': [
      'Bags',
      'Camping Tent',
      'Sleeping Bags',
      'Portable Stoves',
      'Water Bottles/Thermos',
      'Other',
    ],
    'Decore': [
      'Lights',
      'Artificial Flowers/plants',
      'theme party props',
      'Stage',
      'Mandap decore',
      'Other',
    ],
    'Furniture': [
      'Mattress',
      'Rack/Cabinet',
      'Folding Table/chairs',
      'Bench',
      'Baby Crib',
      'Other',
    ],
    'Subscription': [
      'OTT/Streaming',
      'Music',
      'Gaming',
      'Education',
      'Software/Tool',
      'Other',
    ],
    'Other': ['Other'],
  };

  late String _selectedCategory;
  late String _selectedSubcategory;

  final Color primaryDarkBlue = const Color(0xFF113F67);
  final Color lightFillColor = const Color(0xFFE5F4F9);

  @override
  void initState() {
    super.initState();
    if (_categoriesMap.containsKey(widget.categoryController.text)) {
      _selectedCategory = widget.categoryController.text;
    } else {
      _selectedCategory = 'Fashion';
      widget.categoryController.text = 'Fashion';
    }

    _selectedSubcategory = _categoriesMap[_selectedCategory]!.first;
    widget.subcategoryController.text = _selectedSubcategory;
  }

  @override
  Widget build(BuildContext context) {
    // Replaced the Row with a Column to match the updated UI layout
    return Column(
      children: [_buildCategoryDropdown(), _buildSubcategoryDropdown()],
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        isExpanded: true,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: lightFillColor,
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/category_icon.png',
                  height: 14,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.category, size: 14, color: primaryDarkBlue),
                ),
                const SizedBox(width: 7),
                Text(
                  "Category : ",
                  style: TextStyle(
                    color: primaryDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.5),
          ),
        ),
        icon: Icon(Icons.keyboard_arrow_down, color: primaryDarkBlue, size: 24),
        items: _categoriesMap.keys.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCategory = newValue;
              widget.categoryController.text = newValue;
              _selectedSubcategory = _categoriesMap[newValue]!.first;
              widget.subcategoryController.text = _selectedSubcategory;
            });
          }
        },
      ),
    );
  }

  Widget _buildSubcategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _selectedSubcategory,
        isExpanded: true,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: lightFillColor,
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/subcategory_icon.png',
                  height: 14,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_tree,
                    size: 14,
                    color: primaryDarkBlue,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  "Subcategory : ",
                  style: TextStyle(
                    color: primaryDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.5),
          ),
        ),
        icon: Icon(Icons.keyboard_arrow_down, color: primaryDarkBlue, size: 24),
        items: _categoriesMap[_selectedCategory]!.map((String subcategory) {
          return DropdownMenuItem<String>(
            value: subcategory,
            child: Text(subcategory, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedSubcategory = newValue;
              widget.subcategoryController.text = newValue;
            });
          }
        },
      ),
    );
  }
}
