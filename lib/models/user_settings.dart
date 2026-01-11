class UserSettings {
  final String id;
  final String userId;
  final int startingBalance; // in paise (cents)
  final int monthlyBudget; // in paise (cents)
  final int currentDebt; // in paise (cents)

  UserSettings({
    required this.id,
    required this.userId,
    required this.startingBalance,
    required this.monthlyBudget,
    required this.currentDebt,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      startingBalance: map['starting_balance'] ?? 789050,
      monthlyBudget: map['monthly_budget'] ?? 300000,
      currentDebt: map['current_debt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'starting_balance': startingBalance,
      'monthly_budget': monthlyBudget,
      'current_debt': currentDebt,
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    int? startingBalance,
    int? monthlyBudget,
    int? currentDebt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startingBalance: startingBalance ?? this.startingBalance,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currentDebt: currentDebt ?? this.currentDebt,
    );
  }
}
