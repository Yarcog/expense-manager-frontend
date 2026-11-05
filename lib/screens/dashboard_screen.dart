import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../theme/theme.dart';
import '../components/accounts_section.dart';
import '../components/custom_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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

  // Datos simulados para el gráfico de barras (luego los conectamos al backend)
  final List<FlSpot> _expenseSpots = [
    const FlSpot(0, 3), const FlSpot(1, 1), const FlSpot(2, 4),
    const FlSpot(3, 2), const FlSpot(4, 5), const FlSpot(5, 1),
    const FlSpot(6, 4),
  ];

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
        padding: const EdgeInsets.all(16),
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

            // 🎯 Gráfico de Barras (Evolución)
            Text(
              'Evolución de Gastos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UIColors.foreground),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 6,
                    barGroups: List.generate(7, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: _expenseSpots[index].y,
                            color: UIColors.primary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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