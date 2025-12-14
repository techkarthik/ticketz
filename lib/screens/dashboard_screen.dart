import 'package:flutter/material.dart';
import 'admin/expense_types_screen.dart';
import 'admin/departments_screen.dart';
import 'expenses/add_expense_screen.dart';
import 'expenses/my_expenses_screen.dart';
import 'admin/expense_limits_screen.dart';
import 'admin/months_screen.dart';
import 'admin/users_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user['username']),
              accountEmail: Text(user['email']),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user['username'][0].toUpperCase(),
                  style: const TextStyle(fontSize: 24.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Users'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Manage Departments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DepartmentsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Expense Types'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseTypesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Months'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonthsScreen()),
                );
              },
            ),
             ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Expense Limits'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseLimitsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Welcome Card
            Card(
              color: Colors.deepPurple[50],
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                   const  CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${user['username']}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Dept ID: ${user['deptId']}', style: TextStyle(color: Colors.grey[700])),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddExpenseScreen(user: user)),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyExpensesScreen(user: user)),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('My Expenses'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
