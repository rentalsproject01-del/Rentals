import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rentals/firebase_options.dart';

import 'package:rentals/widgets/navbar.dart';
import 'package:rentals/views/auth/login_page.dart';
import 'package:rentals/views/auth/blocked_account_page.dart';
import 'package:rentals/views/profile/account_setup_page.dart';
import 'package:rentals/views/my_rentals/myrent_page.dart';
import 'package:rentals/views/chat/chat_room_page.dart'; // Added chat room import
import 'package:rentals/services/chat_service.dart';
import 'package:rentals/services/user_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF113F67)),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _tokenRefreshUserId;
  String? _blockedSessionHandledUserId;
  bool _notificationTapListenersInitialized = false;
  bool _isNavigationReady = false;
  RemoteMessage? _pendingNavigationMessage;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeNotificationTapHandling();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  Future<void> _saveFcmToken(String uid) async {
    if (_tokenRefreshUserId == uid) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _tokenRefreshUserId = uid;

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('FCM token refresh save failed: $e');
        }
      });
    } catch (e) {
      debugPrint('Saving FCM token failed: $e');
    }
  }

  void _syncAuthenticatedUser(User? user) {
    if (user == null) {
      _tokenRefreshUserId = null;
      _blockedSessionHandledUserId = null;
      _isNavigationReady = false;
      return;
    }
  }

  void _handleBlockedSession(User user) {
    if (_blockedSessionHandledUserId == user.uid) {
      return;
    }

    _blockedSessionHandledUserId = user.uid;
    _pendingNavigationMessage = null;
    _isNavigationReady = false;
    ChatService.cleanupPresence();
    unawaited(ChatService.setUserOffline());
  }

  Future<void> _signOutBlockedUser() async {
    _pendingNavigationMessage = null;
    _isNavigationReady = false;
    ChatService.cleanupPresence();

    try {
      await ChatService.setUserOffline();
    } catch (e) {
      debugPrint('Setting blocked user offline failed: $e');
    }

    await FirebaseAuth.instance.signOut();
  }

  Future<void> _initializeNotificationTapHandling() async {
    if (_notificationTapListenersInitialized) return;
    _notificationTapListenersInitialized = true;

    try {
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        _pendingNavigationMessage = initialMessage;
      }

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _pendingNavigationMessage = message;
        _tryHandlePendingNotificationNavigation();
      });
    } catch (e) {
      debugPrint('Notification tap handling initialization failed: $e');
    }
  }

  void _tryHandlePendingNotificationNavigation() {
    if (_pendingNavigationMessage == null) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    if (!_isNavigationReady) return;
    if (appNavigatorKey.currentState == null) return;

    final RemoteMessage message = _pendingNavigationMessage!;
    _pendingNavigationMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromNotification(message);
    });
  }

  Future<void> _routeFromNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type']?.toString() ?? '';
    final transactionId = data['transactionId']?.toString();

    if (type == 'rental_request_sent') {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MyrentPage(
            initialHostMode: true,
            initialTransactionId: transactionId,
          ),
        ),
      );
      return;
    }

    if (type == 'rental_request_accepted' ||
        type == 'rental_request_rejected') {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MyrentPage(
            initialHostMode: false,
            initialTransactionId: transactionId,
          ),
        ),
      );
      return;
    }

    // --- NEW: Handle Chat Push Notifications ---
    if (type == 'chat_message') {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentUserId = currentUser.uid;
      final chatRoomId = data['chatRoomId']?.toString() ?? '';
      if (chatRoomId.isEmpty) return;

      final resolvedData = await ChatService.resolveChatRoomNavigationData(
        chatRoomId: chatRoomId,
        currentUserId: currentUserId,
      );

      final otherUserId =
          resolvedData?['otherUserId']?.toString() ??
          data['otherUserId']?.toString() ??
          '';
      if (otherUserId.isEmpty) return;

      final otherUserName =
          resolvedData?['otherUserName']?.toString() ??
          data['otherUserName']?.toString() ??
          'Unknown User';
      final otherUserImage =
          resolvedData?['otherUserImage']?.toString() ??
          data['otherUserImage']?.toString() ??
          '';
      final itemTitle =
          resolvedData?['itemTitle']?.toString() ??
          data['itemTitle']?.toString() ??
          'Item Inquiry';
      final itemImage =
          resolvedData?['itemImage']?.toString() ??
          data['itemImage']?.toString() ??
          '';

      if (!mounted) return;

      appNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            chatRoomId: chatRoomId,
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserImage: otherUserImage,
            itemTitle: itemTitle,
            itemImage: itemImage,
          ),
        ),
      );
      return;
    }

    debugPrint('Unhandled notification type: $type');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = authSnapshot.data;
        _syncAuthenticatedUser(user);

        if (user == null) {
          return const LoginPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, firestoreSnapshot) {
            if (firestoreSnapshot.connectionState == ConnectionState.waiting &&
                !firestoreSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (firestoreSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text("Error loading profile. Please try again."),
                ),
              );
            }

            final Map<String, dynamic>? userData =
                firestoreSnapshot.hasData &&
                    firestoreSnapshot.data?.data() != null
                ? Map<String, dynamic>.from(firestoreSnapshot.data!.data()!)
                : null;

            if (UserService.isUserBlocked(userData)) {
              _handleBlockedSession(user);
              return BlockedAccountPage(onSignOut: _signOutBlockedUser);
            }

            _blockedSessionHandledUserId = null;

            if (userData != null) {
              _saveFcmToken(user.uid);
            }

            if (UserService.isProfileComplete(userData)) {
              _isNavigationReady = true;
              _tryHandlePendingNotificationNavigation();
              return const Navbar();
            }

            _isNavigationReady = false;
            return const AccountSetupPage();
          },
        );
      },
    );
  }
}
