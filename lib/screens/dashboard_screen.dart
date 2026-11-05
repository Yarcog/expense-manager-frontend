import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../theme/theme.dart';
import '../components/accounts_section.dart';
import '../components/custom_card.dart';
import '../components/recent_transactions.dart';
import '../components/weekly_expense_chart.dart';

class DashboardScreen extends StatefulWidget {
  /// Se llama al tocar "Ver todo" en "Últimas transacciones".
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({super.key, this.onViewAllTransactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  bool _loading = true;
  double _income = 0;
  double _expense = 0;
  double _balance = 0;
  late final TransactionProvider _transactions;
  late int _seenChangeCount;

  @override
  void initState() {
    super.initState();
    _transactions = context.read<TransactionProvider>();
    _seenChangeCount = _transactions.changeCount;
    _transactions.addListener(_onTransactionsChanged);
    Future.microtask(() {
      if (mounted) _loadSummary();
    });
  }

  @override
  void dispose() {
    _transactions.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  void _onTransactionsChanged() {
    if (_transactions.changeCount == _seenChangeCount) return;
    _seenChangeCount = _transactions.changeCount;
    _loadSummary(showSpinner: false);
  }

  // Al actualizar no se muestra el indicador de carga: reemplazaría todo el
  // contenido y la pantalla saltaría, además de volver a crear "Mis cuentas".
  Future<void> _loadSummary({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context); // ✅ Capturado antes
    try {
      final response = await _api.get('/reports/summary');
      final data = response.data;
      if (!mounted) return;

      setState(() {
        _income = (data['totalIncome'] as num).toDouble();
        _expense = (data['totalExpense'] as num).toDouble();
        _balance = (data['balance'] as num).toDouble();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar( // ✅ Usa el messenger capturado
        SnackBar(content: Text('Error: $e'), backgroundColor: UIColors.destructive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        // El espacio de abajo evita que el botón "+" tape la última transacción.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🎯 Tarjeta de Balance (Bricolage Style)
            CustomCard(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: UIColors.primary,
                  borderRadius: BorderRadius.circular(UIRadius.xl),
                  boxShadow: const [UIShadows.md],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance Total',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.money(_balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat('Ingresos', _income, UIColors.success),
                        _buildMiniStat('Gastos', _expense, UIColors.destructive),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const AccountsSection(),
            const SizedBox(height: 24),

            _buildTransactionSections(),
          ],
        ),
      ),
    );
  }

  // Mientras cargan o si falló la carga no se muestran las secciones: dirían
  // "no tienes gastos" sin saberlo, o enseñarían datos de la sesión anterior.
  Widget _buildTransactionSections() {
    final provider = context.watch<TransactionProvider>();

    if (provider.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.loadFailed) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'No se pudieron cargar tus transacciones',
              style: TextStyle(color: UIColors.destructive),
            ),
          ),
          TextButton(
            onPressed: provider.loadTransactions,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeeklyExpenseChart(transactions: provider.transactions),
        const SizedBox(height: 24),
        RecentTransactions(
          transactions: provider.transactions,
          onViewAll: widget.onViewAllTransactions,
        ),
      ],
    );
  }

  Widget _buildMiniStat(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          Formatters.money(amount),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}