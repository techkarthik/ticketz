
import 'package:flutter/material.dart';
import '../../services/turso_service.dart';
import '../../widgets/gradient_background.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AddExpenseScreen({super.key, required this.user});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _tursoService = TursoService();
  final _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _expenseTypes = [];
  String? _selectedTypeId;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  // Mapping of DateTime months to string names stored in DB
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final types = await _tursoService.getExpenseTypes(widget.user['organizationId']);
    setState(() {
      _expenseTypes = types;
    });
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final amount = int.parse(_amountController.text);
    final monthName = _monthNames[_selectedDate.month - 1]; // 0-indexed array, 1-indexed month
    
    // 1. Check Limit
    final limit = await _tursoService.checkExpenseLimit(widget.user['organizationId'], widget.user['deptId'], monthName);
    // Fetch current department spending
    String monthPrefix = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";
    final currentSpending = await _tursoService.getDepartmentCurrentSpending(
       widget.user['organizationId'], 
       widget.user['deptId'], 
       monthPrefix
    );

    if (limit != -1 && (currentSpending + amount) > limit) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limit Exceeded'),
          content: Text('This expense of ₹$amount exceeds your department limit of ₹$limit for $monthName.\nCurrent Spending: ₹$currentSpending'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 2. Submit
    final success = await _tursoService.createExpense(
      widget.user['organizationId'], // Pass organizationId
      widget.user['id'],
      int.parse(_selectedTypeId!),
      amount,
      _selectedDate.toIso8601String().split('T')[0],
      _descriptionController.text
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense submitted successfully')),
      );
    } else {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit expense')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputDecor = InputDecoration(
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      border: OutlineInputBorder(),
    );
    const textStyle = TextStyle(color: Colors.white);

    return GradientBackground(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                     DropdownButtonFormField<String>(
                      value: _selectedTypeId,
                      dropdownColor: const Color(0xFF2C5364), // Dark background for dropdown menu
                      style: textStyle,
                      decoration: inputDecor.copyWith(labelText: 'Expense Type'),
                      items: _expenseTypes.map((t) {
                        return DropdownMenuItem(
                          value: t['id'].toString(),
                          child: Text(t['type']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTypeId = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: inputDecor.copyWith(labelText: 'Amount'),
                      style: textStyle,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (int.tryParse(val) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecor.copyWith(labelText: 'Description'),
                      style: textStyle,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date: ${_selectedDate.toIso8601String().split('T')[0]}', style: textStyle),
                      trailing: const Icon(Icons.calendar_today, color: Colors.white),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitExpense,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF2ECC71), // Emerald
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
