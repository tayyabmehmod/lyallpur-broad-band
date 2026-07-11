import 'package:flutter/material.dart';
import 'sidebar.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final List<Widget>? actions;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AdminSidebar(currentIndex: currentIndex),
            const VerticalDivider(width: 1, color: Color(0xFF30363D)),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(title),
                  actions: actions,
                  automaticallyImplyLeading: false, // Hide menu/back icon on wide screens
                ),
                body: body,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
        ),
        drawer: AdminSidebar(currentIndex: currentIndex, isDrawer: true),
        body: body,
      );
    }
  }
}
