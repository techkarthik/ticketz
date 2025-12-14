import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class MonthsScreen extends StatefulWidget {
  const MonthsScreen({super.key});

  @override
  State<MonthsScreen> createState() => _MonthsScreenState();
}

class _MonthsScreenState extends State<MonthsScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _months = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    setState(() => _isLoading = true);
    final months = await _tursoService.getMonths();
    setState(() {
      _months = months;
      _isLoading = false;
    });
  }

  Future<void> _showMonthDialog([Map<String, dynamic>? month]) async {
    final isEditing = month != null;
    final nameController = TextEditingController(text: month?['name']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Month' : 'Add Month'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Month Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final name = nameController.text;

              if (name.isEmpty) return;

              bool success;
              if (isEditing) {
                success = await _tursoService.updateMonth(month['id'], name);
              } else {
                success = await _tursoService.createMonth(name);
              }

              if (success) {
                  if (mounted) _loadMonths();
                  navigator.pop();
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMonth(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this month?'),
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
      await _tursoService.deleteMonth(id);
      _loadMonths();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Manage Months'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMonthDialog(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final month = _months[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month, color: Colors.white),
                    title: Text(month['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showMonthDialog(month),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteMonth(month['id']),
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
