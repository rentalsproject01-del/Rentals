import 'dart:io';
import 'package:rentals/services/rental_service.dart';

class RentSubmitService {
  /// Acts as a logic bridge between the UI (RentPage) and the data layer (RentalService).
  /// Forwards the validated parameters directly to the central Firebase service.
  static Future<void> uploadRental({
    required String title,
    required String subtitle,
    required String description,
    required double deposit,
    required double price,
    required String duration,
    required String category,
    required String subcategory,
    required String location,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String email, // <-- ADDED EMAIL HERE
    required List<File> images,
  }) async {
    await RentalService.uploadRental(
      title: title,
      subtitle: subtitle,
      description: description,
      deposit: deposit,
      price: price,
      duration: duration,
      category: category,
      subcategory: subcategory,
      location: location,
      latitude: latitude,
      longitude: longitude,
      phoneNumber: phoneNumber,
      email: email, // <-- PASSED EMAIL HERE
      images: images,
    );
  }
}
