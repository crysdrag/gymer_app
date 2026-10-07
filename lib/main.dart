import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gymer_app/screens/scan_screen.dart';
import 'package:gymer_app/screens/timer_screen.dart';
import 'services/notification_service.dart';



// Handler cho tin nhắn background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Đảm bảo Firebase được khởi tạo trước khi dùng bất kỳ dịch vụ nào của nó
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Notification Service
  final notificationService = NotificationService();
  await notificationService.init();

  try {
    await Firebase.initializeApp();
    
    // Thiết lập background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Xin quyền thông báo (đặc biệt quan trọng từ Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    
    // Lấy Token FCM và log ra console
    String? token = await messaging.getToken();
    debugPrint("FCM Registration Token: $token");

    // Lắng nghe tin nhắn khi app đang ở foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.messageId}");
      if (message.data.isNotEmpty) {
        debugPrint("Message data: ${message.data}");
      }

      RemoteNotification? notification = message.notification;
      if (notification != null) {
        debugPrint("Notification Title: ${notification.title}");
        debugPrint("Notification Body: ${notification.body}");

        notificationService.showNotification(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          payload: message.data.toString(),
        );
      }
    });
    
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }

  runApp(const NutriGymApp());
}

class NutriGymApp extends StatelessWidget {
  const NutriGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriGym AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Nền xám nhạt cao cấp từ ảnh app trắng
        primaryColor: const Color(0xFF111827), // Tông màu xanh đen charcoal chủ đạo sang trọng
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827),
          surface: const Color(0xFFF3F4F6),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ScanScreen(),
    const TimerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),

        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF111827),
          unselectedItemColor: const Color(0xFF9CA3AF),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              activeIcon: Icon(Icons.qr_code_scanner, color: Color(0xFF111827)),
              label: 'Quét',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer, color: Color(0xFF111827)),
              label: 'Timer',
            ),
          ],
        ),
      ),
    );
  }
}

