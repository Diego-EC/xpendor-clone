import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import 'package:flutter/foundation.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onViewTicket;
  final Function(ExpenseStatus)? onStatusChange;

  const ExpenseCard({
    required this.expense,
    this.onViewTicket,
    this.onStatusChange,
    super.key,
  });

  // Métodos de estilo originales para mantener tus colores e iconos
  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.accepted: return Colors.green;
      case ExpenseStatus.rejected: return Colors.red;
      case ExpenseStatus.pending: return Colors.orange;
    }
  }

  IconData _getStatusIcon(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.accepted: return Icons.check_circle;
      case ExpenseStatus.rejected: return Icons.cancel;
      case ExpenseStatus.pending: return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(expense.status).withValues(alpha: 0.1),
          child: Icon(_getStatusIcon(expense.status), color: _getStatusColor(expense.status)),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${expense.category} • ${expense.amount.toStringAsFixed(2)}€"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ACCIONES WEB (Botones verdes/rojos circulares)
            if (kIsWeb)
              SizedBox(
                width: 100, // Espacio fijo para los botones de admin
                child: expense.status == ExpenseStatus.pending
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: 'Accept Expense',
                            child: IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => onStatusChange?.call(ExpenseStatus.accepted),
                            ),
                          ),
                          Tooltip(
                            message: 'Reject Expense',
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => onStatusChange?.call(ExpenseStatus.rejected),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
              ),

            // 2. EL OJO (RESERVA DE ESPACIO CLAVE)
            SizedBox(
              width: 48,
              child: expense.imageUrl != null
                  ? Tooltip(
                      message: 'View Receipt',
                      child: IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                        onPressed: onViewTicket, // Corregido para usar el callback
                      ),
                    )
                  : const SizedBox(),
            ),

            const SizedBox(width: 8),

            // 3. ESTADO (Ancho fijo para alineación vertical perfecta)
            SizedBox(
              width: 80,
              child: Text(
                expense.status.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getStatusColor(expense.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}