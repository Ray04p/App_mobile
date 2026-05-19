import 'package:flutter/material.dart';
import 'recipes_screen.dart';
import 'pantry_screen.dart';
import 'meal_plan_screen.dart';
import 'shopping_list.dart';
import 'stats.dart';

// Sostituisci HomeScreen con questo:

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }


  // Le schermate — stesso ordine della barra in basso
  final List<Widget> _screens = const [
  //  HomeScreen(),
    RecipesScreen(),
    PantryScreen(),
    MealPlanScreen() ,
    ShoppingListScreen() ,
    StatsScreen() ,
  ];

  // Voci della barra in basso
  final List<BottomNavigationBarItem> _navItems = const [
   // BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Ricette'),
    BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Dispensa'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meal Plan'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Lista Spesa'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistiche'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene lo stato di ogni schermata viva
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,        
        unselectedItemColor: Colors.grey,       
        type: BottomNavigationBarType.fixed,    
        items: _navItems,
      ),
    );
  }
}


// HomeScreen aggiornata: i tap ora cambiano tab invece di fare push
/*
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recupera lo stato del MainScreen per cambiare tab
    final mainState = context.findAncestorStateOfType<_MainScreenState>();

    final items = [
      ['Ricette', Icons.restaurant_menu, 1],
      ['Dispensa', Icons.kitchen, 2],
      ['Meal Plan', Icons.calendar_month, 3],
      ['Lista Spesa', Icons.shopping_cart, 4],
      ['Statistiche', Icons.bar_chart, 5],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MealMate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                // Cambia tab invece di push → niente freccia indietro
                onTap: () => mainState?.changeTab(items[index][2] as int),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[index][1] as IconData, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      items[index][0] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
*/