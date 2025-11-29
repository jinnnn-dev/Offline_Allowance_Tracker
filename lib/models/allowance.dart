enum AllowanceFrequency { daily, weekly }

class Allowance {
  final double amount;
  final AllowanceFrequency frequency;
  final DateTime lastResetDate;

  Allowance({
    required this.amount,
    required this.frequency,
    required this.lastResetDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'frequency': frequency.toString().split('.').last,
      'lastResetDate': lastResetDate.toIso8601String(),
    };
  }

  factory Allowance.fromJson(Map<String, dynamic> json) {
    return Allowance(
      amount: (json['amount'] ?? 0).toDouble(),
      frequency: json['frequency'] == 'weekly'
          ? AllowanceFrequency.weekly
          : AllowanceFrequency.daily,
      lastResetDate: DateTime.parse(
        json['lastResetDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
