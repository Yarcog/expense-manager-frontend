import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import 'custom_card.dart';

/// Sección "Evolución de Gastos" del dashboard: una barra por cada uno de los
/// últimos 7 días, con hoy a la derecha.
class WeeklyExpenseChart extends StatelessWidget {
  final List<Transaction> transactions;

  const WeeklyExpenseChart({super.key, required this.transactions});

  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );

    final totals = List<double>.filled(7, 0);
    for (final t in transactions) {
      if (t.type != 'EXPENSE') continue;
      final index = days.indexOf(DateTime(t.date.year, t.date.month, t.date.day));
      if (index != -1) totals[index] += t.amount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Evolución de Gastos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: UIColors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        CustomCard(
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: totals.any((total) => total > 0)
                ? _buildChart(days, totals)
                : const Center(
                    child: Text(
                      'Aún no tienes gastos esta semana',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: UIColors.mutedForeground),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<DateTime> days, List<double> totals) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: totals[index],
                color: UIColors.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              Formatters.money(rod.toY),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = days[value.toInt()];
                return Text(
                  _weekdayLabels[day.weekday - 1],
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
