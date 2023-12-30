import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:what_to_click/src/app.dart';
import 'package:what_to_click/src/domain/connection/extension.dart';
import 'package:what_to_click/src/pages/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final extensionConnection = ExtensionConnection();
  final serializedOffer = await extensionConnection.serializedOffer();
  await launchUrlString(
    'https://wtc.wrbl.xyz/connection-test.html#$serializedOffer',
  );

  final appRouter = AppRouter();

  linkStream.listen((link) {
    if (link == null) {
      return;
    }
    final uri = Uri.parse(link);
    final hash = uri.fragment;
    extensionConnection.confirmConnection(hash);
  });
  runApp(WhatToClickApp(appRouter: appRouter));
}
