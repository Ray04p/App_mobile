import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/app_state.dart';
import 'favorite_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String search = '';
  String selectedCategory = 'Tutte';

  bool matchesFilters(Recipe recipe) {
    final query = search.toLowerCase().trim();

    final matchesSearch = query.isEmpty ||
        recipe.name.toLowerCase().contains(query) ||
        recipe.category.toLowerCase().contains(query);

    final matchesCategory =
        selectedCategory == 'Tutte' || recipe.category == selectedCategory;

    return matchesSearch && matchesCategory;
  }

  Widget recipeImage(Recipe recipe) {
    final path = recipe.imagePath;

    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.restaurant, size: 48),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }

    final file = File(path);

    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48),
      );
    }

    return Image.file(file, fit: BoxFit.cover);
  }

  void openDetail(Recipe recipe) {
    if (recipe.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    final suggested = app.suggestedRecipes().where(matchesFilters).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final allRecipes = app.recipes.where(matchesFilters).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final showSuggestedSection = search.trim().isEmpty && suggested.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FavoriteRecipesScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecipeFormScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cosa vuoi cucinare oggi?',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cerca ricette o ingredienti...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F0E8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => search = value),
            ),
            if (showSuggestedSection) ...[
              const SizedBox(height: 32),
              sectionTitle('Consigliate da noi'),
              const SizedBox(height: 14),
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggested.length,
                  itemBuilder: (context, index) {
                    final recipe = suggested[index];

                    return GestureDetector(
                      onTap: () => openDetail(recipe),
                      child: Container(
                        width: 210,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              recipeImage(recipe),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 14,
                                child: Text(
                                  recipe.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      recipe.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: recipe.isFavorite
                                          ? Colors.red
                                          : Colors.black87,
                                    ),
                                    onPressed: () {
                                      app.toggleFavoriteRecipe(recipe);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 34),
            sectionTitle('Categorie'),
            const SizedBox(height: 14),
            SizedBox(
              height: 105,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  categoryButton('Tutte', Icons.restaurant),
                  categoryButton('Primo', Icons.ramen_dining),
                  categoryButton('Secondo', Icons.dinner_dining),
                  categoryButton('Contorno', Icons.eco),
                  categoryButton('Colazione', Icons.cake),
                  categoryButton('Spuntino', Icons.local_cafe),
                  categoryButton('Altro', Icons.more_horiz),
                ],
              ),
            ),
            const SizedBox(height: 30),
            sectionTitle('Le tue ricette'),
            const SizedBox(height: 14),
            if (allRecipes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nessuna ricetta trovata'),
                ),
              )
            else
              ...allRecipes.map((recipe) {
                return GestureDetector(
                  onTap: () => openDetail(recipe),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 95,
                              height: 85,
                              child: recipeImage(recipe),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.category,
                                  style: TextStyle(
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${recipe.preparationTime} min • ${recipe.difficulty}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              recipe.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: recipe.isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              app.toggleFavoriteRecipe(recipe);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: Colors.green[900],
        fontFamily: 'serif',
      ),
    );
  }

  Widget categoryButton(String label, IconData icon) {
    final selected = selectedCategory == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.green[800]
                    : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.green[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
