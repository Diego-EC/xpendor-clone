import 'package:flutter/material.dart';
import 'package:xpendor_clone/models/expense_model.dart';
import 'package:flutter/foundation.dart'; // Para usar kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:xpendor_clone/services/database_service.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  // --- 1. DATOS ---
  final DatabaseService _dbService = DatabaseService(); 
  bool _isImageUploading = false;
  XFile? _tempPhoto; // Para guardar la foto seleccionada en el diálogo
  ExpenseCategory _selectedCategory = ExpenseCategory.other; // Por defecto 'Other'

  // --- 2. CONTROLLERS ---
  // Controladores para capturar el texto
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // --- 3. CICLO DE VIDA ---
  @override
  void dispose() {
    // Cerramos los controladores al salir de la pantalla para evitar fugas de memoria
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // --- 4. LÓGICA / MÉTODOS ---
  void _showExpenseDialog(BuildContext context) {
    _titleController.clear();
    _amountController.clear();
    _tempPhoto = null;
    _selectedCategory = ExpenseCategory.other;

    // Variables de control de error (empiezan en false)
    bool titleHasError = false;
    bool amountHasError = false;
    bool photoHasError = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Expense'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECCIÓN DE FOTO (Solo para Móvil)
                  if (!kIsWeb) ...[
                    GestureDetector(
                      onTap: () async {
                        try {
                          final ImagePicker picker = ImagePicker();
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 1024,
                            imageQuality: 50,
                          );
                          if (photo != null && context.mounted) {
                            setDialogState(() {
                              _tempPhoto = photo;
                              photoHasError = false; // Quitamos error al seleccionar
                            });
                          }
                        } catch (e) {
                          debugPrint("Error cámara: $e");
                        }
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          // BORDE ROJO SI FALTA LA FOTO
                          border: Border.all(
                            color: photoHasError ? Colors.red : Colors.grey[400]!,
                            width: photoHasError ? 2 : 1,
                          ),
                        ),
                        child: _tempPhoto == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, 
                                      color: photoHasError ? Colors.red : Colors.grey, 
                                      size: 32),
                                  const SizedBox(height: 8),
                                  Text("Add Ticket", 
                                      style: TextStyle(fontSize: 12, color: photoHasError ? Colors.red : Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(_tempPhoto!.path), fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Column(
                    children: [
                      Row(
                        children: [
                          _buildCategoryButton(ExpenseCategory.food, setDialogState),
                          const SizedBox(width: 8),
                          _buildCategoryButton(ExpenseCategory.transport, setDialogState),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildCategoryButton(ExpenseCategory.lodging, setDialogState),
                          const SizedBox(width: 8),
                          _buildCategoryButton(ExpenseCategory.other, setDialogState),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // 2. CAMPO CONCEPTO
                  TextField(
                    controller: _titleController,
                    onChanged: (val) => setDialogState(() => titleHasError = false),
                    decoration: InputDecoration(
                      labelText: 'Concept (e.g. Fuel)',
                      border: const OutlineInputBorder(),
                      // Estilo de borde normal con error
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: titleHasError ? Colors.red : Colors.grey, width: titleHasError ? 2 : 1),
                      ),
                      // Estilo de borde cuando se está escribiendo
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: titleHasError ? Colors.red : const Color(0xFF1E2677), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. CAMPO IMPORTE
                  TextField(
                    controller: _amountController,
                    onChanged: (val) => setDialogState(() => amountHasError = false),
                    decoration: InputDecoration(
                      labelText: 'Amount (€)',
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: amountHasError ? Colors.red : Colors.grey, width: amountHasError ? 2 : 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: amountHasError ? Colors.red : const Color(0xFF1E2677), width: 2),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2677),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                String concepto = _titleController.text.trim();
                double? importe = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));

                // VALIDACIÓN DE ESTADOS
                setDialogState(() {
                  titleHasError = concepto.isEmpty;
                  amountHasError = (importe == null || importe <= 0);
                  // La foto es obligatoria SOLO en móvil
                  photoHasError = !kIsWeb && _tempPhoto == null;
                });

                // Si algo falla, no salimos
                if (titleHasError || amountHasError || photoHasError) return;

                Navigator.pop(context);
                _saveExpenseWithPhoto();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpenseWithPhoto() async {
    setState(() => _isImageUploading = true);

    try {
      String? imageUrl;
      // Si hay una foto capturada en el móvil, la subimos primero
      if (_tempPhoto != null) {
        imageUrl = await _dbService.uploadExpenseImage(_tempPhoto!.path);
      }

      final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

      final newExpense = Expense(
        id: '',
        title: _titleController.text,
        amount: amount,
        category: _selectedCategory.name,
        date: DateTime.now(),
        status: ExpenseStatus.pending,
        imageUrl: imageUrl,
      );

      await _dbService.saveExpense(newExpense);
    } catch (e) {
      debugPrint("Error saving: $e");
    } finally {
      if (mounted) setState(() => _isImageUploading = false);
    }
  }

  // --- 5. EL DIBUJO (BUILD) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kIsWeb ? 'Xpendor Clone - Admin Panel' : 'Xpendor Clone - My Expenses'),
        centerTitle: !kIsWeb,
        backgroundColor: const Color(0xFF1E2677),
        foregroundColor: Colors.white,
      ),
      // Usamos el IgnorePointer para que el usuario no pueda clicar nada mientras sube
      body: IgnorePointer(
        ignoring: _isImageUploading, 
        child: Stack(
          children: [
            StreamBuilder<List<Expense>>(
              stream: _dbService.gastosStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Connection Error'));
                
                // Evita el parpadeo de "doble spinner"
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expensesFromCloud = snapshot.data ?? [];
                
                // para que el más nuevo esté siempre arriba
                expensesFromCloud.sort((a, b) => b.date.compareTo(a.date));
                
                if (expensesFromCloud.isEmpty && !_isImageUploading) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: expensesFromCloud.length,
                  itemBuilder: (context, index) {
                    final expense = expensesFromCloud[index];
                    return ExpenseCard(
                      key: ValueKey(expense.id),
                      expense: expense,
                      // IMPORTANTE: Pasamos la función que abre el ticket
                      onViewTicket: expense.imageUrl != null ? () => _viewTicket(expense) : null,
                      onStatusChange: (newStatus) => _dbService.updateExpenseStatus(expense.id, newStatus),
                    );
                  },
                );
              },
            ),
            
            // Spinner de subida mejorado
            if (_isImageUploading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            "Processing Ticket...", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
        floatingActionButton: _isImageUploading 
          ? null 
          : FloatingActionButton(
              onPressed: () => _showExpenseDialog(context), 
              child: Icon(Icons.add),
            ),
    );
  }

  // --- 6. HELPER WIDGETS (Pequeñas piezas) ---
  void _viewTicket(Expense expense) async {
    // 1. Spinner de espera
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await precacheImage(NetworkImage(expense.imageUrl!), context);
      if (!mounted) return;
      Navigator.pop(context); // Quitar spinner

      // 2. Diálogo con la imagen optimizada
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(expense.title),
          content: SizedBox(
            // Esto obliga a la imagen a no exceder el tamaño de la pantalla
            width: double.maxFinite, 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                expense.imageUrl!,
                fit: BoxFit.contain, // Muestra la imagen entera sin recortar
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Close')
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not load image"))
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No expenses registered",
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey[600], 
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 8),
          const Text("New tickets will appear here automatically"),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food: return Icons.restaurant;
      case ExpenseCategory.transport: return Icons.directions_car;
      case ExpenseCategory.lodging: return Icons.hotel;
      case ExpenseCategory.other: return Icons.more_horiz;
    }
  }

  Widget _buildCategoryButton(ExpenseCategory cat, StateSetter setDialogState) {
    bool isSelected = _selectedCategory == cat;
    return Expanded( // El Expanded hace que cada botón ocupe exactamente la mitad de la fila
      child: GestureDetector(
        onTap: () => setDialogState(() => _selectedCategory = cat),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E2677) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E2677) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(cat),
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                cat.name.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}