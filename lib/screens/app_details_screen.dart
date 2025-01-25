import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For date formatting

class AppDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> app;

  const AppDetailsScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final appIcon = app['appIcon'] as Uint8List?;
    final appName = app['appName'] as String? ?? 'Unknown';
    final packageName = app['packageName'] as String? ?? 'Unknown';
    final versionName = app['versionName'] as String? ?? 'Unknown';
    final appSizeInBytes = app['appSize'] as int? ?? 0;
    final appSizeInMB =
        (appSizeInBytes / (1024 * 1024)).toStringAsFixed(2); // Convert to MB
    final installDate =
        DateTime.fromMillisecondsSinceEpoch(app['installDate'] as int? ?? 0);
    final formattedDate =
        DateFormat('MMM dd, yyyy').format(installDate); // Format date

    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon
            Center(
              child: appIcon != null
                  ? Image.memory(
                      appIcon,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.android, size: 100),
            ),
            const SizedBox(height: 20),

            // App Details
            _buildDetailRow('Package', packageName),
            _buildDetailRow('Version', versionName),
            _buildDetailRow('Size', '$appSizeInMB MB'), // Display size in MB
            _buildDetailRow(
                'Installed', formattedDate), // Display formatted date

            const SizedBox(height: 20),

            // Uninstall Button
            Center(
              child: ElevatedButton(
                onPressed: () => _confirmUninstall(context, packageName),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red, // Use a red color for destructive actions
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Uninstall App',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // Helper method to show a confirmation dialog before uninstalling
  void _confirmUninstall(BuildContext context, String packageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall App'),
        content: const Text('Are you sure you want to uninstall this app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pop(context); // Go back to the previous screen
              MethodChannel('com.example.app_list_flutter/apps')
                  .invokeMethod('uninstallApp', {'packageName': packageName});
            },
            child: const Text(
              'Uninstall',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
