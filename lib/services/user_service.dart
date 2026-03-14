import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUserException implements Exception {
  const BlockedUserException([
    this.message = 'This account has been blocked. Please contact support.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String blockedAccountStatus = 'blocked';

  // Static cache for location to prevent redundant GPS pings across the app.
  static double? currentLat;
  static double? currentLng;

  /// Returns the current authenticated user's UID.
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Returns the current authenticated user's email.
  static String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  /// Creates a new user profile document in Firestore.
  static Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required String location,
    required double latitude,
    required double longitude,
    required String profileImageUrl,
  }) async {
    final String? uid = getCurrentUserId();
    if (uid == null) {
      throw Exception("User is not authenticated.");
    }

    await ensureCurrentUserCanPerformWrite();

    // Update local location cache
    currentLat = latitude;
    currentLng = longitude;

    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email.isNotEmpty ? email : getCurrentUserEmail(),
      'phone': phone,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

    return _normalizeUserData(
      doc.data() as Map<String, dynamic>,
      fallbackEmail: getCurrentUserEmail(),
    );
  }

  static Future<Map<String, dynamic>?> getCurrentUserDocument() async {
    final String? uid = getCurrentUserId();
    if (uid == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Map<String, dynamic>.from(doc.data()!);
  }

  static bool isUserBlocked(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final isBlocked = data['isBlocked'] == true;
    final accountStatus = normalizeAccountStatus(data['accountStatus']);
    return isBlocked || accountStatus == blockedAccountStatus;
  }

  static String normalizeAccountStatus(Object? value) {
    if (value is! String) {
      return '';
    }

    return value.trim().toLowerCase();
  }

  static Future<void> ensureCurrentUserCanPerformWrite() async {
    final profile = await getCurrentUserDocument();
    if (isUserBlocked(profile)) {
      throw const BlockedUserException();
    }
  }

  /// Retrieves a stream of the current user's profile for real-time UI updates.
  static Stream<Map<String, dynamic>?> getUserProfileStream() {
    final String? uid = getCurrentUserId();
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return _normalizeUserData(
          doc.data() as Map<String, dynamic>,
          fallbackEmail: getCurrentUserEmail(),
        );
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

    return _normalizeUserData(doc.data() as Map<String, dynamic>);
  }

  /// Retrieves all user profiles once for search and public profile discovery.
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final QuerySnapshot snapshot = await _firestore.collection('users').get();

    return snapshot.docs.map((doc) {
      final data = _normalizeUserData(doc.data() as Map<String, dynamic>);
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  /// Filters users against the entered query using case-insensitive name matching.
  static List<Map<String, dynamic>> filterUsersByQuery(
    List<Map<String, dynamic>> users,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    return users.where((user) {
      final name = user['name']?.toString().trim().toLowerCase() ?? '';
      return name.contains(normalizedQuery);
    }).toList();
  }

  /// Updates specific fields in the current user's profile.
  static Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? location,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final String? uid = getCurrentUserId();
    if (uid == null) {
      throw Exception("User is not authenticated.");
    }

    await ensureCurrentUserCanPerformWrite();

    final Map<String, dynamic> updateData = {};

    if (name != null && name.isNotEmpty) {
      updateData['name'] = name;
    }
    if (phone != null && phone.isNotEmpty) {
      updateData['phone'] = phone;
    }
    if (location != null && location.isNotEmpty) {
      updateData['location'] = location;
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
      await _firestore
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));
    }
  }

  static String getLocationLabel({
    String? location,
    double? latitude,
    double? longitude,
  }) {
    final normalizedLocation = location?.trim() ?? '';
    if (normalizedLocation.isNotEmpty) {
      return normalizedLocation;
    }

    if (latitude == null || longitude == null) {
      return '';
    }

    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static bool isProfileComplete(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final normalized = _normalizeUserData(
      data,
      fallbackEmail: getCurrentUserEmail(),
    );

    final name = normalized['name']?.toString().trim() ?? '';
    final email = normalized['email']?.toString().trim() ?? '';
    final phone = normalized['phone']?.toString().trim() ?? '';
    final location = normalized['location']?.toString().trim() ?? '';
    final latitude = normalized['latitude'];
    final longitude = normalized['longitude'];

    return name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        location.isNotEmpty &&
        latitude is double &&
        longitude is double;
  }

  static Map<String, dynamic> _normalizeUserData(
    Map<String, dynamic> data, {
    String fallbackEmail = '',
  }) {
    final normalized = Map<String, dynamic>.from(data);

    final latitudeValue = normalized['latitude'];
    if (latitudeValue is num) {
      currentLat = latitudeValue.toDouble();
      normalized['latitude'] = currentLat;
    }

    final longitudeValue = normalized['longitude'];
    if (longitudeValue is num) {
      currentLng = longitudeValue.toDouble();
      normalized['longitude'] = currentLng;
    }

    final storedEmail = normalized['email']?.toString().trim() ?? '';
    normalized['email'] = storedEmail.isNotEmpty ? storedEmail : fallbackEmail;
    normalized['phone'] = normalized['phone']?.toString().trim() ?? '';
    normalized['name'] = normalized['name']?.toString().trim() ?? '';
    normalized['profileImageUrl'] =
        normalized['profileImageUrl']?.toString().trim() ?? '';
    normalized['location'] = getLocationLabel(
      location: normalized['location']?.toString(),
      latitude: normalized['latitude'] as double?,
      longitude: normalized['longitude'] as double?,
    );
    normalized['accountStatus'] = normalizeAccountStatus(
      normalized['accountStatus'],
    );
    normalized['isBlocked'] = normalized['isBlocked'] == true;

    return normalized;
  }
}
