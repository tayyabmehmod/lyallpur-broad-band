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

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectPaymentDialog(BuildContext context, ClientModel client) {
    final amountController = TextEditingController(text: client.remaining > 0 ? client.remaining.toStringAsFixed(0) : '');
    final noteController = TextEditingController(text: 'Dues Payment');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
          title: const Text('Collect Dues Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the payment amount collected from "${client.name}".',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount (PKR) *',
                    hintText: 'e.g. 1000',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the amount';
                    }
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Payment Note',
                    hintText: 'e.g. Dues Payment, October paid',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185FA5),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amt = double.tryParse(amountController.text) ?? 0.0;
                final note = noteController.text.trim();

                Navigator.pop(context);

                try {
                  await FirebaseService().collectPayment(
                    clientId: client.id,
                    clientName: client.name,
                    amount: amt,
                    note: note,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment of Rs. ${amt.toStringAsFixed(0)} logged successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging payment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Collect'),
            ),
          ],
        );
      },
    );
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
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width >= 800;

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
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: isWideScreen
                              ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoTile(
                                            icon: Icons.phone_outlined,
                                            iconColor: Colors.blueAccent,
                                            title: 'Phone Number',
                                            subtitle: client.phone,
                                          ),
                                        ),
                                        Container(width: 1, height: 40, color: const Color(0xFF30363D)),
                                        Expanded(
                                          child: _buildInfoTile(
                                            icon: Icons.map_outlined,
                                            iconColor: Colors.purpleAccent,
                                            title: 'Service Area',
                                            subtitle: client.area.isEmpty ? 'None / Blank' : client.area,
                                          ),
                                        ),
                                        Container(width: 1, height: 40, color: const Color(0xFF30363D)),
                                        Expanded(
                                          child: _buildInfoTile(
                                            icon: Icons.speed,
                                            iconColor: Colors.orangeAccent,
                                            title: 'Subscription Package',
                                            subtitle: client.packageName,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 1, color: Color(0xFF30363D)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoTile(
                                            icon: Icons.calendar_today_outlined,
                                            iconColor: Colors.tealAccent,
                                            title: 'Billing Connection Date',
                                            subtitle: "${client.connectionDate.toLocal()}".split(' ')[0],
                                          ),
                                        ),
                                        Container(width: 1, height: 40, color: const Color(0xFF30363D)),
                                        Expanded(
                                          child: _buildInfoTile(
                                            icon: Icons.timer_outlined,
                                            iconColor: Colors.pinkAccent,
                                            title: 'Next Billing Due Date',
                                            subtitle: "${expiryDate.toLocal()}".split(' ')[0],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildInfoTile(
                                      icon: Icons.phone_outlined,
                                      iconColor: Colors.blueAccent,
                                      title: 'Phone Number',
                                      subtitle: client.phone,
                                    ),
                                    const Divider(height: 1, color: Color(0xFF30363D)),
                                    _buildInfoTile(
                                      icon: Icons.map_outlined,
                                      iconColor: Colors.purpleAccent,
                                      title: 'Service Area',
                                      subtitle: client.area.isEmpty ? 'None / Blank' : client.area,
                                    ),
                                    const Divider(height: 1, color: Color(0xFF30363D)),
                                    _buildInfoTile(
                                      icon: Icons.speed,
                                      iconColor: Colors.orangeAccent,
                                      title: 'Subscription Package',
                                      subtitle: client.packageName,
                                    ),
                                    const Divider(height: 1, color: Color(0xFF30363D)),
                                    _buildInfoTile(
                                      icon: Icons.calendar_today_outlined,
                                      iconColor: Colors.tealAccent,
                                      title: 'Billing Connection Date',
                                      subtitle: "${client.connectionDate.toLocal()}".split(' ')[0],
                                    ),
                                    const Divider(height: 1, color: Color(0xFF30363D)),
                                    _buildInfoTile(
                                      icon: Icons.timer_outlined,
                                      iconColor: Colors.pinkAccent,
                                      title: 'Next Billing Due Date',
                                      subtitle: "${expiryDate.toLocal()}".split(' ')[0],
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
                      isWideScreen
                          ? Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.secondary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _showCollectPaymentDialog(context, client),
                                    icon: const Icon(Icons.payment, color: Colors.white),
                                    label: const Text('Collect Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                  const SizedBox(width: 12),
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
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _showCollectPaymentDialog(context, client),
                                  icon: const Icon(Icons.payment, color: Colors.white),
                                  label: const Text('Collect Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
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
                                      const SizedBox(width: 12),
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
                    ],
                  ),
                );
              },
            ),
    );
  }
}
