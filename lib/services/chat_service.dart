import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:firebase_database/firebase_database.dart' as rtdb show Query;

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  static StreamSubscription<DatabaseEvent>? _presenceSubscription;

  /// Returns the current authenticated user's UID.
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Initializes user presence tracking (online status and last seen).
  static void initializePresence() {
    if (_presenceSubscription != null) return;

    final String? uid = getCurrentUserId();
    if (uid == null) return;

    final DatabaseReference statusRef = _db.ref().child('status/$uid');
    final DatabaseReference connectedRef = _db.ref().child('.info/connected');

    _presenceSubscription = connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;
      if (isConnected) {
        // Set up onDisconnect operations to run if the client drops connection
        statusRef
            .onDisconnect()
            .update({'isOnline': false, 'lastSeen': ServerValue.timestamp})
            .then((_) {
              // Once onDisconnect is queued, update current status to online
              statusRef.update({'isOnline': true});
            });
      }
    });
  }

  /// Cleans up the presence listener safely.
  static void cleanupPresence() {
    _presenceSubscription?.cancel();
    _presenceSubscription = null;
  }

  /// Manually sets the user offline (e.g., during logout).
  static Future<void> setUserOffline() async {
    final String? uid = getCurrentUserId();
    if (uid == null) return;

    await _db.ref().child('status/$uid').update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Retrieves a stream of another user's online status.
  static Stream<DatabaseEvent> getUserStatusStream(String uid) {
    return _db.ref().child('status/$uid').onValue;
  }

  /// Sets the typing status for the current user in a specific chat room.
  static Future<void> setTypingStatus(String chatRoomId, bool isTyping) async {
    final String? uid = getCurrentUserId();
    if (uid == null) return;

    final DatabaseReference typingRef = _db.ref().child(
      'typing/$chatRoomId/$uid',
    );

    if (isTyping) {
      await typingRef.set({
        'isTyping': true,
        'updatedAt': ServerValue.timestamp,
      });
    } else {
      await typingRef.remove();
    }
  }

  /// Retrieves a stream of a specific user's typing status in a chat room.
  static Stream<DatabaseEvent> getTypingStatusStream(
    String chatRoomId,
    String userId,
  ) {
    return _db.ref().child('typing/$chatRoomId/$userId').onValue;
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

    // Create the room document in Firestore
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

  /// Retrieves a stream of messages for a specific chat room from Realtime Database (Full snapshot stream).
  static Stream<DatabaseEvent> getMessages(String chatRoomId) {
    return _db
        .ref()
        .child('messages/$chatRoomId')
        .orderByChild('timestamp')
        .onValue;
  }

  /// Retrieves a Realtime Database Query for messages to allow incremental listening.
  static rtdb.Query getMessagesQuery(String chatRoomId) {
    return _db.ref().child('messages/$chatRoomId').orderByChild('timestamp');
  }

  /// Sends a message to Realtime Database and updates the parent chat room's latest message data in Firestore.
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

    // 1. Add message to the Realtime Database
    final DatabaseReference msgsRef = _db.ref().child('messages/$chatRoomId');
    final DatabaseReference newMessageRef = msgsRef.push();

    await newMessageRef.set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': trimmedText,
      'timestamp': ServerValue.timestamp,
      'isRead': false,
    });

    // 2. Update parent room in Firestore with the latest message details
    final DocumentReference roomRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

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
