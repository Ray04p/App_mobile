import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/app_state.dart';
import 'recipe_detail_screen.dart';

class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
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

    final matchesDifficulty =
        selectedDifficulty == 'Tutte' || recipe.difficulty == selectedDifficulty;

    final matchesTime = selectedTime == 'Tutti' ||
        (selectedTime == '≤ 30 min' && recipe.preparationTime <= 30) ||
        (selectedTime == '31-60 min' &&
            recipe.preparationTime > 30 &&
            recipe.preparationTime <= 60) ||
        (selectedTime == '> 60 min' && recipe.preparationTime > 60);

    return matchesSearch && matchesCategory && matchesDifficulty && matchesTime;
  }

  Widget recipeImage(Recipe recipe) {
    final path = recipe.imagePath;

    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.restaurant),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }

    final file = File(path);

    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image),
      );
    }

    return Image.file(file, fit: BoxFit.cover);
  }

  Future<void> openFilters() async {
    String tempCategory = selectedCategory;
    String tempDifficulty = selectedDifficulty;
    String tempTime = selectedTime;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtri',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),

                    filterColumn(
                      title: 'Categoria',
                      options: const [
                        'Tutte',
                        'Primo',
                        'Secondo',
                        'Contorno',
                        'Colazione',
                        'Spuntino',
                        'Altro',
                      ],
                      selected: tempCategory,
                      onSelected: (value) {
                        setModalState(() {
                          tempCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    filterColumn(
                      title: 'Difficoltà',
                      options: const [
                        'Tutte',
                        'Facile',
                        'Media',
                        'Difficile',
                      ],
                      selected: tempDifficulty,
                      onSelected: (value) {
                        setModalState(() {
                          tempDifficulty = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    filterColumn(
                      title: 'Tempo di preparazione',
                      options: const [
                        'Tutti',
                        '≤ 30 min',
                        '31-60 min',
                        '> 60 min',
                      ],
                      selected: tempTime,
                      onSelected: (value) {
                        setModalState(() {
                          tempTime = value;
                        });
                      },
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = 'Tutte';
                                selectedDifficulty = 'Tutte';
                                selectedTime = 'Tutti';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = tempCategory;
                                selectedDifficulty = tempDifficulty;
                                selectedTime = tempTime;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Applica'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget filterColumn({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: selected == option,
              onSelected: (_) => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    final favorites = app.favoriteRecipes().where(matchesFilters).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ricette preferite',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 29, 102, 34),
            fontFamily: 'serif',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cerca tra le preferite',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(Icons.filter_list),
                onPressed: openFilters,
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Nessuna ricetta preferita trovata'),
              ),
            )
          else
            ...favorites.map((recipe) {
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: recipeImage(recipe),
                    ),
                  ),
                  title: Text(
                    recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${recipe.category} • ${recipe.preparationTime} min • ${recipe.difficulty}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      app.toggleFavoriteRecipe(recipe);
                    },
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
            }),
        ],
      ),
    );
  }
}