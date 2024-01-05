import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:what_to_click/src/app.dart';
import 'package:what_to_click/src/domain/connection/extension.dart';
import 'package:what_to_click/src/injectable.dart';
import 'package:what_to_click/src/ui/system_tray.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  setupDeeplinkListener();
  sl<SystemTrayManager>().init();
  runApp(WhatToClickApp());
}

void setupDeeplinkListener() {
  final extensionConnection = sl<ExtensionConnection>();
  linkStream.listen((link) {
    if (link == null ||
        extensionConnection.status != ExtensionConnectionStatus.begin) {
      return;
    }

    final uri = Uri.parse(link);
    final hash = uri.fragment;
    extensionConnection.confirmConnection(hash);
  });
}
