import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../services/ai/meal_recommendation_service.dart';
import '../services/ai/providers/roboflow_food_recognition_service.dart';
import '../services/ai/providers/themealdb_recipe_service.dart';

// Nội dung chính của màn hình Quét
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isFlashOn = false;
  bool _isLoading = false;
  File? _selectedImage;
  List<Recipe> _recommendedRecipes = [];
  List<String> _detectedIngredients = [];

  // Khởi tạo AI Services
  late final MealRecommendationService _recommendationService;

  @override
  void initState() {
    super.initState();
    _recommendationService = MealRecommendationService(
      foodRecognitionService: RoboflowFoodRecognitionService(
        apiKey: const String.fromEnvironment('ROBOFLOW_API_KEY'),      ),
      recipeService: TheMealDBRecipeService(),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
        _recommendedRecipes = [];
        _detectedIngredients = [];
      });

      try {
        // Gọi service nhận diện và gợi ý (Chỉ gọi 1 lần duy nhất)
        final result = await _recommendationService.recommendMeals(_selectedImage!);

        if (!mounted) return;

        setState(() {
          _recommendedRecipes = result.recipes;
          _detectedIngredients = result.recognizedIngredients
              .map((r) => r.foodName)
              .toList();
          _isLoading = false;
        });

        if (_recommendedRecipes.isNotEmpty) {
          _showRecipesDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy nguyên liệu hoặc công thức phù hợp')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }


  void _simulateCapture() {
    _pickImage(ImageSource.camera);
  }

  void _pickFromGallery() {
    _pickImage(ImageSource.gallery);
  }

  void _showRecipesDialog() {
    if (_recommendedRecipes.isEmpty) return;

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
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recommendedRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _recommendedRecipes[index];
              return _buildRecipeItem(
                recipe.name,
                "${recipe.durationMinutes ?? '??'} phút • ${recipe.ingredients.length} nguyên liệu",
                index == 0 ? "Phù hợp nhất" : "Gợi ý",
              );
            },
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
                      child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.restaurant_outlined, size: 80, color: Color(0xFFD1D5DB)),
                          ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
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
                              child: GestureDetector(
                                onTap: _pickFromGallery,
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
                        if (_recommendedRecipes.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                            child: const Text('CHỈNH SỬA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _detectedIngredients.isEmpty
                          ? [const Text("Vui lòng quét để nhận diện", style: TextStyle(color: Colors.grey, fontSize: 13))]
                          : _detectedIngredients.map((ing) => Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Text("• $ing", style: const TextStyle(fontWeight: FontWeight.w600)),
                            )).toList(),
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
