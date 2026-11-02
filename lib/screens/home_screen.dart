import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: UIColors.primary,
        unselectedItemColor: UIColors.mutedForeground, // ✅ Corregido
        backgroundColor: UIColors.card, // ✅ Corregido
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transacciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorías',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/transaction-form');
          if (_currentIndex == 0) {
            setState(() => _currentIndex = 0);
          }
        },
        backgroundColor: UIColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}