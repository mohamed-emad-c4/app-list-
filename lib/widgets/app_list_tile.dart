import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppListTile extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AppListTile({
    Key? key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appIcon = app['appIcon'] as Uint8List?;

    return ListTile(
      leading: appIcon != null
          ? Image.memory(
              appIcon,
              width: 40,
              height: 40,
            )
          : const Icon(Icons.android),
      title: Text(app['appName'] ?? 'Unknown'),
      subtitle: Text(app['packageName'] ?? 'Unknown'),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}