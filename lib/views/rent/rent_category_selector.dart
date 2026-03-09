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
    return Row(
      children: [
        Expanded(child: _buildCategoryDropdown()),
        const SizedBox(width: 15),
        Expanded(child: _buildSubcategoryDropdown()),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: "Category",
        labelStyle: TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
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
    );
  }

  Widget _buildSubcategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSubcategory,
      decoration: const InputDecoration(
        labelText: "Subcategory",
        labelStyle: TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
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
    );
  }
}
