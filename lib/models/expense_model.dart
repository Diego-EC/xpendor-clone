enum ExpenseStatus { pending, accepted, rejected }
enum ExpenseCategory { food, transport, lodging, other }

class Expense {
  String id;
  String title;
  double amount;
  DateTime date;
  String category;
  String? imageUrl; // Para la foto del ticket
  ExpenseStatus status;    // 'pendiente', 'aceptado', 'rechazado'

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.imageUrl,
    this.status = ExpenseStatus.pending, // Por defecto todos nacen pendientes
  });

  // Convierte un gasto a un Mapa para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'imageUrl': imageUrl,
      'status': status.name,
    };
  }
}