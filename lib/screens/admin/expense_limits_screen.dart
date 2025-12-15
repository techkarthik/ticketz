import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class ExpenseLimitsScreen extends StatefulWidget {
  const ExpenseLimitsScreen({super.key});

  @override
  State<ExpenseLimitsScreen> createState() => _ExpenseLimitsScreenState();
}

class _ExpenseLimitsScreenState extends State<ExpenseLimitsScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _limits = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _months = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final limits = await _tursoService.getExpenseLimits();
    final departments = await _tursoService.getDepartments();
    final months = await _tursoService.getMonths();
    
    setState(() {
      _limits = limits;
      _departments = departments;
      _months = months;
      _isLoading = false;
    });
  }

  Future<void> _showLimitDialog([Map<String, dynamic>? limit]) async {
    final isEditing = limit != null;
    
    // Initial values
    int? selectedDeptId = limit?['deptId'];
    String? selectedMonth = limit?['month'];
    final limitController = TextEditingController(text: limit?['limit']?.toString());

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Use StatefulBuilder to update dropdowns in dialog
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Expense Limit' : 'Add Expense Limit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Department Dropdown
                DropdownButtonFormField<int>(
                  value: selectedDeptId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _departments.map((dept) {
                    return DropdownMenuItem<int>(
                      value: dept['id'],
                      child: Text(dept['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedDeptId = value);
                  },
                ),
                const SizedBox(height: 10),
                // Month Dropdown
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: _months.map((month) {
                    return DropdownMenuItem<String>(
                      value: month['name'],
                      child: Text(month['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMonth = value);
                  },
                ),
                const SizedBox(height: 10),
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
                  final amount = int.tryParse(limitController.text);

                  if (selectedDeptId == null || selectedMonth == null || amount == null) return;

                  String? error;
                  if (isEditing) {
                    error = await _tursoService.updateExpenseLimit(
                        limit['id'], selectedDeptId!, selectedMonth!, amount);
                  } else {
                    error = await _tursoService.createExpenseLimit(selectedDeptId!, selectedMonth!, amount);
                  }

                  if (error == null) {
                      if (mounted) _loadData();
                      navigator.pop();
                  } else {
                    navigator.pop(); // Close dialog first or show error on top? Better to show on top or keep dialog.
                    // Let's keep dialog open and show error? Or use ScaffoldMessenger.
                    // For simplicity, let's close and show SnackBar.
                    // Re-opening navigator reference might be tricky if popped.
                    // Actually, if we pop, we lose context for SnackBar helper if not careful.
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        }
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
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Manage Expense Limits'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLimitDialog(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _limits.length,
              itemBuilder: (context, index) {
                final limit = _limits[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.currency_rupee, color: Colors.white),
                    title: Text('${limit['month']} • ${limit['deptName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Limit: ₹${limit['limit']}', style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showLimitDialog(limit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteLimit(limit['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
