import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RentImagePicker extends StatefulWidget {
  final Function(List<File>) onImagesChanged;

  const RentImagePicker({super.key, required this.onImagesChanged});

  @override
  State<RentImagePicker> createState() => RentImagePickerState();
}

class RentImagePickerState extends State<RentImagePicker> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  int _currentOfferIndex = 0;
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();
    _startOfferTimer();
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Exposed method for parent to reset images after successful upload
  void clearImages() {
    setState(() {
      _selectedImages.clear();
      _currentOfferIndex = 0;
    });
    widget.onImagesChanged(_selectedImages);
  }

  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_selectedImages.isEmpty) return;

      if (_currentOfferIndex < _selectedImages.length - 1) {
        _currentOfferIndex++;
      } else {
        _currentOfferIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentOfferIndex,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
          _currentOfferIndex = _selectedImages.length - 1;
        });
        widget.onImagesChanged(_selectedImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImagePickerOptions() {
    FocusScope.of(context).unfocus();
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only select up to 3 images.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0D3454)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF0D3454),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selectedImages.isEmpty ? _showImagePickerOptions : null,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF16BCE6), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: _selectedImages.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 45, color: Color(0xFF16BCE6)),
                  SizedBox(height: 8),
                  Text(
                    "Add up to 3 Images",
                    style: TextStyle(
                      color: Color(0xFF16BCE6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _selectedImages.length,
                      onPageChanged: (index) =>
                          setState(() => _currentOfferIndex = index),
                      itemBuilder: (context, index) {
                        return Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  // Page Indicators
                  if (_selectedImages.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_selectedImages.length, (
                          index,
                        ) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentOfferIndex == index
                                  ? const Color(0xFF16BCE6)
                                  : Colors.white70,
                            ),
                          );
                        }),
                      ),
                    ),
                  // Remove Image Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(_currentOfferIndex);
                          if (_currentOfferIndex >= _selectedImages.length &&
                              _currentOfferIndex > 0) {
                            _currentOfferIndex--;
                          }
                        });
                        widget.onImagesChanged(_selectedImages);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Add More Images Button
                  if (_selectedImages.length < 3)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16BCE6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
