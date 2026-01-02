import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Cards
            Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    icon: Icons.shield_outlined,
                    iconColor: Colors.blue,
                    title: 'Emergency Fund',
                    amount: '₹804.00',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceCard(
                    icon: Icons.currency_rupee_outlined,
                    iconColor: Colors.green,
                    title: 'Usable',
                    amount: '₹2,412.00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBalanceCard(
              icon: Icons.credit_card_outlined,
              iconColor: Colors.red,
              title: 'Debt Amount',
              amount: '₹267.00',
              isFullWidth: true,
            ),
            
            const SizedBox(height: 32),
            
            // Recent Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Transaction List
            _buildTransactionItem(
              icon: Icons.directions_car_outlined,
              title: 'Transport',
              subtitle: 'Monthly transport pass',
              amount: '- ₹80.00',
              date: 'Dec 15, 2025',
              isExpense: true,
            ),
            _buildTransactionItem(
              icon: Icons.bolt_outlined,
              title: 'Utilities',
              subtitle: 'Electricity and water bill',
              amount: '- ₹120.00',
              date: 'Dec 14, 2025',
              isExpense: true,
            ),
            _buildTransactionItem(
              icon: Icons.computer_outlined,
              title: 'Freelance',
              subtitle: 'Web development project',
              amount: '+ ₹800.00',
              date: 'Dec 13, 2025',
              isExpense: false,
            ),
            _buildTransactionItem(
              icon: Icons.shopping_cart_outlined,
              title: 'Groceries',
              subtitle: 'Weekly grocery shopping',
              amount: '- ₹45.00',
              date: 'Dec 12, 2025',
              isExpense: true,
            ),
            _buildTransactionItem(
              icon: Icons.house_outlined,
              title: 'Rent',
              subtitle: 'Monthly rent payment',
              amount: '- ₹500.00',
              date: 'Dec 10, 2025',
              isExpense: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isExpense ? Colors.red : Colors.green,
              size: 24,
            ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
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
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
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

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: const Color(0xFF1E1E1E),
      shape: const CircularNotchedRectangle(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', isSelected: true),
            _buildNavItem(Icons.receipt_long_outlined, 'Transactions'),
            const SizedBox(width: 40), // Space for the FAB
            _buildNavItem(Icons.chat_bubble_outline, 'AI Chat'),
            _buildNavItem(Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.green : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.green : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
