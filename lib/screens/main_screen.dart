import 'package:flutter/material.dart';
import 'recipes_screen.dart';
import 'pantry_screen.dart';
import 'meal_plan_screen.dart';
import 'shopping_list.dart';
import 'stats.dart';


class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }


  // Le schermate — stesso ordine della barra in basso
  final List<Widget> _screens = const [
    RecipesScreen(),
    PantryScreen(),
    MealPlanScreen(),
    ShoppingListScreen(),
    StatsScreen(),
  ];

  // Voci della barra in basso
  final List<BottomNavigationBarItem> _navItems = const [
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
