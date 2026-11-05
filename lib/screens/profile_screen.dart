import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';

const List<String> _supportedCurrencies = ['COP', 'USD', 'EUR'];
const int _minPasswordLength = 8;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // microtask: el provider avisa a los widgets, y eso no se puede hacer
    // mientras la pantalla todavía se está construyendo.
    Future.microtask(() {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loadProfile();
    if (!success) _showError(auth);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: UIColors.success),
    );
  }

  void _showError(AuthProvider auth) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.errorMessage ?? 'Error desconocido'),
        backgroundColor: UIColors.destructive,
      ),
    );
  }

  Future<void> _showEditProfileDialog(User user) async {
    final result = await showDialog<_ProfileChanges>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );
    if (result == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(result.name, result.currency);
    if (success) {
      _showSuccess('Perfil actualizado');
    } else {
      _showError(auth);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final result = await showDialog<_PasswordChange>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(result.current, result.newPass);
    if (success) {
      _showSuccess('Contraseña actualizada');
    } else {
      _showError(auth);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: UIColors.destructive),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    // Borra todas las pantallas anteriores para que no se pueda volver atrás.
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? _buildWithoutUser(auth)
          : _buildProfile(user, auth.isLoading),
    );
  }

  Widget _buildWithoutUser(AuthProvider auth) {
    if (auth.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No se pudo cargar el perfil'),
          const SizedBox(height: UISpacing.sm),
          TextButton(
            onPressed: _loadProfile,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(User user, bool isLoading) {
    return ListView(
      padding: const EdgeInsets.all(UISpacing.md),
      children: [
        // Altura fija para que la pantalla no salte al aparecer la barra.
        SizedBox(
          height: 4,
          child: isLoading ? const LinearProgressIndicator() : null,
        ),
        const SizedBox(height: UISpacing.md),
        _ProfileHeader(user: user),
        const SizedBox(height: UISpacing.lg),
        // Los botones se desactivan mientras hay una petición en curso.
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _showEditProfileDialog(user),
          icon: const Icon(Icons.edit),
          label: const Text('Editar perfil'),
        ),
        const SizedBox(height: UISpacing.sm),
        OutlinedButton.icon(
          onPressed: isLoading ? null : _showChangePasswordDialog,
          icon: const Icon(Icons.lock),
          label: const Text('Cambiar contraseña'),
        ),
        const SizedBox(height: UISpacing.sm),
        ElevatedButton.icon(
          onPressed: isLoading ? null : _confirmLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: UIColors.destructive,
            foregroundColor: UIColors.destructiveForeground,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: UIColors.primary,
          child: Text(
            initial,
            style: const TextStyle(
              color: UIColors.primaryForeground,
              fontSize: UITypography.fontSize3XL,
              fontWeight: UITypography.fontWeightBold,
            ),
          ),
        ),
        const SizedBox(height: UISpacing.md),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: UITypography.fontSizeXL,
            fontWeight: UITypography.fontWeightBold,
          ),
        ),
        const SizedBox(height: UISpacing.xs),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: UIColors.mutedForeground),
        ),
        const SizedBox(height: UISpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UISpacing.sm + UISpacing.xs,
            vertical: UISpacing.xs,
          ),
          decoration: BoxDecoration(
            color: UIColors.muted,
            borderRadius: BorderRadius.circular(UIRadius.full),
          ),
          child: Text(
            '${user.role} · ${user.currency}',
            style: const TextStyle(
              fontSize: UITypography.fontSizeXS,
              fontWeight: UITypography.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }
}

// Datos que devuelve el diálogo de editar perfil al pulsar "Guardar".
class _ProfileChanges {
  final String name;
  final String currency;

  const _ProfileChanges(this.name, this.currency);
}

class _EditProfileDialog extends StatefulWidget {
  final User user;

  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _currency = widget.user.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ProfileChanges(_nameController.text.trim(), _currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El dropdown falla si su valor no está en la lista. El backend acepta
    // cualquier moneda de 3 letras, así que se agrega la actual si hace falta.
    final currencies = {..._supportedCurrencies, widget.user.currency};

    return AlertDialog(
      title: const Text('Editar perfil'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              items: currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _currency = value!),
              decoration: const InputDecoration(
                labelText: 'Moneda',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// Datos que devuelve el diálogo de cambiar contraseña al pulsar "Cambiar".
class _PasswordChange {
  final String current;
  final String newPass;

  const _PasswordChange(this.current, this.newPass);
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    // Si algún validador falla, el diálogo sigue abierto y no se llama al backend.
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PasswordChange(_currentController.text, _newController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Ingresa tu contraseña actual'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.length < _minPasswordLength)
                      ? 'Debe tener mínimo $_minPasswordLength caracteres'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value != _newController.text
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Cambiar'),
        ),
      ],
    );
  }
}
