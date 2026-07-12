import 'package:flutter/material.dart';
import '../models/area.dart';
import '../services/firebase_service.dart';
import '../widgets/responsive_scaffold.dart';

class AreaScreen extends StatefulWidget {
  const AreaScreen({super.key});

  @override
  State<AreaScreen> createState() => _AreaScreenState();
}

class _AreaScreenState extends State<AreaScreen> {
  final _searchController = TextEditingController();
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

  // Open dialog to Add or Edit Area
  void _showAreaDialog(BuildContext context, {AreaModel? area}) {
    final controller = TextEditingController(text: area?.name ?? '');
    final formKey = GlobalKey<FormState>();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF30363D)),
              ),
              title: Text(
                area == null ? 'Add New Area' : 'Edit Area Name',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Area Name',
                        errorText: errorText,
                        hintText: 'e.g. Samanabad',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Area name cannot be empty';
                        }
                        return null;
                      },
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final newName = controller.text.trim();
                    try {
                      if (area == null) {
                        await FirebaseService().addArea(newName);
                      } else {
                        await FirebaseService().updateArea(area.id, newName);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setDialogState(() {
                        errorText = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Open confirmation dialog before deleting an area
  void _showDeleteConfirmation(BuildContext context, AreaModel area) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
          title: const Text('Delete Area?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text(
            'Are you sure you want to delete "${area.name}"?\n\n'
            'Clients assigned to it will not be deleted, but you may want to reassign them first.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85149), // Theme Error color
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await FirebaseService().deleteArea(area.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting area: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = FirebaseService();

    return ResponsiveScaffold(
      title: 'Areas',
      currentIndex: 2,
      actions: [
        IconButton(
          tooltip: 'Add Area',
          icon: const Icon(Icons.add),
          onPressed: () => _showAreaDialog(context),
        ),
      ],
      body: StreamBuilder<List<AreaModel>>(
        stream: firebaseService.getAreas(),
        initialData: FirebaseService.lastAreas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading areas: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final areas = snapshot.data ?? [];

          if (areas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Service Areas Defined',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You must add service areas to register clients.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Area'),
                      onPressed: () => _showAreaDialog(context),
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter areas based on search query
          final filteredAreas = areas.where((area) {
            return area.name.toLowerCase().contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Search Bar Header
              Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color(0xFF0D1117),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search areas...',
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
              ),
              const Divider(height: 1, color: Color(0xFF30363D)),
              Expanded(
                child: filteredAreas.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching areas found.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredAreas.length,
                        itemBuilder: (context, index) {
                          final area = filteredAreas[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF30363D), width: 1),
                            ),
                            color: const Color(0xFF161B22),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Row(
                                children: [
                                  // Lead visual badge
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.location_on_outlined, color: theme.colorScheme.tertiary),
                                  ),
                                  const SizedBox(width: 16),
                                  // Core details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          area.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'This area has ${area.clientCount} connection${area.clientCount == 1 ? '' : 's'}',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit Icon Button
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: Icon(Icons.edit_outlined, color: Colors.grey[400]),
                                    onPressed: () => _showAreaDialog(context, area: area),
                                  ),
                                  // Delete Icon Button
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFF85149)),
                                    onPressed: () => _showDeleteConfirmation(context, area),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
