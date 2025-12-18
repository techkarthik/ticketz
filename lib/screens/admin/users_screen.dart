import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class UsersScreen extends StatefulWidget {
  final int organizationId;
  const UsersScreen({super.key, required this.organizationId});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await _tursoService.getUsers(widget.organizationId);
    final departments = await _tursoService.getDepartments(widget.organizationId);
    setState(() {
      _users = users;
      _departments = departments;
      _isLoading = false;
    });
  }

  Future<void> _showUserDialog([Map<String, dynamic>? user]) async {
    final isEditing = user != null;
    final usernameController = TextEditingController(text: user?['username']);
    final emailController = TextEditingController(text: user?['email']);
    final mobileController = TextEditingController(text: user?['mobile']);
    final passwordController = TextEditingController();
    
    // Default to first department if adding, or existing deptId if editing
    // Default to first department if adding, or existing deptId if editing
    int? selectedDeptId = user?['deptId'];
    if (selectedDeptId == 0) selectedDeptId = null; // Handle unassigned

    if (selectedDeptId == null && _departments.isNotEmpty && !isEditing) {
      selectedDeptId = _departments.first['id'];
    }

    // Role
    String selectedRole = user?['role'] ?? 'USER';
    final List<String> roles = ['ADMIN', 'USER'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2A38), // Dark background
            title: Text(
              isEditing ? 'Edit User' : 'Add User',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(usernameController, 'Username'),
                  const SizedBox(height: 10),
                  _buildTextField(passwordController, isEditing ? 'New Password (optional)' : 'Password', obscureText: true),
                  const SizedBox(height: 10),
                  _buildTextField(emailController, 'Email', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  _buildTextField(mobileController, 'Mobile', keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  // Department Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedDeptId,
                    dropdownColor: const Color(0xFF2C3E50),
                    decoration: InputDecoration(
                      labelText: 'Department',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
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
                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF2C3E50),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedRole = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final username = usernameController.text;
                  final password = passwordController.text;
                  final email = emailController.text;
                  final mobile = mobileController.text;

                  if (username.isEmpty) return;
                  if (!isEditing && password.isEmpty) return; // Password required for new
                  if (selectedDeptId == null) return;

                  bool success;
                  if (isEditing) {
                    success = await _tursoService.updateUser(
                      user['id'],
                      username,
                      password.isEmpty ? null : password,
                      email,
                      mobile,
                      selectedDeptId!,
                      selectedRole,
                    );
                  } else {
                    success = await _tursoService.createUser(
                      widget.organizationId,
                      username,
                      password,
                      email,
                      mobile,
                      selectedDeptId!,
                      selectedRole,
                    );
                  }

                  if (success) {
                    if (mounted) _loadData();
                    navigator.pop();
                  }
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A38),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this user?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
      await _tursoService.deleteUser(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.transparent, // Transparent for gradient
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  color: Colors.white.withOpacity(0.1), // Glassmorphism
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        (user['username'] as String).isNotEmpty ? user['username'][0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white)
                      ),
                    ),
                    title: Text('${user['username']} (${user['role']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${user['email']} • ${user['deptName']}', style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showUserDialog(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteUser(user['id']),
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
