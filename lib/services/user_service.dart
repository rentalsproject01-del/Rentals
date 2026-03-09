import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Location cache variables
  static double? currentLat;
  static double? currentLng;

  /// Retrieves the current authenticated user's ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Streams the current user's profile data
  static Stream<Map<String, dynamic>?> getUserProfileStream() {
    final uid = getCurrentUserId();
    if (uid == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        // Fixed: Removed the unnecessary 'as Map<String, dynamic>?' cast
        return doc.data();
      }
      return null;
    });
  }

  /// Creates a new user profile document in Firestore
  static Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required double latitude,
    required double longitude,
    required String profileImageUrl,
  }) async {
    try {
      final uid = getCurrentUserId();
      if (uid == null) throw Exception("User not authenticated");

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      // Update location cache
      currentLat = latitude;
      currentLng = longitude;
    } on FirebaseException catch (e) {
      throw Exception("Failed to create user profile: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  /// Fetches the current user's profile data as a Future
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final uid = getCurrentUserId();
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // Sync location cache
          currentLat = data['latitude'] as double?;
          currentLng = data['longitude'] as double?;
        }
        return data;
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception("Failed to get user profile: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  /// Fetches any user's profile data by their UID
  static Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception("Failed to get user profile: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  /// Updates specific fields of the current user's profile
  static Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uid = getCurrentUserId();
      if (uid == null) throw Exception("User not authenticated");

      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;

      if (latitude != null) {
        updateData['latitude'] = latitude;
        currentLat = latitude; // Update cache
      }
      if (longitude != null) {
        updateData['longitude'] = longitude;
        currentLng = longitude; // Update cache
      }

      await _firestore.collection('users').doc(uid).update(updateData);
    } on FirebaseException catch (e) {
      throw Exception("Failed to update user profile: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }
}
