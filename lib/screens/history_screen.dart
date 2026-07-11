import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/responsive_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatPKR(double amount) {
    final formatStr = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return 'Rs. $formatStr';
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      title: 'History & Logs',
      currentIndex: 4,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.getPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading logs: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No payment logs or history available.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFF30363D)),
            itemBuilder: (context, index) {
              final log = logs[index];
              final amount = log['amount'] as double? ?? 0.0;
              final clientName = log['clientName']?.toString() ?? 'Unknown Subscriber';
              final note = log['note']?.toString() ?? 'Billing activity';
              final dateVal = log['date'] as DateTime? ?? DateTime.now();

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment, color: Colors.greenAccent, size: 22),
                ),
                title: Text(
                  clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: Text(
                  '$note • ${dateVal.toLocal().toString().split('.')[0]}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                trailing: Text(
                  '+ ${_formatPKR(amount)}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
