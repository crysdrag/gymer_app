import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'screens/timer_screen.dart';

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
  int _currentTab = 1; // Mặc định là tab Quét

  // Hàm chuyển đổi nội dung body dựa trên tab
  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 64, color: Color(0xFF111827)),
              const SizedBox(height: 24),
              const Text(
                'MÀN HÌNH CHÍNH',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  NotificationService().showNotification(
                    title: "Gymer",
                    body: "Đây là thông báo kiểm tra Local Notification.",
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Test Notification', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TimerScreen()),
                  );
                },
                icon: const Icon(Icons.timer),
                label: const Text('Timer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      case 1:
        return const CameraScanContent();
      default:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Color(0xFF9CA3AF)),
              SizedBox(height: 16),
              Text(
                'Tính năng đang phát triển',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text('Vui lòng quay lại sau!', style: TextStyle(color: Color(0xFF9CA3AF))),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER BAR (Giữ cố định)
            const AppHeader(),

            // 2. DYNAMIC BODY (Thay đổi theo tab)
            Expanded(child: _buildBody()),

            // 3. BOTTOM NAVIGATION BAR (Giữ cố định)
            const SizedBox(height: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, "Home"),
                  _buildNavItem(1, Icons.qr_code_scanner, "Quét"),
                  _buildNavItem(2, Icons.cookie_outlined, "Nấu ăn"),
                  _buildNavItem(3, Icons.insights_outlined, "Vóc dáng"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget Header tách biệt
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NUTRIGYM AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Quét Nguyên Liệu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, color: Color(0xFF111827)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// Nội dung chính của màn hình Quét
class CameraScanContent extends StatefulWidget {
  const CameraScanContent({super.key});

  @override
  State<CameraScanContent> createState() => _CameraScanContentState();
}

class _CameraScanContentState extends State<CameraScanContent> {
  bool _isFlashOn = false;

  void _simulateCapture() {
    // Logic 2: Kích hoạt camera (Giả lập bằng SnackBar và hiệu ứng Haptic)
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.white),
            SizedBox(width: 12),
            Text('Đang kích hoạt Camera'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF111827),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRecipesDialog() {
    // Logic 3: Popup danh sách công thức
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            const Text(
              'CÔNG THỨC GỢI Ý',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 30, height: 2, color: const Color(0xFFE5E7EB)),
          ],
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // Màu xám sáng rõ rệt như ý bạn (Light Grey giống nền App)
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2), // Cạnh dọc mỏng đúng 2px
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2), // Cạnh dọc mỏng đúng 2px
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildRecipeItem("🍗 Ức gà áp chảo sốt cam", "450 kcal • 20 phút", "Cao Protein"),
              _buildRecipeItem("🥗 Salad gà & bông cải xanh", "320 kcal • 15 phút", "Ít Carbs"),
              _buildRecipeItem("🍲 Soup gà rau củ giải nhiệt", "280 kcal • 30 phút", "Dễ tiêu hóa"),
              _buildRecipeItem("🌯 Wrap gà ngũ cốc", "380 kcal • 10 phút", "Năng lượng nhanh"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem(String title, String info, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Nền item màu trắng để nổi bật trên nền xám sáng của popup
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(info, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(6)),
            child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNutritionDetailDialog(String title, List<Map<String, String>> items) {
    // Logic 4: Popup chi tiết dinh dưỡng
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'CHI TIẾT ${title.toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // Màu xám sáng rõ rệt như ý bạn (Light Grey giống nền App)
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2), // Cạnh dọc mỏng đúng 2px
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2), // Cạnh dọc mỏng đúng 2px
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name']!, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                  Text(item['value']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HIỂU RỒI', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Status Pill Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI VISION 4.2 • SẴN SÀNG',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF111827), letterSpacing: 0.5),
                ),
                const Spacer(),
                const Icon(Icons.videocam_outlined, color: Color(0xFF6B7280), size: 18),
                const SizedBox(width: 12),
                const Icon(Icons.close, color: Color(0xFF6B7280), size: 18),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Khối Camera
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE5E7EB), Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant_outlined, size: 80, color: Color(0xFFD1D5DB)),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.image_outlined, color: Color(0xFF111827), size: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('GALLERY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _simulateCapture,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF111827), width: 3),
                              ),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(color: Color(0xFF111827), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFF4B5563), size: 14),
                                  const SizedBox(width: 4),
                                  const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('AUTO-DETECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                                      Text('60 FPS', style: TextStyle(fontSize: 8, color: Color(0xFF6B7280))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Khối kết quả
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Đã nhận diện', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                          child: const Text('CHỈNH SỬA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text("🍗 Ức gà (200g)", style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 12),
                          Text("🥦 Bông cải xanh (100g)", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutritionClickable(
                          label: "NĂNG LƯỢNG", value: "320", unit: "KCAL",
                          onTap: () => _showNutritionDetailDialog("Năng lượng", [
                            {"name": "Ức gà (200g)", "value": "270 kcal"},
                            {"name": "Bông cải xanh", "value": "50 kcal"},
                            {"name": "Tổng cộng", "value": "320 kcal"},
                          ]),
                        ),
                        _buildNutritionClickable(
                          label: "PROTEIN", value: "48g", unit: "HIGH",
                          onTap: () => _showNutritionDetailDialog("Protein", [
                            {"name": "Ức gà (200g)", "value": "46g"},
                            {"name": "Bông cải xanh", "value": "2g"},
                          ]),
                        ),
                        _buildNutritionClickable(
                          label: "CARBS", value: "14g", unit: "CLEAN",
                          onTap: () => _showNutritionDetailDialog("Carbs", [
                            {"name": "Ức gà (200g)", "value": "0g"},
                            {"name": "Bông cải xanh", "value": "14g"},
                          ]),
                        ),
                        _buildNutritionClickable(
                          label: "CHẤT BÉO", value: "9g", unit: "FIT",
                          onTap: () => _showNutritionDetailDialog("Chất béo", [
                            {"name": "Ức gà (200g)", "value": "8g"},
                            {"name": "Bông cải xanh", "value": "1g"},
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _showRecipesDialog,
                        child: const Text('Tạo công thức phù hợp', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionClickable({required String label, required String value, required String unit, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                Text(unit, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
