import 'dart:developer';

import 'package:click_tracker/click_tracker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:click_tracker/click_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _clicks = <ClickPosition>[];
  final _clickTrackerPlugin = ClickTracker();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    _clickTrackerPlugin.clicks$(context).listen((e) => setState(() {
          _clicks.add(e);
        }));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(
              'Clicks: ${_clicks.map<String>((c) => c.toString()).join('\n')}'),
        ),
      ),
    );
  }
}
