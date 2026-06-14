import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String label;
  final String status;
  final Color statusColor;

  const ResultCard({
    super.key,
    required this.label,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}