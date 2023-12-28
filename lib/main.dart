import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:what_to_click/src/app.dart';
import 'package:what_to_click/src/domain/connection/extension.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serializedOffer = await ExtensionConnection().serializedOffer();
  await launchUrlString(
    'https://wtc.wrbl.xyz/connection-test.html#$serializedOffer',
  );

  runApp(const WhatToClickApp());
}
