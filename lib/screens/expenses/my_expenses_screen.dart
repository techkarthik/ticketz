import 'package:flutter/material.dart';
import '../../services/turso_service.dart';

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
    final expenses = await _tursoService.getUserExpenses(widget.user['id']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Expenses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty 
              ? const Center(child: Text('No expenses found.'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.receipt_long),
                        ),
                        title: Text(expense['description']),
                        subtitle: Text('${expense['date']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${expense['amount']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Refresh on return
             _loadExpenses();
        },
        child: const Icon(Icons.refresh), // Just refresh for now, add logic handled in dashboard
      ),
    );
  }
}
