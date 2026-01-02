// lib/data/transactions_data.dart
import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String title;
  final String subtitle;
  final int amount; // in paise
  final DateTime date;
  final bool isExpense;
  final String category;
  final Color color;
  final String? categoryId; // Foreign key to categories table

  const Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
    required this.color,
    this.categoryId,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      amount: map['amount'] ?? 0,
      date: DateTime.parse(map['date']),
      isExpense: map['is_expense'] ?? true,
      category: map['category'] ?? '',
      color: Color(int.parse(map['color'].replaceFirst('#', '0xFF'))),
      categoryId: map['category_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'is_expense': isExpense,
      'category': category,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'category_id': categoryId,
    };
  }

  Transaction copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? amount,
    DateTime? date,
    bool? isExpense,
    String? category,
    Color? color,
    String? categoryId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      category: category ?? this.category,
      color: color ?? this.color,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

// Sample transactions (kept for fallback/reference)
List<Transaction> transactions = [
  Transaction(
    id: '1',
    title: 'Shopping',
    subtitle: 'Amazon',
    amount: 250000, // ₹2,500.00
    date: DateTime.now().subtract(const Duration(days: 1)),
    isExpense: true,
    category: 'Shopping',
    color: Colors.purple,
  ),
  // Add more sample transactions as needed
];

// Get recent transactions (kept for fallback/reference)
List<Transaction> getRecentTransactions({int? limit}) {
  final sorted = List<Transaction>.from(transactions);
  sorted.sort((a, b) => b.date.compareTo(a.date));
  return limit != null ? sorted.take(limit).toList() : sorted;
}

// Add a new transaction to the global list (kept for fallback/reference)
void addTransaction(Transaction transaction) {
  transactions.insert(0, transaction); // Add to the beginning to maintain reverse chronological order
}