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
                        subtitle: Text('${expense['date']}', style: const TextStyle(color: Colors.white70)),
                        trailing: Column(
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
                      ),
                    );
                  },
                ),
    );
  }
}
