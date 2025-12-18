
import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class PendingExpensesScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const PendingExpensesScreen({super.key, required this.currentUser});

  @override
  State<PendingExpensesScreen> createState() => _PendingExpensesScreenState();
}

class _PendingExpensesScreenState extends State<PendingExpensesScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _pendingExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenses = await _tursoService.getPendingExpenses(widget.currentUser['organizationId']);
    setState(() {
      _pendingExpenses = expenses;
      _isLoading = false;
    });
  }

  Future<void> _approveExpense(int id) async {
    final success = await _tursoService.approveExpense(id, widget.currentUser['id']);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense Approved')));
        _loadData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to approve expense')));
      }
    }
  }

  Future<void> _rejectExpense(int id) async {
    final remarkController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A38),
        title: const Text('Reject Expense', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(
              controller: remarkController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason (e.g., duplicate, policy violation)',
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (remarkController.text.isEmpty) return;
              Navigator.pop(context); // Close dialog
              final success = await _tursoService.rejectExpense(
                id, 
                widget.currentUser['id'], 
                remarkController.text
              );
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense Rejected')));
                  _loadData();
                }
              } else {
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reject expense')));
                 }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Pending Approvals', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _pendingExpenses.isEmpty
              ? const Center(child: Text('No pending expenses to review', style: TextStyle(color: Colors.white70, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = _pendingExpenses[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(
                                   expense['username'] ?? 'Unknown User',
                                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                                 Text(
                                   '₹${expense['amount']}',
                                   style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 5),
                             Text(
                               '${expense['deptName']} • ${expense['date']}',
                               style: const TextStyle(color: Colors.white70, fontSize: 14),
                             ),
                             const SizedBox(height: 10),
                             Text(
                               expense['description'] ?? 'No description',
                               style: const TextStyle(color: Colors.white, fontSize: 15),
                             ),
                             const SizedBox(height: 15),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                 OutlinedButton.icon(
                                   onPressed: () => _rejectExpense(expense['id']),
                                   icon: const Icon(Icons.close, color: Colors.redAccent),
                                   label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                   style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                                 ),
                                 const SizedBox(width: 10),
                                 ElevatedButton.icon(
                                   onPressed: () => _approveExpense(expense['id']),
                                   icon: const Icon(Icons.check, color: Colors.white),
                                   label: const Text('Approve'),
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                 ),
                               ],
                             )
                           ],
                         ),
                      ),
                    );
                  },
                ),
    );
  }
}
