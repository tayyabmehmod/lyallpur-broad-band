import 'package:flutter/material.dart';
import '../models/area.dart';
import '../services/firebase_service.dart';
import '../widgets/responsive_scaffold.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({super.key});

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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
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
                              '${area.clientCount} Active Subscribers',
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
          );
        },
      ),
    );
  }
}
