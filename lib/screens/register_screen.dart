import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Usuario creado exitosamente! Ahora inicia sesión.'),
          backgroundColor: UIColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error desconocido'),
          backgroundColor: UIColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.person_add, size: 80, color: UIColors.primary),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mín. 8 caracteres)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrarse', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}