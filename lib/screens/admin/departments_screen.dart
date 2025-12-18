import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class DepartmentsScreen extends StatefulWidget {
  final int organizationId;
  const DepartmentsScreen({super.key, required this.organizationId});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    final departments = await _tursoService.getDepartments(widget.organizationId);
    setState(() {
      _departments = departments;
      _isLoading = false;
    });
  }

  Future<void> _showDepartmentDialog([Map<String, dynamic>? dept]) async {
    final isEditing = dept != null;
    final nameController = TextEditingController(text: dept?['name']);
    String active = dept?['active'] ?? 'Y';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Department' : 'Add Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Department Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: active,
                decoration: const InputDecoration(labelText: 'Active'),
                items: const [
                  DropdownMenuItem(value: 'Y', child: Text('Yes')),
                  DropdownMenuItem(value: 'N', child: Text('No')),
                ],
                onChanged: (val) => setState(() => active = val!),
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
                final name = nameController.text;

                if (name.isEmpty) return;

                bool success;
                if (isEditing) {
                  success = await _tursoService.updateDepartment(
                      dept['id'], name, active);
                } else {
                  success = await _tursoService.createDepartment(widget.organizationId, name, active);
                }

                if (success) {
                    if (mounted) _loadDepartments();
                    navigator.pop();
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDepartment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this department?'),
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
      await _tursoService.deleteDepartment(id);
      _loadDepartments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Manage Departments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentDialog(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final dept = _departments[index];
                return Card(
                  color: Colors.white.withOpacity(0.1), // Glassmorphism
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.business, color: Colors.white),
                    title: Text(dept['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Active: ${dept['active']}', style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showDepartmentDialog(dept),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteDepartment(dept['id']),
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
