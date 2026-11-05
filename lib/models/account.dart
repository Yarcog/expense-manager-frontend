import 'dart:ui' show Color;

/// Nombres amigables de cada tipo de cuenta que acepta el backend.
const Map<String, String> accountTypeLabels = {
  'NEQUI': 'Nequi',
  'DAVIPLATA': 'Daviplata',
  'EFECTIVO': 'Efectivo',
  'BANCO': 'Banco',
  'TARJETA_CREDITO': 'Tarjeta de crédito',
};

/// Color de cada tipo de cuenta, en el formato que guarda el backend.
const Map<String, String> accountTypeColors = {
  'NEQUI': '#6D28D9',
  'DAVIPLATA': '#DC2626',
  'EFECTIVO': '#059669',
  'BANCO': '#2563EB',
  'TARJETA_CREDITO': '#374151',
};

class Account {
  final String id;
  final String name;
  final String type;
  final double initialBalance;
  final double balance;
  final String color;
  final DateTime? createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.balance,
    required this.color,
    this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'EFECTIVO',
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }

  String get typeLabel => accountTypeLabels[type] ?? type;

  /// El fondo de la tarjeta depende del tipo, no del color guardado.
  Color get typeColor {
    final hex = accountTypeColors[type] ?? accountTypeColors['TARJETA_CREDITO']!;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
}
