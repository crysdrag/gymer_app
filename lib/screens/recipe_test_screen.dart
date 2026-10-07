import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/ai/providers/themealdb_recipe_service.dart';
import '../services/ai/recipe_service.dart';

class RecipeTestScreen extends StatefulWidget {
  const RecipeTestScreen({super.key});

  @override
  State<RecipeTestScreen> createState() => _RecipeTestScreenState();
}

class _RecipeTestScreenState extends State<RecipeTestScreen> {
  final TextEditingController _ingredientController = TextEditingController(text: "chicken_breast");
  final RecipeService _recipeService = TheMealDBRecipeService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Recipe> _recipes = [];

  Future<void> _searchRecipes() async {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _recipes = [];
    });

    try {
      final results = await _recipeService.getRecipesByIngredient(ingredient);
      setState(() {
        _recipes = results;
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
        title: const Text("Recipe API Test"),
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      labelText: "Ingredient",
                      hintText: "e.g., chicken_breast, tomato",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchRecipes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  child: const Text("Tìm"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_recipes.isEmpty)
              const Expanded(child: Center(child: Text("Nhập nguyên liệu để tìm công thức")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          recipe.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          recipe.durationMinutes != null
                              ? "Thời gian nấu: ${recipe.durationMinutes} phút"
                              : "Thời gian nấu: Không có dữ liệu",
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Nguyên liệu:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...recipe.ingredients.map((ing) => Text("- $ing")),
                                const SizedBox(height: 12),
                                const Text(
                                  "Các bước thực hiện:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...recipe.steps.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("${entry.key + 1}. ${entry.value.trim()}"),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
