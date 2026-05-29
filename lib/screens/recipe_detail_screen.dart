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
        color: Colors.grey.shade200,
        child: const Icon(Icons.restaurant, size: 80),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }

    final file = File(path);

    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 80),
      );
    }

    return Image.file(file, fit: BoxFit.cover);
  }

  // --- LA LOGICA DI ELIMINAZIONE INCAPSULATA ---
  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Elimina Ricetta'),
          content: const Text(
            'Sei sicuro di voler eliminare questa ricetta? L\'azione cancellerà anche gli ingredienti associati in modo irreversibile.',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // Chiude solo il popup
              child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(ctx).pop(); // 1. Chiudi il popup
                
                // 2. Chiedi al Provider di distruggere i dati dal DB Relazionale
                final app = Provider.of<AppState>(context, listen: false);
                await app.deleteRecipe(id);
                
                // 3. Torna alla schermata principale se l'app è ancora in esecuzione
                if (context.mounted) {
                  Navigator.of(context).pop(); 
                }
              },
              child: const Text('Elimina', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  // ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final recipe = app.recipeById(recipeId.toString());

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ricetta non trovata')),
        body: const Center(child: Text('Questa ricetta non esiste più.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFFF8FBF2),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  children: [
                    // PULSANTE 1: CUORE (Preferiti)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
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

                    const SizedBox(width: 10),

                    // PULSANTE 2: MODIFICA
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.black87,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeFormScreen(
                                recipe: recipe,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    // PULSANTE 3: ELIMINA (Nuovo Inserimento)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          _confirmDelete(context, recipe.id!);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  recipeImage(recipe),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBF2),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.name,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.category,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      recipe.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        infoBox(
                          icon: Icons.schedule,
                          value: '${recipe.preparationTime}',
                          label: 'Min',
                        ),
                        infoBox(
                          icon: Icons.restaurant,
                          value: '${recipe.portions}',
                          label: 'Porzioni',
                        ),
                        infoBox(
                          icon: Icons.leaderboard,
                          value: recipe.difficulty,
                          label: 'Livello',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    sectionTitle('Ingredienti'),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 9,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ingredient.displayText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    sectionTitle('Preparazione'),
                    const SizedBox(height: 12),
                    Text(
                      recipe.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    if (recipe.notes.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      sectionTitle('Note'),
                      const SizedBox(height: 12),
                      Text(
                        recipe.notes,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF8FBF2),
            child: Icon(
              icon,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Text(
      '$text:',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.green[900],
        fontFamily: 'serif',
      ),
    );
  }
}