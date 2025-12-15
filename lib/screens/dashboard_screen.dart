import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import 'admin/expense_types_screen.dart';
import 'admin/departments_screen.dart';
import 'expenses/add_expense_screen.dart';
import 'expenses/my_expenses_screen.dart';
import 'admin/expense_limits_screen.dart';
import 'admin/months_screen.dart';
import 'admin/users_screen.dart';
import 'admin/pending_expenses_screen.dart';
import 'login_screen.dart';
import '../services/turso_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Map<String, dynamic>>> _statsFuture;
  final _tursoService = TursoService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    if (widget.user['role'] == 'ADMIN') {
      final now = DateTime.now();
      final monthPrefix = now.toIso8601String().substring(0, 7); // YYYY-MM
      
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final monthName = monthNames[now.month - 1];

      _statsFuture = _tursoService.getDepartmentStats(monthPrefix, monthName);
    } else {
      _statsFuture = Future.value([]);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027), 
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('${widget.user['username']} (${widget.user['role'] ?? 'USER'})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                accountEmail: Text(widget.user['email'], style: const TextStyle(color: Colors.white70)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    widget.user['username'][0].toUpperCase(),
                    style: const TextStyle(fontSize: 28.0, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // Subtle separation
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
              ),
              if (widget.user['role'] == 'ADMIN') ...[
                _buildDrawerItem(context, Icons.done_all, 'Pending Approvals', PendingExpensesScreen(currentUser: widget.user)),
                _buildDrawerItem(context, Icons.people, 'Manage Users', const UsersScreen()),
                _buildDrawerItem(context, Icons.business, 'Manage Departments', const DepartmentsScreen()),
                _buildDrawerItem(context, Icons.category, 'Expense Types', const ExpenseTypesScreen()),
                _buildDrawerItem(context, Icons.calendar_today, 'Months', const MonthsScreen()),
                _buildDrawerItem(context, Icons.currency_rupee, 'Expense Limits', const ExpenseLimitsScreen()),
              ]
            ],
          ),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Reduced top padding as GradientBackground handles safe area/body behind app bar
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Max width for desktop
            child: Column(
              children: [
                const SizedBox(height: 60), // Add some spacing for AppBar
                // Welcome Summary Card (Glassmorphism)
                Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.2),
                         blurRadius: 10,
                         offset: const Offset(0, 5),
                       )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, size: 35, color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${widget.user['username']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            'Department: ${widget.user['deptName']}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (widget.user['role'] == 'ADMIN') ...[
                 _buildStatsCard(),
                 const SizedBox(height: 30),
              ],

              // Action Buttons Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.add_circle_outline,
                        label: 'New Expense',
                        color: ColorExtension.emerald,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddExpenseScreen(user: widget.user)),
                          ).then((_) {
                              if (widget.user['role'] == 'ADMIN') {
                                setState(() {
                                   _loadStats();
                                });
                              }
                          });
                        },
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.history,
                        label: 'My Expenses',
                        color: Colors.orangeAccent,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyExpensesScreen(user: widget.user)),
                          );
                        },
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text(
             'Department Expenses (Current Month)',
             style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 15),
           FutureBuilder<List<Map<String, dynamic>>>(
             future: _statsFuture,
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator(color: Colors.white));
               }
               if (snapshot.hasError) {
                 return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent));
               }
               if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return const Text('No approved expenses this month.', style: TextStyle(color: Colors.white70));
               }

               final stats = snapshot.data!;
               return ListView.separated(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 itemCount: stats.length,
                 separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.1)),
                 itemBuilder: (context, index) {
                   final item = stats[index];
                   final total = item['total'];
                   final limit = item['limit'];
                   
                   return Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(item['deptName'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                       Row(
                         children: [
                            Text(
                              '₹${total.toStringAsFixed(2)}', 
                              style: TextStyle(
                                color: (limit != null && total > limit) ? Colors.redAccent : Colors.white, 
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                            if (limit != null) ...[
                               Text(' / ₹$limit', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                            ]
                         ],
                       ),
                     ],
                   );
                 },
               );
             },
           )
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: 200, // Fixed reasonable width
      height: 150,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // Glassy background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
               gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
               ),
               boxShadow: [
                 BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,4))
               ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ).then((_) {
             // Refresh stats if coming back from pending approvals (approvals might have happened)
             if (widget.user['role'] == 'ADMIN' && title == 'Pending Approvals') {
                setState(() {
                  _loadStats();
                });
             }
        });
      },
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }
}

extension ColorExtension on Colors {
    static const Color emerald = Color(0xFF2ECC71);
}

