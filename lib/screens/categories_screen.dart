import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../theme/theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<CategoryProvider>().loadCategories();
      }
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    String type = 'EXPENSE';

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
                decoration: const InputDecoration(
                  labelText: 'Nombre',
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
      await provider.createCategory(
        name: nameController.text.trim(),
        type: type,
        icon: 'category',
        color: type == 'EXPENSE' ? '#EF4444' : '#10B981', // Colores del tema
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.categories.isEmpty) {
            return const Center(child: Text('No hay categorías'));
          }

          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final c = provider.categories[index];
              final color = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.category, color: Colors.white),
                ),
                title: Text(c.name),
                subtitle: Text(c.type == 'EXPENSE' ? 'Gasto' : 'Ingreso'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: UIColors.destructive),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar'),
                        content: Text('¿Eliminar ${c.name}?'),
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
                      await provider.deleteCategory(c.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: UIColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}