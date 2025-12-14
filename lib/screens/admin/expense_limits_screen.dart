import 'package:flutter/material.dart';
import '../../services/turso_service.dart';

class ExpenseLimitsScreen extends StatefulWidget {
  const ExpenseLimitsScreen({super.key});

  @override
  State<ExpenseLimitsScreen> createState() => _ExpenseLimitsScreenState();
}

class _ExpenseLimitsScreenState extends State<ExpenseLimitsScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _limits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    setState(() => _isLoading = true);
    final limits = await _tursoService.getExpenseLimits();
    setState(() {
      _limits = limits;
      _isLoading = false;
    });
  }

  Future<void> _showLimitDialog([Map<String, dynamic>? limit]) async {
    final isEditing = limit != null;
    final deptIdController = TextEditingController(text: limit?['deptId']?.toString());
    final monthController = TextEditingController(text: limit?['month']);
    final limitController = TextEditingController(text: limit?['limit']?.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Expense Limit' : 'Add Expense Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deptIdController,
              decoration: const InputDecoration(labelText: 'Department ID'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: monthController,
              decoration: const InputDecoration(labelText: 'Month Name'),
            ),
            TextField(
              controller: limitController,
              decoration: const InputDecoration(labelText: 'Limit Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final deptId = int.tryParse(deptIdController.text);
              final month = monthController.text;
              final amount = int.tryParse(limitController.text);

              if (deptId == null || month.isEmpty || amount == null) return;

              bool success;
              if (isEditing) {
                success = await _tursoService.updateExpenseLimit(
                    limit['id'], deptId, month, amount);
              } else {
                success = await _tursoService.createExpenseLimit(deptId, month, amount);
              }

              if (success) {
                  if (mounted) _loadLimits();
                  navigator.pop();
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLimit(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this expense limit?'),
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
      await _tursoService.deleteExpenseLimit(id);
      _loadLimits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Expense Limits'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _limits.length,
              itemBuilder: (context, index) {
                final limit = _limits[index];
                return ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text('${limit['month']} (Dept: ${limit['deptId']})'),
                  subtitle: Text('Limit: ${limit['limit']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showLimitDialog(limit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLimit(limit['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLimitDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
