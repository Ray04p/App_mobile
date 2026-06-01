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
  // Ephemeral state: filtri locali della schermata
  String search = '';
  String selectedCategory = 'Tutte';

  // Controlla se la ricetta passa i filtri di ricerca e categoria
  bool matchesFilters(Recipe recipe) {
    final query = search.toLowerCase().trim();

    final matchesSearch = query.isEmpty ||
        recipe.name.toLowerCase().contains(query) ||
        recipe.category.toLowerCase().contains(query);

    final normalizedRecipeCategory = recipe.category.toLowerCase().trim();
    final normalizedSelectedCategory = selectedCategory.toLowerCase().trim();

    // Categorie standard — "Altro" cattura tutto ciò che non rientra in queste
    const standardCategories = ['primo', 'secondo', 'contorno', 'colazione', 'spuntino'];

    bool matchesCategory;

    if (normalizedSelectedCategory == 'tutte') {
      matchesCategory = true;
    } else if (normalizedSelectedCategory == 'altro') {
      // "Altro" mostra le ricette con categoria non standard
      matchesCategory = !standardCategories.contains(normalizedRecipeCategory);
    } else {
      matchesCategory = normalizedRecipeCategory == normalizedSelectedCategory;
    }

    return matchesSearch && matchesCategory;
  }

  // Gestisce i 4 casi possibili per l'immagine di una ricetta
  Widget recipeImage(Recipe recipe) {
    final path = recipe.imagePath;

    // Caso 1: nessuna immagine: placeholder grigio
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.restaurant, size: 48),
      );
    }

    // Caso 2: immagine inclusa nel bundle dell'app
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }

    final file = File(path);

    // Caso 3: file locale non più esistente → placeholder broken
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48),
      );
    }

    // Caso 4: file locale esistente: carica dal filesystem
    return Image.file(file, fit: BoxFit.cover);
  }

  // Naviga al dettaglio della ricetta (guard su id null)
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

    // filteredRecipes applica il filtro "solo disponibili" se lo switch è attivo
    final validRecipes = app.filteredRecipes;

    // Ricette consigliate: solo quelle che passano anche i filtri locali
    final suggested = app.suggestedRecipes()
        .where((recipe) => validRecipes.any((valid) => valid.id == recipe.id))
        .where(matchesFilters)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Tutte le ricette valide che passano i filtri locali
    final allRecipes = validRecipes.where(matchesFilters).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // La sezione "Consigliate" appare solo se la ricerca è vuota e ci sono suggerimenti
    final showSuggestedSection = search.trim().isEmpty && suggested.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF2),
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
        actions: [
          // Naviga alle ricette preferite
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
          // Apre il form per aggiungere una nuova ricetta
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          const SizedBox(height: 8),
          Text(
            'Cosa vuoi cucinare oggi?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 22),

          // Barra di ricerca testuale
          TextField(
            decoration: InputDecoration(
              hintText: 'Cerca una ricetta o categoria...',
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

          const SizedBox(height: 8),

          // Switch "solo ricette con ingredienti in dispensa"
          // Stato gestito in AppState (app state) perché potrebbe servire ad altre schermate
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.kitchen, size: 18, color: Colors.green[800]),
              const SizedBox(width: 6),
              const Text(
                'Solo con ingredienti in dispensa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: app.showOnlyAvailable,
                activeThumbColor: Colors.green[800],
                onChanged: (bool value) {
                  app.toggleAvailableFilter(value);
                },
              ),
            ],
          ),

          // Sezione "Consigliate da noi" — scorrimento orizzontale
          if (showSuggestedSection) ...[
            const SizedBox(height: 18),
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
                            // Gradiente scuro in basso per leggibilità del testo
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
                            // Nome ricetta sovrapposto all'immagine
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
                            // Bottone preferiti sovrapposto in alto a destra
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
                                 onPressed: () async {
                                    try {
                                      await app.toggleFavoriteRecipe(recipe);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Errore nel salvataggio dei preferiti')),
                                        );
                                      }
                                    }
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

          // Filtro per categoria con scorrimento orizzontale
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
                child: Text('Nessuna ricetta corrisponde ai criteri.'),
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
                        // Immagine ricetta con angoli arrotondati
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 95,
                            height: 85,
                            child: recipeImage(recipe),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Info ricetta — Expanded per occupare lo spazio disponibile
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
                        // Bottone preferiti
                        IconButton(
                          icon: Icon(
                            recipe.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: recipe.isFavorite ? Colors.red : null,
                          ),
                          onPressed: () async {
                            try {
                              await app.toggleFavoriteRecipe(recipe);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Errore nel salvataggio dei preferiti')),
                                );
                              }
                            }
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
    );
  }

  // Titolo di sezione
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

  // Bottone categoria con stato selezionato/deselezionato
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
                // Verde pieno se selezionato, verde trasparente se no
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
