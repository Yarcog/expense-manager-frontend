import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart'; // Lista de transacciones
import 'screens/transaction_form_screen.dart'; // Formulario
import 'screens/categories_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: UIColors.primary,
        scaffoldBackgroundColor: UIColors.background,
        colorScheme: const ColorScheme.light(
          primary: UIColors.primary,
          secondary: UIColors.secondary,
          surface: UIColors.card,
          error: UIColors.destructive,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: UIColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: UIColors.foreground),
          titleTextStyle: TextStyle(
            color: UIColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: UIColors.primary,
            foregroundColor: UIColors.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIRadius.md),
            ),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/transactions': (_) => const TransactionsScreen(),
        '/transaction-form': (_) => const TransactionFormScreen(),
        '/categories': (_) => const CategoriesScreen(),
      },
    );
  }
}