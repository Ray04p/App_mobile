import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'recipe_detail_screen.dart';
import '../providers/app_state.dart';
import 'recipe_form_screen.dart';
import '../models/recipe.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String search = '';
  String selectedCategory = 'Tutte';
  String selectedDifficulty = 'Tutte';
  String selectedTime = 'Tutti';

  bool matchesFilters(Recipe recipe) {
    final query = search.toLowerCase().trim();

    final matchesSearch = query.isEmpty ||
        recipe.name.toLowerCase().contains(query) ||
        recipe.category.toLowerCase().contains(query);

    final matchesCategory =
        selectedCategory == 'Tutte' || recipe.category == selectedCategory;

    final matchesDifficulty = selectedDifficulty == 'Tutte' ||
        recipe.difficulty == selectedDifficulty;

    final matchesTime = selectedTime == 'Tutti' ||
        (selectedTime == '≤ 30 min' && recipe.preparationTime <= 30) ||
        (selectedTime == '31-60 min' &&
            recipe.preparationTime > 30 &&
            recipe.preparationTime <= 60) ||
        (selectedTime == '> 60 min' && recipe.preparationTime > 60);

    return matchesSearch && matchesCategory && matchesDifficulty && matchesTime;
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    final suggested = app.suggestedRecipes().where(matchesFilters).toList();
    final favorites = app.favoriteRecipes().where(matchesFilters).toList();

    favorites.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    suggested.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    final recipes = app.recipes.where((recipe) {
      if (recipe.isRecommended) {
        return false;
      }

      return matchesFilters(recipe);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ricette',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 29, 102, 34),
            fontFamily: 'serif',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cerca ricetta o categoria',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => search = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
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
          ),


          //FILTRI
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            'Tutte',
                            'Primo',
                            'Secondo',
                            'Contorno',
                            'Dolce',
                            'Spuntino',
                            'Altro',
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDifficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficoltà',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            'Tutte',
                            'Facile',
                            'Media',
                            'Difficile',
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDifficulty = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedTime,
                          decoration: const InputDecoration(
                            labelText: 'Tempo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            'Tutti',
                            '≤ 30 min',
                            '31-60 min',
                            '> 60 min',
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTime = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),


                //RESETS
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset filtri'),
                    onPressed: () {
                      setState(() {
                        search = '';
                        selectedCategory = 'Tutte';
                        selectedDifficulty = 'Tutte';
                        selectedTime = 'Tutti';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // PREFERITE
          if (favorites.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ricette preferite',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 29, 102, 34),
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final recipe = favorites[index];

                  return SizedBox(
                    width: 230,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (recipe.id == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipeId: recipe.id!,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Preferita',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                recipe.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
          ],

          // CONSIGLIATE
          if (suggested.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ricette consigliate da noi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 29, 102, 34),
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: suggested.length,
                itemBuilder: (context, index) {
                  final recipe = suggested[index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (recipe.id == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipeId: recipe.id!,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.recommend),
                              const SizedBox(width: 10),
                              Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
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
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
          ],

          // RICETTE DELL'UTENTE
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Le tue ricette',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 29, 102, 34),
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),

          if (recipes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Nessuna ricetta trovata',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 29, 102, 34),
                    fontFamily: 'serif',
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(recipe.name),
                    subtitle: Text(
                      '${recipe.category} • ${recipe.preparationTime} min • ${recipe.difficulty}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            if (recipe.id != null) {
                              app.deleteRecipe(recipe.id!);
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      if (recipe.id == null) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipeId: recipe.id!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
