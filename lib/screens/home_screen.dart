// lib/screens/home_screen.dart
import 'transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/transactions_data.dart';
import '../utils/formatters.dart';
import '../services/database_service.dart';
import '../models/user_settings.dart';
import '../models/monthly_debt_history.dart';
import '../models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _transactions = [];
  UserSettings? _userSettings;
  List<MonthlyDebtHistory> _monthlyDebtHistory = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // For demo purposes, we'll use a fixed user ID
      // In a real app, this would come from Supabase Auth
      _dbService.setUserId('demo-user');
      
      final results = await Future.wait([
        _dbService.getTransactions(),
        _dbService.getOrCreateUserSettings(),
        _dbService.getMonthlyDebtHistory(),
        _dbService.getCategories(),
      ]);
      
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _userSettings = results[1] as UserSettings;
        _monthlyDebtHistory = results[2] as List<MonthlyDebtHistory>;
        _categories = results[3] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper methods for date handling
  List<DateTime> _getLastMonths(int count) {
    final now = DateTime.now();
    final List<DateTime> months = [];
    for (int i = count - 1; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }
    return months;
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _addTransactionToDatabase(Transaction transaction, String category, int amount) async {
    try {
      // Add transaction
      await _dbService.addTransaction(transaction);
      
      // Update user settings if it's a debt payment
      if (category == 'Debt Payment' && _userSettings != null) {
        final newDebtAmount = (_userSettings!.currentDebt - amount).clamp(0, double.infinity).toInt();
        final updatedSettings = _userSettings!.copyWith(currentDebt: newDebtAmount);
        await _dbService.updateUserSettings(updatedSettings);
        
        // Update monthly debt history
        await _dbService.updateMonthlyDebt(DateTime.now(), newDebtAmount);
      }
      
      // Refresh data
      await _initializeData();
    } catch (e) {
      print('Error adding transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding transaction: $e')),
      );
    }
  }
  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAddTransactionDialog(context);
      },
    );
  }

  // Build Add Transaction Dialog
  Widget _buildAddTransactionDialog(BuildContext context) {
    String selectedCategory = 'Shopping';
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool isExpense = true;

    final List<Map<String, dynamic>> categories = [
      {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
      {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.red},
      {'name': 'Rent', 'icon': Icons.home, 'color': Colors.orange},
      {'name': 'Miscellaneous', 'icon': Icons.receipt, 'color': Colors.blue},
      {'name': 'Debt Payment', 'icon': Icons.payments, 'color': Colors.teal},
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Add Transaction',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            isExpense = true;
                            if (selectedCategory == 'Income') {
                              selectedCategory = 'Shopping';
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isExpense ? Colors.red[900] : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Expense',
                                style: GoogleFonts.poppins(
                                  color: isExpense ? Colors.white : Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            isExpense = false;
                            selectedCategory = 'Income';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isExpense ? Colors.green[900] : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Income',
                                style: GoogleFonts.poppins(
                                  color: !isExpense ? Colors.white : Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
                  decoration: InputDecoration(
                    prefixText: '₹',
                    prefixStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
                    hintText: '0.00',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection
                if (isExpense) ...[
                  Text(
                    'Category',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      bool isSelected = selectedCategory == category['name'];
                      return ChoiceChip(
                        label: Text(
                          category['name'],
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedCategory = category['name'];
                              if (selectedCategory == 'Debt Payment') {
                                isExpense = true;
                              }
                            });
                          }
                        },
                        backgroundColor: Colors.grey[900],
                        selectedColor: category['color'].withOpacity(0.3),
                        side: BorderSide(
                          color: isSelected
                              ? category['color']
                              : Colors.grey[700]!,
                        ),
                        avatar: Icon(
                          category['icon'],
                          size: 16,
                          color: isSelected ? category['color'] : Colors.grey[400],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.18)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.green[300],
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Category: Income',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                TextField(
                  controller: descriptionController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.notes, color: Colors.grey, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  final amountPaise = (amount * 100).toInt();
                  final effectiveCategory = isExpense ? selectedCategory : 'Income';
                  final effectiveIsExpense = effectiveCategory == 'Debt Payment'
                      ? true
                      : isExpense;
                  final effectiveColor = !effectiveIsExpense
                      ? Colors.green
                      : (categories.firstWhere(
                          (cat) => cat['name'] == effectiveCategory,
                          orElse: () => {'color': Colors.blue},
                        )['color'] as Color);
                  final newTransaction = Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: effectiveCategory,
                    subtitle: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : 'No description',
                    amount: amountPaise, // Convert to paise
                    date: DateTime.now(),
                    isExpense: effectiveIsExpense,
                    category: effectiveCategory,
                    color: effectiveColor,
                  );

                  // Add transaction to database
                  _addTransactionToDatabase(newTransaction, effectiveCategory, amountPaise);

                  // Add to global transactions list
                  addTransaction(newTransaction);

                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Add ${isExpense ? 'Expense' : 'Income'}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show edit budget dialog
  void _showEditBudgetDialog() {
    final TextEditingController budgetController =
        TextEditingController(text: ((_userSettings?.monthlyBudget ?? 300000) / 100).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Edit Monthly Budget',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter monthly budget',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixText: '₹',
              prefixStyle: GoogleFonts.poppins(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBudget = (double.tryParse(budgetController.text) ?? 0) * 100;
                if (_userSettings != null) {
                  final updatedSettings = _userSettings!.copyWith(monthlyBudget: newBudget.toInt());
                  await _dbService.updateUserSettings(updatedSettings);
                  await _initializeData();
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDebtDialog() {
    final TextEditingController debtController =
        TextEditingController(text: ((_userSettings?.currentDebt ?? 0) / 100).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Edit Debt',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: TextField(
            controller: debtController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter debt amount',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixText: '₹',
              prefixStyle: GoogleFonts.poppins(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                final parsed = double.tryParse(debtController.text) ?? 0;
                final newDebtAmount = (parsed < 0 ? 0 : parsed) * 100;
                if (_userSettings != null) {
                  final updatedSettings = _userSettings!.copyWith(currentDebt: newDebtAmount.toInt());
                  await _dbService.updateUserSettings(updatedSettings);
                  await _dbService.updateMonthlyDebt(DateTime.now(), newDebtAmount.toInt());
                  await _initializeData();
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebtGraph() {
    final months = _getLastMonths(6);
    double maxValue = 0;
    final Map<String, double> debtHistory = {};
    
    // Convert MonthlyDebtHistory to map format
    for (final history in _monthlyDebtHistory) {
      debtHistory[_monthKey(history.month)] = history.debtAmount.toDouble();
    }
    
    for (final month in months) {
      final v = debtHistory[_monthKey(month)] ?? 0;
      if (v > maxValue) maxValue = v;
    }
    if (maxValue <= 0) maxValue = 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debt Trend',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last 6 months',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((month) {
                final value = debtHistory[_monthKey(month)] ?? 0;
                final ratio = (value / maxValue).clamp(0.0, 1.0);
                final barColor = value > 0 ? Colors.red[300] : Colors.green[300];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 90 * ratio,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: (barColor ?? Colors.grey).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM').format(month),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${formatIndianCurrency((_userSettings?.currentDebt ?? 0).toDouble())}',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }
    
    final now = DateTime.now();
    final monthlyTransactions = _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
    final monthlySpent = monthlyTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount.toDouble());
    final totalChange = _transactions.fold<double>(
      0,
      (sum, t) =>
          sum + (t.isExpense ? -t.amount.toDouble() : t.amount.toDouble()),
    );
    final totalBalance = (_userSettings?.startingBalance ?? 789050) + totalChange;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'John Doe',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[900]?.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Balance Summary
              Text(
                'Balance Summary',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Balance Cards
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceCard(
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.green,
                      title: 'Total Balance',
                      amount: formatIndianCurrency(totalBalance),
                      isFullWidth: false,
                      trend: Icons.trending_up,
                      trendColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBalanceCard(
                      icon: Icons.credit_card,
                      iconColor: Colors.orange,
                      title: 'Monthly Spend',
                      amount: formatIndianCurrency(monthlySpent),
                      isFullWidth: false,
                      trend: Icons.trending_down,
                      trendColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBudgetProgress(
                title: 'Monthly Budget',
                spent: monthlySpent,
                total: (_userSettings?.monthlyBudget ?? 300000).toDouble(),
                color: Colors.red,
                onEdit: _showEditBudgetDialog,
              ),
              const SizedBox(height: 12),

              // Debt Card
              InkWell(
                onTap: _showEditDebtDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E1E1E),
                        (_userSettings?.currentDebt ?? 0) > 0
                            ? const Color(0xFF2A1414)
                            : const Color(0xFF162414),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ((_userSettings?.currentDebt ?? 0) > 0 ? Colors.red : Colors.green)
                          .withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ((_userSettings?.currentDebt ?? 0) > 0 ? Colors.red : Colors.green)
                              .withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payments,
                          color: (_userSettings?.currentDebt ?? 0) > 0 ? Colors.red[300] : Colors.green[300],
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Debt',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ((_userSettings?.currentDebt ?? 0) > 0 ? Colors.red : Colors.green)
                                        .withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    (_userSettings?.currentDebt ?? 0) > 0 ? 'You owe' : 'No debt',
                                    style: GoogleFonts.poppins(
                                      color: (_userSettings?.currentDebt ?? 0) > 0
                                          ? Colors.red[200]
                                          : Colors.green[200],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatIndianCurrency((_userSettings?.currentDebt ?? 0).toDouble()),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to edit',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildDebtGraph(),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: Colors.blue[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._transactions.take(3).map((transaction) => _buildTransactionItem(
                    icon: _getIconForCategory(transaction.category),
                    title: transaction.title,
                    subtitle: '${transaction.subtitle} • ${_formatDate(transaction.date)}',
                    amount: formatIndianCurrency(transaction.amount.toDouble()),
                    date: _formatDate(transaction.date),
                    isExpense: transaction.isExpense,
                    color: transaction.color,
                  )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required IconData trend,
    required Color trendColor,
    bool isFullWidth = true,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            iconColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Icon(trend, color: trendColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress({
    required String title,
    required double spent,
    required double total,
    required Color color,
    required VoidCallback onEdit,
  }) {
    final progress = total <= 0 ? 0.0 : (spent / total);
    final remaining = total - spent;
    final barColor = progress >= 0.85 ? Colors.red : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            barColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.grey[300]),
                      const SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[200],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatIndianCurrency(spent)} spent',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                '${formatIndianCurrency(total)} total',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            backgroundColor: Colors.grey[800],
            color: barColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: progress >= 0.85 ? Colors.red[200] : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                '${formatIndianCurrency(remaining)} left',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required bool isExpense,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.poppins(
                  color: isExpense ? Colors.red[300] : Colors.green[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'rent':
        return Icons.home;
      case 'salary':
        return Icons.account_balance_wallet;
      case 'miscellaneous':
        return Icons.receipt;
      case 'debt payment':
        return Icons.payments;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}