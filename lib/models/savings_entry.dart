enum SavingsAction { saved, carryOver }

class SavingsEntry {
  final String id;
  final double amount;
  final DateTime date;
  final SavingsAction action;

  SavingsEntry({
    required this.id,
    required this.amount,
    required this.date,
    required this.action,
  });

  bool get isSaved => action == SavingsAction.saved;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'action': action.name,
    };
  }

  factory SavingsEntry.fromJson(Map<String, dynamic> json) {
    return SavingsEntry(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      action: (json['action'] ?? 'saved') == 'carryOver'
          ? SavingsAction.carryOver
          : SavingsAction.saved,
    );
  }
}
