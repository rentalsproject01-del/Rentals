import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current authenticated user's UID.
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Returns a deterministic chat room ID based on the item, owner, and renter.
  static String getChatRoomId({
    required String itemId,
    required String ownerId,
    required String renterId,
  }) {
    return '${itemId}_${ownerId}_${renterId}';
  }

  /// Creates a new chat room if it doesn't exist, or returns the existing room ID.
  static Future<String> createOrGetChatRoom({
    required Map<String, dynamic> rentalData,
    required Map<String, dynamic> ownerData,
    required Map<String, dynamic> renterData,
  }) async {
    final String itemId = rentalData['id']?.toString() ?? '';

    // Safely resolve owner and renter IDs (handling common key variations like 'uid' or 'id')
    final String ownerId =
        ownerData['uid']?.toString() ?? ownerData['id']?.toString() ?? '';
    final String renterId =
        renterData['uid']?.toString() ?? renterData['id']?.toString() ?? '';

    if (itemId.isEmpty || ownerId.isEmpty || renterId.isEmpty) {
      throw Exception(
        'Missing required IDs (itemId, ownerId, or renterId) to initialize chat.',
      );
    }

    final String chatRoomId = getChatRoomId(
      itemId: itemId,
      ownerId: ownerId,
      renterId: renterId,
    );

    final DocumentReference roomRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);
    final DocumentSnapshot roomSnap = await roomRef.get();

    if (roomSnap.exists) {
      return chatRoomId;
    }

    // Safely extract the item image
    String itemImage = '';
    if (rentalData['imageUrls'] != null) {
      if (rentalData['imageUrls'] is List &&
          (rentalData['imageUrls'] as List).isNotEmpty) {
        itemImage = rentalData['imageUrls'][0].toString();
      } else if (rentalData['imageUrls'] is String &&
          rentalData['imageUrls'].toString().isNotEmpty) {
        itemImage = rentalData['imageUrls'].toString();
      }
    }

    // Create the room document
    await roomRef.set({
      'chatRoomId': chatRoomId,
      'itemId': itemId,
      'itemTitle': rentalData['title']?.toString() ?? 'Unknown Item',
      'itemImage': itemImage,
      'ownerId': ownerId,
      'ownerName': ownerData['name']?.toString() ?? 'Unknown Owner',
      'ownerImage': ownerData['profileImageUrl']?.toString() ?? '',
      'renterId': renterId,
      'renterName': renterData['name']?.toString() ?? 'Unknown Renter',
      'renterImage': renterData['profileImageUrl']?.toString() ?? '',
      'participants': [ownerId, renterId],
      'lastMessage': '',
      'lastMessageSenderId': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return chatRoomId;
  }

  /// Retrieves a stream of all chat rooms the current user is a participant in.
  static Stream<QuerySnapshot> getUserChatRooms() {
    final String? uid = getCurrentUserId();
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Retrieves a stream of messages for a specific chat room.
  static Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Sends a message and updates the parent chat room's latest message data.
  static Future<void> sendMessage({
    required String chatRoomId,
    required String text,
    required String receiverId,
  }) async {
    final String? currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('User is not authenticated.');
    }

    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final DocumentReference roomRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

    // 1. Add message to the subcollection
    await roomRef.collection('messages').add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': trimmedText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2. Update parent room with the latest message details
    await roomRef.update({
      'lastMessage': trimmedText,
      'lastMessageSenderId': currentUserId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Retrieves the raw data of a specific chat room if it exists.
  static Future<Map<String, dynamic>?> getChatRoom(String chatRoomId) async {
    final DocumentSnapshot doc = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .get();

    if (doc.exists && doc.data() != null) {
      return Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
