import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';

const double _cardWidth = 240;
const double _cardHeight = 160;

/// Sección "Mis cuentas" del dashboard: tarjetas deslizables con el saldo de
/// cada cuenta y, al final, una tarjeta para agregar una nueva.
class AccountsSection extends StatefulWidget {
  const AccountsSection({super.key});

  @override
  State<AccountsSection> createState() => _AccountsSectionState();
}

class _AccountsSectionState extends State<AccountsSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        // Esta sección se crea al iniciar sesión: se limpian las cuentas de
        // una sesión anterior antes de pedir las del usuario actual.
        context.read<AccountProvider>()
          ..clear()
          ..loadAccounts();
      }
    });
  }

  Future<void> _showAddDialog() {
    return showDialog<void>(
      context: context,
      builder: (_) => const _AddAccountDialog(),
    );
  }

  Future<void> _confirmDelete(Account account) async {
    final provider = context.read<AccountProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Quieres eliminar la cuenta "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final success = await provider.deleteAccount(account.id);
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al eliminar la cuenta'),
          backgroundColor: UIColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final accounts = provider.accounts;
    // La altura crece con el tamaño de letra del teléfono para que el
    // contenido de la tarjeta siempre quepa.
    final height = MediaQuery.textScalerOf(context).scale(_cardHeight);
    // Mientras cargan o si falló la carga no se muestra el total: diría
    // "$ 0" sin saberlo, o una suma con saldos desactualizados.
    final showTotal =
        !provider.loadFailed && !(provider.isLoading && accounts.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Mis cuentas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: UIColors.foreground,
              ),
            ),
            if (showTotal) ...[
              const SizedBox(width: 12),
              // Los totales muy largos se reducen en vez de cortarse.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${Formatters.money(
                      accounts.fold<double>(0, (sum, a) => sum + a.balance),
                    )}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: UIColors.foreground,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (provider.loadFailed) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'No se pudieron cargar tus cuentas',
                  style: TextStyle(color: UIColors.destructive),
                ),
              ),
              TextButton(
                onPressed: provider.isLoading ? null : provider.loadAccounts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: height,
          // Solo se muestra el indicador en la primera carga. Al recargar se
          // dejan las tarjetas visibles hasta que llegue el saldo nuevo.
          child: provider.isLoading && accounts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == accounts.length) {
                      return _AddAccountCard(onTap: _showAddDialog);
                    }
                    final account = accounts[index];
                    return _AccountCard(
                      account: account,
                      onLongPress: () => _confirmDelete(account),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onLongPress;

  const _AccountCard({required this.account, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: account.typeColor,
        borderRadius: BorderRadius.circular(UIRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.typeLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const Spacer(),
                if (account.balance < 0) const _NegativeBalanceBadge(),
                // Los saldos muy largos se reducen en vez de cortarse.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.money(account.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso blanco de saldo negativo. Un texto rojo no se vería en la tarjeta de
/// Daviplata, que ya es roja, así que el aviso se ve igual en todos los colores.
class _NegativeBalanceBadge extends StatelessWidget {
  const _NegativeBalanceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIRadius.full),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 14, color: UIColors.destructive),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'Saldo negativo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: UIColors.foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: UIColors.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIRadius.xl),
          side: const BorderSide(color: UIColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Text(
              '+ Agregar cuenta',
              style: TextStyle(
                color: UIColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo para crear una cuenta. Sigue abierto mientras se guarda y, si el
/// backend rechaza la cuenta, muestra el motivo sin perder lo que se escribió.
class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  // Hasta dos decimales y signo opcional (una tarjeta puede empezar en deuda).
  // Al no aceptar "1.000" se evita que se guarde como 1 en vez de mil.
  static final _balancePattern = RegExp(r'^-?\d*[.,]?\d{0,2}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _type = accountTypeLabels.keys.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  // Si el campo queda vacío, la cuenta empieza en cero.
  double? _parseBalance(String text) {
    final value = text.trim().replaceAll(',', '.');
    return value.isEmpty ? 0 : double.tryParse(value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final provider = context.read<AccountProvider>();
    final success = await provider.createAccount(
      name: _nameController.text.trim(),
      type: _type,
      initialBalance: _parseBalance(_balanceController.text)!,
      color: accountTypeColors[_type]!,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = provider.errorMessage ?? 'Error al crear la cuenta';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva cuenta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Escribe un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: accountTypeLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) =>
                        _balancePattern.hasMatch(newValue.text)
                            ? newValue
                            : oldValue,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _parseBalance(v ?? '') == null
                    ? 'Escribe un valor numérico'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: UIColors.destructive),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Creando...' : 'Crear'),
        ),
      ],
    );
  }
}
