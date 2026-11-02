class CategoryReport {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final double total;
  final int transactionCount;

  CategoryReport({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.total,
    required this.transactionCount,
  });

  factory CategoryReport.fromJson(Map<String, dynamic> json) {
    return CategoryReport(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? 'Sin nombre',
      categoryColor: json['categoryColor'] ?? '#CCCCCC',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}