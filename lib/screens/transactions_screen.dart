import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../theme/theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transacciones')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.transactions.isEmpty) {
            return const Center(child: Text('No hay transacciones'));
          }

          return RefreshIndicator(
            onRefresh: provider.loadTransactions,
            child: ListView.builder(
              itemCount: provider.transactions.length,
              itemBuilder: (context, index) {
                final t = provider.transactions[index];
                final isExpense = t.type == 'EXPENSE';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpense
                        ? UIColors.destructive.withValues(alpha: 0.1)
                        : UIColors.success.withValues(alpha: 0.1),
                    child: Icon(
                      isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isExpense ? UIColors.destructive : UIColors.success,
                    ),
                  ),
                  title: Text(t.description.isEmpty
                      ? 'Sin descripción'
                      : t.description),
                  subtitle: Text(Formatters.date(t.date)),
                  trailing: Text(
                    '${isExpense ? '-' : '+'}${Formatters.money(t.amount)}',
                    style: TextStyle(
                      color: isExpense ? UIColors.destructive : UIColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar'),
                        content: const Text('¿Eliminar esta transacción?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await provider.deleteTransaction(t.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}