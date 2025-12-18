import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class MonthsScreen extends StatefulWidget {
  // Removed Organization ID dependency as Months are now global/static
  final int organizationId; // Still kept for compatibility if needed, but unused for fetching
  const MonthsScreen({super.key, required this.organizationId});

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
    // Modified to call global getMonths()
    final months = await _tursoService.getMonths();
    setState(() {
      _months = months;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appBar: AppBar(
        title: const Text('Months'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        // Removed Actions (Create Button)
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _months.isEmpty
              ? const Center(
                  child: Text(
                    'No months found.\nPlease Initialize Database from Login Screen.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _months.length,
                  itemBuilder: (context, index) {
                    final month = _months[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            month['name'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          month['name'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        // Removed Trailing Actions (Edit/Delete)
                      ),
                    );
                  },
                ),
    );
  }
}
