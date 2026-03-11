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

  final Color primaryDarkBlue = const Color(0xFF113F67);

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
              leading: Icon(Icons.camera_alt, color: primaryDarkBlue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryDarkBlue),
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

  // Helper widget for the custom Add Image Button
  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryDarkBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedImages.isEmpty
                  ? "Add Image"
                  : "Add Image (${_selectedImages.length}/3)",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Image.asset(
              'assets/icons/addimg_icon.png',
              height: 12,
              width: 12,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.add_photo_alternate,
                size: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 160,
                width: 330,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentOfferIndex = index);
                    },
                    itemCount: _selectedImages.isEmpty
                        ? 1
                        : _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        color: Colors.grey[200],
                        child: _selectedImages.isNotEmpty
                            ? Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "No Images",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),

              // Remove Image Button (Kept functionality but restyled subtly)
              if (_selectedImages.isNotEmpty)
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
                        size: 16,
                      ),
                    ),
                  ),
                ),

              // Add Image Button
              if (_selectedImages.length < 3)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildAddImageButton(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Custom Page Indicators
        if (_selectedImages.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _selectedImages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _currentOfferIndex ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: index == _currentOfferIndex
                      ? primaryDarkBlue
                      : const Color(0xFF00B0FF),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
