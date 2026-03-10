import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Static cache for location to prevent redundant GPS pings across the app.
  static double? currentLat;
  static double? currentLng;

  /// Returns the current authenticated user's UID.
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Creates a new user profile document in Firestore.
  static Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required double latitude,
    required double longitude,
    required String profileImageUrl,
  }) async {
    final String? uid = getCurrentUserId();
    if (uid == null) {
      throw Exception("User is not authenticated.");
    }

    // Update local location cache
    currentLat = latitude;
    currentLng = longitude;

    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Retrieves the current user's profile data as a Future.
  /// Safely parses latitude and longitude from num to double.
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final String? uid = getCurrentUserId();
    if (uid == null) return null;

    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely parse coordinates to avoid type casting errors (int vs double in Firestore)
    if (data['latitude'] != null) {
      currentLat = (data['latitude'] as num).toDouble();
      data['latitude'] = currentLat;
    }

    if (data['longitude'] != null) {
      currentLng = (data['longitude'] as num).toDouble();
      data['longitude'] = currentLng;
    }

    return data;
  }

  /// Retrieves a stream of the current user's profile for real-time UI updates.
  static Stream<Map<String, dynamic>?> getUserProfileStream() {
    final String? uid = getCurrentUserId();
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Keep the cache updated if the stream emits new location data
        if (data['latitude'] != null) {
          currentLat = (data['latitude'] as num).toDouble();
        }
        if (data['longitude'] != null) {
          currentLng = (data['longitude'] as num).toDouble();
        }

        return data;
      }
      return null;
    });
  }

  /// Retrieves an arbitrary user's profile by UID.
  static Future<Map<String, dynamic>?> getUserById(String uid) async {
    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safe conversion for arbitrary user reads as well
    if (data['latitude'] != null) {
      data['latitude'] = (data['latitude'] as num).toDouble();
    }
    if (data['longitude'] != null) {
      data['longitude'] = (data['longitude'] as num).toDouble();
    }

    return data;
  }

  /// Updates specific fields in the current user's profile.
  static Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final String? uid = getCurrentUserId();
    if (uid == null) {
      throw Exception("User is not authenticated.");
    }

    final Map<String, dynamic> updateData = {};

    if (name != null && name.isNotEmpty) {
      updateData['name'] = name;
    }
    if (phone != null && phone.isNotEmpty) {
      updateData['phone'] = phone;
    }
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      updateData['profileImageUrl'] = profileImageUrl;
    }
    if (latitude != null) {
      updateData['latitude'] = latitude;
      currentLat = latitude;
    }
    if (longitude != null) {
      updateData['longitude'] = longitude;
      currentLng = longitude;
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(updateData);
    }
  }
}
