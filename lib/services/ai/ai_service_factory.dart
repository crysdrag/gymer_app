import 'food_recognition_service.dart';
import 'providers/roboflow_food_recognition_service.dart';

class AIServiceFactory {
  static FoodRecognitionService createFoodRecognitionService() {
    return RoboflowFoodRecognitionService(
      apiKey: const String.fromEnvironment('ROBOFLOW_API_KEY'),
    );
  }
}
