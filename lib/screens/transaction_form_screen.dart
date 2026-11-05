import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/theme.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  // Hasta dos decimales. Al no aceptar "1.000" se evita que se guarde como 1
  // en vez de mil.
  static final _amountPattern = RegExp(r'^\d*[.,]?\d{0,2}$');

  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _categoryId;
  String? _accountId;
  String _type = 'EXPENSE';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<CategoryProvider>().loadCategories();
        context.read<AccountProvider>().loadAccounts();
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _createCategoryDialog() async {
    final nameController = TextEditingController();
    String type = _type;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'EXPENSE', child: Text('Gasto')),
                  DropdownMenuItem(value: 'INCOME', child: Text('Ingreso')),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (created == true && nameController.text.isNotEmpty) {
      if (!mounted) return;
      final provider = context.read<CategoryProvider>();

      final success = await provider.createCategory(
        name: nameController.text.trim(),
        type: type,
        icon: 'category',
        color: type == 'EXPENSE' ? '#EF4444' : '#10B981',
      );

      if (success) {
        await provider.loadCategories();
        if (mounted) {
          setState(() {
            _categoryId = provider.categories.last.id;
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al crear categoría'),
            backgroundColor: UIColors.destructive,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_categoryId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un monto mayor que cero, sin puntos de miles'),
          backgroundColor: UIColors.destructive,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();

    final success = await provider.createTransaction(
      categoryId: _categoryId!,
      type: _type,
      amount: amount,
      description: _descController.text.trim(),
      date: _date,
      accountId: _accountId,
    );

    // No se espera la respuesta: el formulario se cierra de una vez y las
    // tarjetas del dashboard se actualizan cuando llegue el saldo nuevo.
    if (success) unawaited(accountProvider.loadAccounts());

    setState(() => _saving = false);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error'),
          backgroundColor: UIColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final accounts = context.watch<AccountProvider>().accounts;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transacción')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'EXPENSE', label: Text('Gasto')),
                ButtonSegment(value: 'INCOME', label: Text('Ingreso')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    items: categories
                        .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: UIColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Crear nueva categoría',
                    onPressed: _createCategoryDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _accountId,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin cuenta'),
                ),
                ...accounts.map((a) => DropdownMenuItem<String?>(
                      value: a.id,
                      child: Text(a.name, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _accountId = v),
              decoration: const InputDecoration(
                labelText: 'Cuenta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => _amountPattern.hasMatch(newValue.text)
                      ? newValue
                      : oldValue,
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('Fecha: ${_date.day}/${_date.month}/${_date.year}'),
              onPressed: _pickDate,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}