import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_recognition_result.dart';
import '../services/ai/providers/roboflow_food_recognition_service.dart';

class AITestScreen extends StatefulWidget {
  const AITestScreen({super.key});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  List<FoodRecognitionResult> _results = [];
  
  // Đọc API Key từ môi trường
  final String _apiKey = const String.fromEnvironment('ROBOFLOW_API_KEY');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _results = [];
        _errorMessage = null;
      });
    }
  }

  Future<void> _runRecognition() async {
    if (_selectedImage == null) return;

    if (_apiKey.isEmpty) {
      setState(() {
        _errorMessage = "LỖI: ROBOFLOW_API_KEY chưa được cấu hình.\n"
            "Vui lòng chạy với: --dart-define=ROBOFLOW_API_KEY=your_key_here";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final service = RoboflowFoodRecognitionService(apiKey: _apiKey);
      final results = await service.recognizeIngredients(_selectedImage!);
      
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Test - Roboflow"),
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_apiKey.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.amber.shade100,
                child: const Text(
                  "Cảnh báo: API Key đang rỗng. Bạn cần cấu hình ROBOFLOW_API_KEY qua --dart-define.",
                  style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
            
            // Image Preview
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("Chưa chọn ảnh")),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Chọn ảnh"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedImage != null && !_isLoading ? _runRecognition : null,
                    icon: const Icon(Icons.psychology),
                    label: const Text("Nhận diện"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            else if (_results.isEmpty && _selectedImage != null)
              const Text("Không tìm thấy nguyên liệu nào.", textAlign: TextAlign.center)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final confidencePercent = (result.confidence * 100).toStringAsFixed(2);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.restaurant, color: Color(0xFF111827)),
                      title: Text(
                        result.foodName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        "$confidencePercent%",
                        style: TextStyle(
                          color: result.confidence >= 0.8 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
}
}
