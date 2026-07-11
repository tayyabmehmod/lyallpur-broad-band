import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/client.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key});

  String _formatPKR(double amount) {
    final formatStr = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return 'Rs. $formatStr';
  }

  void _showRenewDialog(BuildContext context, ClientModel client) {
    final amountController = TextEditingController(text: client.totalBill.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Text('Renew Client Subscription', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the paid amount for renewal cycle of "${client.name}".',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Paid Amount (PKR)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF30363D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                Navigator.pop(context);
                try {
                  await FirebaseService().renewClient(client.id, amt);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subscription renewed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context); // Go back
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Renewal failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Renew', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _suspendClient(BuildContext context, ClientModel client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Text('Suspend Subscription?', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to suspend "${client.name}"? This sets their subscription status to Expired.',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Suspend', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseService().suspendClient(client.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription suspended'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context); // Go back
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to suspend: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
      ),
      body: clientId.isEmpty
          ? const Center(child: Text('No Client ID specified.'))
          : StreamBuilder<ClientModel?>(
              stream: FirebaseService().getClientById(clientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading details: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final client = snapshot.data;
                if (client == null) {
                  return const Center(
                    child: Text(
                      'Client record not found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final isActive = client.status == 'active';
                final expiryDate = client.connectionDate.add(const Duration(days: 30));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Profile Card
                      Card(
                        color: const Color(0xFF161B22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF30363D)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                child: Icon(
                                  isActive ? Icons.wifi : Icons.wifi_off,
                                  size: 48,
                                  color: isActive ? Colors.greenAccent : Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                client.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                                child: Text(
                                  client.status.toUpperCase(),
                                  style: TextStyle(
                                    color: isActive ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Information Grid Cards
                      Card(
                        color: const Color(0xFF161B22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF30363D)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.phone_outlined, color: Colors.blueAccent),
                                title: const Text('Phone Number', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                subtitle: Text(client.phone, style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                              const Divider(color: Color(0xFF30363D)),
                              ListTile(
                                leading: const Icon(Icons.map_outlined, color: Colors.purpleAccent),
                                title: const Text('Service Area', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                subtitle: Text(client.area, style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                              const Divider(color: Color(0xFF30363D)),
                              ListTile(
                                leading: const Icon(Icons.speed, color: Colors.orangeAccent),
                                title: const Text('Subscription Package', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                subtitle: Text(client.packageName, style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                              const Divider(color: Color(0xFF30363D)),
                              ListTile(
                                leading: const Icon(Icons.calendar_today_outlined, color: Colors.tealAccent),
                                title: const Text('Billing Connection Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                subtitle: Text(
                                  "${client.connectionDate.toLocal()}".split(' ')[0],
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                              const Divider(color: Color(0xFF30363D)),
                              ListTile(
                                leading: const Icon(Icons.timer_outlined, color: Colors.pinkAccent),
                                title: const Text('Next Billing Due Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                subtitle: Text(
                                  "${expiryDate.toLocal()}".split(' ')[0],
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bill Dues Details Card
                      Card(
                        color: const Color(0xFF161B22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF30363D)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Billing Cycle Ledger',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monthly Package Bill:', style: TextStyle(color: Colors.grey)),
                                  Text(_formatPKR(client.totalBill), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Paid Amount:', style: TextStyle(color: Colors.grey)),
                                  Text(_formatPKR(client.totalPaid), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const Divider(color: Color(0xFF30363D)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Outstanding Dues:', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    _formatPKR(client.remaining),
                                    style: TextStyle(
                                      color: client.remaining > 0 ? Colors.redAccent : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _showRenewDialog(context, client),
                              icon: const Icon(Icons.replay_circle_filled_outlined, color: Colors.white),
                              label: const Text('Renew Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _suspendClient(context, client),
                                icon: const Icon(Icons.do_disturb_on_outlined, color: Colors.red),
                                label: const Text('Suspend', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
