import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:firebase_database/firebase_database.dart' as rtdb show Query;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:rentals/services/user_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static StreamSubscription<DatabaseEvent>? _presenceSubscription;

  static const String textMessageType = 'text';
  static const String imageMessageType = 'image';

  static bool isMessageRead(Map<String, dynamic> messageData) {
    return messageData['isRead'] == true;
  }

  static bool shouldMarkMessageAsRead({
    required Map<String, dynamic> messageData,
    required String currentUserId,
    required String otherUserId,
  }) {
    final senderId = messageData['senderId']?.toString() ?? '';
    final receiverId = messageData['receiverId']?.toString() ?? '';

    return senderId == otherUserId &&
        receiverId == currentUserId &&
        !isMessageRead(messageData);
  }

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

    await UserService.ensureCurrentUserCanPerformWrite();

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
    return [itemId, ownerId, renterId].join('_');
  }

  /// Creates a new chat room if it doesn't exist, or returns the existing room ID.
  static Future<String> createOrGetChatRoom({
    required Map<String, dynamic> rentalData,
    required Map<String, dynamic> ownerData,
    required Map<String, dynamic> renterData,
  }) async {
    await UserService.ensureCurrentUserCanPerformWrite();

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

    final DocumentReference<Map<String, dynamic>> roomRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId);

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

    final roomData = <String, dynamic>{
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
    };

    // Avoid a protected pre-read; merge preserves existing room state when the
    // deterministic room already exists.
    await roomRef.set(roomData, SetOptions(merge: true));

    return chatRoomId;
  }

  /// Retrieves a stream of all chat rooms for the current user.
  ///
  /// We merge `ownerId` and `renterId` queries instead of relying on the
  /// `participants` array so legacy room documents can still be discovered.
  static Stream<List<Map<String, dynamic>>> getUserChatRooms() {
    final String? uid = getCurrentUserId();
    if (uid == null) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    late final StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? ownerSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? renterSubscription;

    QuerySnapshot<Map<String, dynamic>>? ownerSnapshot;
    QuerySnapshot<Map<String, dynamic>>? renterSnapshot;

    int millisFromValue(Object? value) {
      if (value is Timestamp) {
        return value.millisecondsSinceEpoch;
      }
      if (value is DateTime) {
        return value.millisecondsSinceEpoch;
      }
      if (value is int) {
        return value;
      }
      return 0;
    }

    void emitMergedRooms() {
      final mergedRooms = <String, Map<String, dynamic>>{};

      for (final snapshot in [ownerSnapshot, renterSnapshot]) {
        if (snapshot == null) {
          continue;
        }

        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          final existingChatRoomId =
              data['chatRoomId']?.toString().trim() ?? '';
          if (existingChatRoomId.isEmpty) {
            data['chatRoomId'] = doc.id;
          }
          mergedRooms[doc.id] = data;
        }
      }

      final rooms = mergedRooms.values.toList()
        ..sort((a, b) {
          final updatedAtDiff = millisFromValue(
            b['updatedAt'],
          ).compareTo(millisFromValue(a['updatedAt']));
          if (updatedAtDiff != 0) {
            return updatedAtDiff;
          }

          return millisFromValue(
            b['lastMessageTime'],
          ).compareTo(millisFromValue(a['lastMessageTime']));
        });

      controller.add(rooms);
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        ownerSubscription = _firestore
            .collection('chat_rooms')
            .where('ownerId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
              ownerSnapshot = snapshot;
              emitMergedRooms();
            }, onError: controller.addError);

        renterSubscription = _firestore
            .collection('chat_rooms')
            .where('renterId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
              renterSnapshot = snapshot;
              emitMergedRooms();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await ownerSubscription?.cancel();
        await renterSubscription?.cancel();
      },
    );

    return controller.stream;
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
    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    await UserService.ensureCurrentUserCanPerformWrite();

    await _sendChatMessage(
      chatRoomId: chatRoomId,
      receiverId: receiverId,
      messageType: textMessageType,
      text: trimmedText,
      imageUrl: '',
      roomPreview: trimmedText,
    );
  }

  static Future<void> sendImageMessage({
    required String chatRoomId,
    required File imageFile,
    required String receiverId,
  }) async {
    await UserService.ensureCurrentUserCanPerformWrite();

    final String imageUrl = await _uploadChatImage(
      chatRoomId: chatRoomId,
      imageFile: imageFile,
    );

    await _sendChatMessage(
      chatRoomId: chatRoomId,
      receiverId: receiverId,
      messageType: imageMessageType,
      text: '',
      imageUrl: imageUrl,
      roomPreview: 'Photo',
    );
  }

  static Future<String> _uploadChatImage({
    required String chatRoomId,
    required File imageFile,
  }) async {
    final String? currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('User is not authenticated.');
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$currentUserId.jpg';
    final Reference ref = _storage.ref().child(
      'chat_images/$chatRoomId/$fileName',
    );

    final TaskSnapshot uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return uploadTask.ref.getDownloadURL();
  }

  static Future<void> _sendChatMessage({
    required String chatRoomId,
    required String receiverId,
    required String messageType,
    required String text,
    required String imageUrl,
    required String roomPreview,
  }) async {
    final String? currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('User is not authenticated.');
    }

    final DatabaseReference msgsRef = _db.ref().child('messages/$chatRoomId');
    final DatabaseReference newMessageRef = msgsRef.push();

    await newMessageRef.set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'messageType': messageType,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': ServerValue.timestamp,
      'isRead': false,
    });

    unawaited(
      _syncChatRoomPreview(
        chatRoomId: chatRoomId,
        currentUserId: currentUserId,
        roomPreview: roomPreview,
      ),
    );
  }

  static Future<void> _syncChatRoomPreview({
    required String chatRoomId,
    required String currentUserId,
    required String roomPreview,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> roomRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId);

      await roomRef.set({
        'lastMessage': roomPreview,
        'lastMessageSenderId': currentUserId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('Failed to sync chat room preview: $e\n$st');
    }
  }

  static Future<void> markMessagesAsRead({
    required String chatRoomId,
    required Iterable<String> messageKeys,
  }) async {
    final keys = messageKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList();

    if (keys.isEmpty) {
      return;
    }

    final updates = <String, Object?>{};
    for (final key in keys) {
      updates['messages/$chatRoomId/$key/isRead'] = true;
    }

    await _db.ref().update(updates);
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

  static Future<Map<String, dynamic>?> resolveChatRoomNavigationData({
    required String chatRoomId,
    required String currentUserId,
  }) async {
    final roomData = await getChatRoom(chatRoomId);
    if (roomData == null) {
      return null;
    }

    final ownerId = roomData['ownerId']?.toString() ?? '';
    final renterId = roomData['renterId']?.toString() ?? '';
    final isOwner = currentUserId == ownerId;

    final otherUserId = isOwner ? renterId : ownerId;
    final otherUserName = isOwner
        ? roomData['renterName']?.toString() ?? 'Unknown User'
        : roomData['ownerName']?.toString() ?? 'Unknown User';
    final otherUserImage = isOwner
        ? roomData['renterImage']?.toString() ?? ''
        : roomData['ownerImage']?.toString() ?? '';

    return {
      'chatRoomId': chatRoomId,
      'currentUserId': currentUserId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserImage': otherUserImage,
      'itemTitle': roomData['itemTitle']?.toString() ?? 'Item Inquiry',
      'itemImage': roomData['itemImage']?.toString() ?? '',
    };
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getChatRoomsForItem(String rentalId) async {
    final snapshot = await _firestore
        .collection('chat_rooms')
        .where('itemId', isEqualTo: rentalId)
        .get();

    return snapshot.docs;
  }

  static Future<void> deleteChatRoomsAndMessagesForItem(
    String rentalId, {
    WriteBatch? batch,
  }) async {
    final roomDocs = await getChatRoomsForItem(rentalId);
    if (roomDocs.isEmpty) {
      return;
    }

    final WriteBatch deletionBatch = batch ?? _firestore.batch();
    final Map<String, Object?> rtdbDeletes = {};

    for (final roomDoc in roomDocs) {
      deletionBatch.delete(roomDoc.reference);
      final roomId = roomDoc.id;
      rtdbDeletes['messages/$roomId'] = null;
      rtdbDeletes['typing/$roomId'] = null;
    }

    if (rtdbDeletes.isNotEmpty) {
      await _db.ref().update(rtdbDeletes);
    }

    if (batch == null) {
      await deletionBatch.commit();
    }
  }
}
