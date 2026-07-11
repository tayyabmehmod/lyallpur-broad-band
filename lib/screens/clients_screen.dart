import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/client.dart';
import '../widgets/responsive_scaffold.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'active', 'expired'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      title: 'Clients Management',
      currentIndex: 1,
      body: Column(
        children: [
          // Filter & Search Header Card
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF0D1117),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by client name or phone...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.tertiary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips Row
                Row(
                  children: [
                    _buildFilterChip(label: 'All Clients', value: 'all', count: null),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: 'Active', value: 'active', color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: 'Expired', value: 'expired', color: Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF30363D)),

          // Clients Stream Builder list
          Expanded(
            child: StreamBuilder<List<ClientModel>>(
              stream: firebaseService.getClients(),
              initialData: FirebaseService.lastClients,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading clients: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allClients = snapshot.data ?? [];

                // 1. Filter by status in Dart
                var filteredClients = allClients;
                if (_selectedFilter != 'all') {
                  filteredClients = filteredClients
                      .where((c) => c.status.toLowerCase() == _selectedFilter)
                      .toList();
                }

                // 2. Filter by search query in Dart
                if (_searchQuery.isNotEmpty) {
                  filteredClients = filteredClients.where((c) {
                    final nameMatch = c.name.toLowerCase().contains(_searchQuery);
                    final phoneMatch = c.phone.contains(_searchQuery);
                    return nameMatch || phoneMatch;
                  }).toList();
                }

                if (filteredClients.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching client records found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    final isActive = client.status == 'active';
                    
                    // Expiry text calculation
                    final expiryDate = client.connectionDate.add(const Duration(days: 30));
                    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
                    
                    String statusText;
                    if (isActive) {
                      statusText = daysLeft >= 0 
                          ? 'Active • Expires in $daysLeft days' 
                          : 'Active • Expired ${-daysLeft} days ago';
                    } else {
                      final daysAgo = DateTime.now().difference(expiryDate).inDays;
                      statusText = daysAgo >= 0
                          ? 'Expired • $daysAgo days ago'
                          : 'Expired • Expires in ${-daysAgo} days';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      color: const Color(0xFF161B22),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive 
                              ? Colors.green.withValues(alpha: 0.1) 
                              : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            isActive ? Icons.wifi : Icons.wifi_off,
                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Plan: ${client.packageName} | $statusText',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/client_detail',
                            arguments: client.id,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    Color? color,
    int? count,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: theme.colorScheme.tertiary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.tertiary,
      labelStyle: TextStyle(
        color: isSelected
            ? (color ?? theme.colorScheme.tertiary)
            : Colors.grey[400],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: const Color(0xFF161B22),
      side: BorderSide(
        color: isSelected
            ? (color ?? theme.colorScheme.tertiary)
            : const Color(0xFF30363D),
      ),
    );
  }
}
