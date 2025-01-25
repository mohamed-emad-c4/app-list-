import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'dart:typed_data';
import '../widgets/app_list_tile.dart';
import 'app_details_screen.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  _AppHomeScreenState createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  static const platform = MethodChannel('com.example.app_list_flutter/apps');
  List<Map<String, dynamic>> installedApps = [];
  List<Map<String, dynamic>> filteredApps = [];
  TextEditingController searchController = TextEditingController();
  String sortBy = 'appName';
  bool isLoading = true;
  bool showSystemApps = false;
  bool isDarkMode = false;
  Set<String> hiddenApps = {};
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    fetchInstalledApps();
  }

  Future<void> fetchInstalledApps() async {
    try {
      final List<dynamic> apps = await platform.invokeMethod('getInstalledApps');
      setState(() {
        installedApps = apps.map((e) => Map<String, dynamic>.from(e)).toList();
        filteredApps = List.from(installedApps);
        isLoading = false;
      });
    } on PlatformException catch (e) {
      print("Failed to get apps: ${e.message}");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshApps() async {
    setState(() {
      isLoading = true;
    });
    await fetchInstalledApps();
  }

  void filterApps(String query) {
    setState(() {
      filteredApps = installedApps.where((app) {
        final appName = app['appName'].toString().toLowerCase();
        final packageName = app['packageName'].toString().toLowerCase();
        return appName.contains(query.toLowerCase()) ||
            packageName.contains(query.toLowerCase());
      }).toList();
      sortApps();
    });
  }

  void sortApps() {
    setState(() {
      filteredApps.sort((a, b) {
        switch (sortBy) {
          case 'appName':
            return a['appName'].compareTo(b['appName']);
          case 'appSize':
            return (a['appSize'] as int).compareTo(b['appSize'] as int);
          case 'installDate':
            return (a['installDate'] as int).compareTo(b['installDate'] as int);
          default:
            return 0;
        }
      });
    });
  }

  void openApp(String packageName) async {
    try {
      await platform.invokeMethod('openApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to open app: ${e.message}");
    }
  }

  void uninstallApp(String packageName) async {
    try {
      await platform.invokeMethod('uninstallApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to uninstall app: ${e.message}");
    }
  }

  void shareApp(String appName, String packageName) async {
    try {
      await platform.invokeMethod('shareApp', {'appName': appName, 'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to share app: ${e.message}");
    }
  }

  void copyAppInfo(String appName, String packageName) {
    Clipboard.setData(ClipboardData(text: "App: $appName\nPackage: $packageName"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  void toggleSystemApps(bool value) {
    setState(() {
      showSystemApps = value;
      filteredApps = installedApps.where((app) {
        final isSystemApp = (app['installDate'] as int) == 0;
        return showSystemApps ? true : !isSystemApp;
      }).toList();
    });
  }

  void toggleDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps'),
        actions: [
         
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortBy = value;
                sortApps();
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'appName', child: Text('Sort by Name')),
              PopupMenuItem(value: 'appSize', child: Text('Sort by Size')),
              PopupMenuItem(value: 'installDate', child: Text('Sort by Install Date')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by app name or package...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: filterApps,
                  ),
                ),
                
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshApps,
                    child: filteredApps.isEmpty
                        ? const Center(child: Text("No apps found"))
                        : ListView.builder(
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              final app = filteredApps[index];
                              return AppListTile(
                                app: app,
                                onTap: () => openApp(app['packageName']),
                                onLongPress: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.info),
                                          title: const Text("App Details"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AppDetailsScreen(app: app),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.share),
                                          title: const Text("Share App"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            shareApp(app['appName'], app['packageName']);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.copy),
                                          title: const Text("Copy App Info"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            copyAppInfo(app['appName'], app['packageName']);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete),
                                          title: const Text("Uninstall App"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            uninstallApp(app['packageName']);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}