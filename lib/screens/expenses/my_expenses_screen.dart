import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class MyExpensesScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MyExpensesScreen({super.key, required this.user});

  @override
  State<MyExpensesScreen> createState() => _MyExpensesScreenState();
}

class _MyExpensesScreenState extends State<MyExpensesScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    
    // Filter by current month
    final now = DateTime.now();
    final monthPrefix = now.toIso8601String().substring(0, 7); // YYYY-MM

    final expenses = await _tursoService.getUserExpenses(widget.user['id'], monthPrefix: monthPrefix);
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this expense?'),
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
      final success = await _tursoService.deleteExpense(id);
      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Expense deleted successfully'), backgroundColor: Colors.green),
           );
           _loadExpenses();
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to delete expense'), backgroundColor: Colors.red),
           );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('My Expenses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Refresh on return
             _loadExpenses();
        },
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh), 
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _expenses.isEmpty 
              ? const Center(child: Text('No expenses found.', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.receipt_long, color: Colors.white),
                        ),
                        title: Text(expense['description'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${expense['date']}', style: const TextStyle(color: Colors.white70)),
                            if (expense['approverName'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                expense['status'] == 'Rejected' 
                                  ? 'Rejected by: ${expense['approverName']}'
                                  : 'Approved by: ${expense['approverName']}',
                                style: TextStyle(
                                  color: expense['status'] == 'Rejected' ? Colors.redAccent : Colors.greenAccent, 
                                  fontSize: 13, 
                                  fontStyle: FontStyle.italic
                                ),
                              ),
                            ],
                            if (expense['status'] == 'Rejected' && expense['remark'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${expense['remark']}',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${expense['amount']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  expense['status'],
                                  style: TextStyle(
                                    color: _getStatusColor(expense['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                            if (expense['status'] != 'Approved') ...[
                               const SizedBox(width: 8),
                               IconButton(
                                 icon: const Icon(Icons.delete, color: Colors.redAccent),
                                 onPressed: () => _deleteExpense(expense['id']),
                                 tooltip: 'Delete Expense',
                               ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
