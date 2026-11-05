import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import 'custom_card.dart';

/// Sección "Últimas transacciones" del dashboard: las 5 más recientes por fecha.
class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;

  /// Si es nulo no se muestra el botón "Ver todo".
  final VoidCallback? onViewAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  static const _maxItems = 5;

  // Se ordena una copia para no alterar la lista del provider. Las transacciones
  // con la misma fecha conservan el orden que traen, con las más nuevas primero.
  List<Transaction> get _recent {
    final sorted = transactions.indexed.toList()
      ..sort((a, b) {
        final byDate = b.$2.date.compareTo(a.$2.date);
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    return sorted.take(_maxItems).map((entry) => entry.$2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = {
      for (final c in context.watch<CategoryProvider>().categories) c.id: c.name,
    };
    final recent = _recent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Últimas transacciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.foreground,
                ),
              ),
            ),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('Ver todo')),
          ],
        ),
        const SizedBox(height: 8),
        CustomCard(
          padding: EdgeInsets.zero,
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay transacciones todavía',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: UIColors.mutedForeground),
                  ),
                )
              : Column(
                  children: [
                    for (final t in recent)
                      _RecentTransactionTile(
                        transaction: t,
                        title: t.description.trim().isNotEmpty
                            ? t.description
                            : categoryNames[t.categoryId] ?? 'Sin descripción',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String title;

  const _RecentTransactionTile({required this.transaction, required this.title});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'EXPENSE';
    final color = isExpense ? UIColors.destructive : UIColors.success;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(Formatters.shortDate(transaction.date)),
      trailing: Text(
        '${isExpense ? '-' : '+'}${Formatters.money(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
