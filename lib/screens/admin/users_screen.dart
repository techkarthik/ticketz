import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _tursoService = TursoService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _tursoService.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _showUserDialog([Map<String, dynamic>? user]) async {
    final isEditing = user != null;
    final usernameController = TextEditingController(text: user?['username']);
    final emailController = TextEditingController(text: user?['email']);
    final mobileController = TextEditingController(text: user?['mobile']);
    final deptIdController = TextEditingController(text: user?['deptId']?.toString());
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Add User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'New Password (optional)' : 'Password',
                ),
                obscureText: true,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              TextField(
                controller: deptIdController,
                decoration: const InputDecoration(labelText: 'Department ID'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final username = usernameController.text;
              final password = passwordController.text;
              final email = emailController.text;
              final mobile = mobileController.text;
              final deptId = int.tryParse(deptIdController.text) ?? 5; // Default to Admin

              if (username.isEmpty) return;
              if (!isEditing && password.isEmpty) return; // Password required for new

              bool success;
              if (isEditing) {
                success = await _tursoService.updateUser(
                  user['id'],
                  username,
                  password.isEmpty ? null : password,
                  email,
                  mobile,
                  deptId,
                );
              } else {
                success = await _tursoService.createUser(
                  username,
                  password,
                  email,
                  mobile,
                  deptId,
                );
              }

              if (success) {
                if (mounted) _loadUsers();
                navigator.pop();
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
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
      await _tursoService.deleteUser(id);
      _loadUsers();
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
                      child: Text(user['username'][0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(user['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
