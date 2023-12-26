import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:what_to_click/src/app.dart';
import 'package:what_to_click/src/domain/connection/extension.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  log(
    serialize(
      await ExtensionConnection().beginConnection(),
    ),
  );

  runApp(const WhatToClickApp());
}
