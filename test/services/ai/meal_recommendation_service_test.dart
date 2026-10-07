import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/models/food_recognition_result.dart';
import 'package:gymer_app/models/recipe.dart';
import 'package:gymer_app/services/ai/food_recognition_service.dart';
import 'package:gymer_app/services/ai/recipe_service.dart';
import 'package:gymer_app/services/ai/meal_recommendation_service.dart';

class MockFoodRecognitionService implements FoodRecognitionService {
  List<FoodRecognitionResult> results = [];
  @override
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image) async {
    return results;
  }
}

class MockRecipeService implements RecipeService {
  Map<String, List<Recipe>> mockData = {};
  @override
  Future<List<Recipe>> getRecipesByIngredient(String ingredient) async {
    return mockData[ingredient] ?? [];
  }
}

void main() {
  late MockFoodRecognitionService mockRecognition;
  late MockRecipeService mockRecipe;
  late MealRecommendationService service;

  setUp(() {
    mockRecognition = MockFoodRecognitionService();
    mockRecipe = MockRecipeService();
    service = MealRecommendationService(
      foodRecognitionService: mockRecognition,
      recipeService: mockRecipe,
    );
  });

  test('Test 1: Only ingredients with confidence >= 0.8 are used', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken Breast', confidence: 0.91),
      FoodRecognitionResult(foodName: 'Yellow Onion', confidence: 0.87),
      FoodRecognitionResult(foodName: 'Mushroom', confidence: 0.70),
    ];

    mockRecipe.mockData = {
      'chicken': [Recipe(name: 'Chicken Soup', ingredients: ['chicken'], steps: [])],
      'onion': [Recipe(name: 'Onion Rings', ingredients: ['onion'], steps: [])],
      'mushroom': [Recipe(name: 'Mushroom Risotto', ingredients: ['mushroom'], steps: [])],
    };

    final result = await service.recommendMeals(File('dummy.jpg'));

    expect(result.length, 2);
    expect(result.any((r) => r.name == 'Chicken Soup'), true);
    expect(result.any((r) => r.name == 'Onion Rings'), true);
    expect(result.any((r) => r.name == 'Mushroom Risotto'), false);
  });

  test('Test 2: All confidence < 0.8 returns empty list', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken', confidence: 0.79),
    ];
    final result = await service.recommendMeals(File('dummy.jpg'));
    expect(result, isEmpty);
  });

  test('Test 3: Recipes are unique even if matching multiple ingredients', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken', confidence: 0.9),
      FoodRecognitionResult(foodName: 'Onion', confidence: 0.9),
    ];

    final sharedRecipe = Recipe(name: 'Shared Dish', ingredients: ['chicken', 'onion'], steps: []);
    mockRecipe.mockData = {
      'chicken': [sharedRecipe],
      'onion': [sharedRecipe],
    };

    final result = await service.recommendMeals(File('dummy.jpg'));
    expect(result.length, 1);
    expect(result.first.name, 'Shared Dish');
  });

  test('Test 4: Recipes with more matches are ranked higher', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken', confidence: 0.9),
      FoodRecognitionResult(foodName: 'Onion', confidence: 0.9),
    ];

    final recipe1 = Recipe(name: 'Just Chicken', ingredients: ['chicken'], steps: []);
    final recipe2 = Recipe(name: 'Chicken & Onion', ingredients: ['chicken', 'onion'], steps: []);

    mockRecipe.mockData = {
      'chicken': [recipe1, recipe2],
      'onion': [recipe2],
    };

    final result = await service.recommendMeals(File('dummy.jpg'));
    
    expect(result.length, 2);
    expect(result[0].name, 'Chicken & Onion'); // Score 2
    expect(result[1].name, 'Just Chicken');    // Score 1
  });
}
