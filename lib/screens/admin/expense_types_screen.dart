import 'package:flutter/material.dart';
import '../../services/turso_service.dart';

class ExpenseTypesScreen extends StatefulWidget {
  const ExpenseTypesScreen({super.key});

  @override
  State<ExpenseTypesScreen> createState() => _ExpenseTypesScreenState();
}

class _ExpenseTypesScreenState extends State<ExpenseTypesScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _expenseTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  Future<void> _loadExpenseTypes() async {
    setState(() => _isLoading = true);
    final types = await _tursoService.getExpenseTypes();
    setState(() {
      _expenseTypes = types;
      _isLoading = false;
    });
  }

  Future<void> _showTypeDialog([Map<String, dynamic>? type]) async {
    final isEditing = type != null;
    final typeController = TextEditingController(text: type?['type']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Expense Type' : 'Add Expense Type'),
        content: TextField(
          controller: typeController,
          decoration: const InputDecoration(labelText: 'Expense Type'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final typeName = typeController.text;

              if (typeName.isEmpty) return;

              bool success;
              if (isEditing) {
                success = await _tursoService.updateExpenseType(type['id'], typeName);
              } else {
                success = await _tursoService.createExpenseType(typeName);
              }

              if (success) {
                  if (mounted) _loadExpenseTypes();
                  navigator.pop();
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteType(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this expense type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _tursoService.deleteExpenseType(id);
      _loadExpenseTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Types'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _expenseTypes.length,
              itemBuilder: (context, index) {
                final type = _expenseTypes[index];
                return ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(type['type']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showTypeDialog(type),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteType(type['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTypeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
