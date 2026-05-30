import 'package:flutter/material.dart';
import 'package:meal_planner_project/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async{
  await initializeDateFormatting('it', null); //Carica i dati della locale italiana (nomi dei mesi, giorni ecc.) necessari per DateFormat('d MMM', 'it') e DateFormat('d MMM yyyy', 'it') che usiamo in _weekLabel.
  //Senza di esso i widget inizierebbero a costruirsi prima che i dati della locale siano pronti, restituendo errore nel meal_plan
  runApp(const MealMateApp());
}

class MealMateApp extends StatelessWidget {
  const MealMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MealMate',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}