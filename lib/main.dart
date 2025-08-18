import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger, Level;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:provider/provider.dart';

import 'shared/constants.dart' show appName, appDocPath;
import 'shared/dependencies.dart' show providers;
import 'shared/routing.dart' show router;

void main() async {
  Logger.root.level = kDebugMode ? Level.FINE : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '\u001b[1;33m${record.loggerName}.${record.level.name}: ${record.time}: ${record.message}\u001b[0m',
    );
  });
  // application document directory path
  WidgetsFlutterBinding.ensureInitialized();
  appDocPath = (await getApplicationDocumentsDirectory()).path;

  runApp(MultiProvider(providers: providers, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appName,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
