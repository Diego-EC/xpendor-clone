import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseService {
  // 1. Referencia a la colección 'expenses' en la nube
  final CollectionReference _expensesCollection = 
      FirebaseFirestore.instance.collection('expenses');

  // 2. Función para guardar un gasto nuevo
  Future<void> saveExpense(Expense expense) async {
    // Usamos add() para que Firebase genere un ID único automáticamente
    await _expensesCollection.add(expense.toMap());
  }

  // 3. Función para el Administrador (Web): Escuchar cambios en tiempo real
  Stream<List<Expense>> get gastosStream {
    return _expensesCollection.orderBy('date', descending: true).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        // Convertimos los datos de Firebase de vuelta a nuestro objeto Expense
        return Expense(
          id: doc.id,
          title: doc['title'],
          amount: doc['amount'].toDouble(),
          date: DateTime.parse(doc['date']),
          category: doc['category'],
          imageUrl: doc['imageUrl'],
          status: ExpenseStatus.values.firstWhere(
            (e) => e.name == doc['status'], 
            orElse: () => ExpenseStatus.pending, // Si el dato es viejo o da error, usa pending por defecto
          ),
        );
      }).toList();

      // --- PARA ASEGURAR EL ORDEN ---
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> updateExpenseStatus(String id, ExpenseStatus newStatus) async {
    try {
      await _expensesCollection.doc(id).update({
        'status': newStatus.name, // Persists 'accepted', 'rejected', or 'pending'
      });
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Función mágica para subir el ticket real
  Future<String?> uploadExpenseImage(String filePath) async {
    try {
      File file = File(filePath);
      
      // Creamos un nombre único basado en el tiempo para que no se sobrescriban
      String fileName = 'tickets/ticket_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 1. Subimos el archivo al "balde" de Storage
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putFile(file);
      
      // 2. Obtenemos el link público para guardarlo en Firestore
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error al subir la imagen: $e");
      return null;
    }
  }
}
