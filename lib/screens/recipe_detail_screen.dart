import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/app_state.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final int recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  Widget recipeImage(Recipe recipe) {
    final path = recipe.imagePath;

    if (path == null || path.isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.restaurant, size: 80),
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.broken_image, size: 80),
            ),
          );
        },
      );
    }

    final file = File(path);

    if (!file.existsSync()) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 80),
        ),
      );
    }

    return Image.file(
      file,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final recipe = app.recipeById(recipeId.toString());

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ricetta non trovata'),
        ),
        body: const Center(
          child: Text('Questa ricetta non esiste più.'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipeImage(recipe),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${recipe.category} • ${recipe.preparationTime} min • ${recipe.difficulty} • ${recipe.portions} porzioni',
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Ingredienti',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              ingredient.displayText,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Preparazione',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  if (recipe.notes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(recipe.notes),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifica ricetta'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeFormScreen(recipe: recipe),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}