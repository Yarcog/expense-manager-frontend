class Transaction {
  final String id;
  final String categoryId;
  final String type;
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      type: json['type'] ?? 'EXPENSE',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}