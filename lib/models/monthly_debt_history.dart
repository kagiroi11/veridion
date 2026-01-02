class MonthlyDebtHistory {
  final String id;
  final DateTime month; // First day of the month
  final int debtAmount; // in paise (cents)
  final String userId;

  MonthlyDebtHistory({
    required this.id,
    required this.month,
    required this.debtAmount,
    required this.userId,
  });

  factory MonthlyDebtHistory.fromMap(Map<String, dynamic> map) {
    return MonthlyDebtHistory(
      id: map['id'].toString(),
      month: DateTime.parse(map['month']),
      debtAmount: map['debt_amount'] ?? 0,
      userId: map['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'debt_amount': debtAmount,
      'user_id': userId,
    };
  }

  MonthlyDebtHistory copyWith({
    String? id,
    DateTime? month,
    int? debtAmount,
    String? userId,
  }) {
    return MonthlyDebtHistory(
      id: id ?? this.id,
      month: month ?? this.month,
      debtAmount: debtAmount ?? this.debtAmount,
      userId: userId ?? this.userId,
    );
  }
}
