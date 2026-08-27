import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:yamp/home.dart';
import 'package:yamp/prefs.dart';
import 'package:yamp/update.dart' as updater;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();

  final customTitleBar =
      (await Prefs.getCustomTitlebar()) ?? Defaults.customTitleBar;
  final windowOptions = WindowOptions(
    size: Size(400, 490),
    titleBarStyle: customTitleBar ? .hidden : .normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.setResizable(false);
  await windowManager.setMaximizable(false);

  updater.UpdateInfo? updateInfo;
  final autoCheckUpdates =
      (await Prefs.getAutoCheckUpdates()) ?? Defaults.autoCheckUpdates;
  final skippedVersion = await Prefs.getSkippedVersion();
  if (autoCheckUpdates) updateInfo = await updater.checkForUpdate();
  if (updateInfo?.latestVersion == skippedVersion) updateInfo = null;

  String? openFilePath = Platform.isWindows ? args.firstOrNull : null;

  runApp(MyApp(openFilePath, updateInfo));
}

const mainColor = Color(0xFFA2845E);

class MyApp extends StatelessWidget {
  const MyApp(this.openFilePath, this.updateInfo, {super.key});

  final String? openFilePath;
  final updater.UpdateInfo? updateInfo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: .dark(primary: Colors.white),
        tooltipTheme: TooltipThemeData(
          waitDuration: Duration(milliseconds: 500),
          verticalOffset: 30,
        ),
        textTheme: TextTheme(bodySmall: TextStyle(color: Color(0xFFAFAFAF))),
      ),
      home: HomePage(openFilePath, updateInfo),
      debugShowCheckedModeBanner: false,
    );
  }
}
