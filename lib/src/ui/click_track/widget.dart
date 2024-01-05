import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:click_tracker/click_tracker.dart';
import 'package:click_tracker/click_tracker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:what_to_click/src/domain/connection/extension.dart';
import 'package:what_to_click/src/injectable.dart';
import 'package:what_to_click/src/ui/click_track/widget/recorded_click.dart';
import 'package:what_to_click/src/ui/system_tray.dart';

@RoutePage()
class ClickTrackPage extends StatefulWidget {
  const ClickTrackPage({super.key});

  @override
  State<ClickTrackPage> createState() => _ClickTrackPageState();
}

class _ClickTrackPageState extends State<ClickTrackPage> {
  late final StreamSubscription<ClickPosition> _clicksSub;
  late final StreamSubscription<bool> _systemTrayToggleSub;
  final ScreenCapturer capturer = ScreenCapturer.instance;
  final _systemTray = sl<SystemTrayManager>();
  List<(ClickPosition, File)> screenshots = [];

  @override
  void initState() {
    super.initState();
    _clicksSub = ClickTracker().clicks$(context).listen((event) async {
      if (!_systemTray.trayToggle) {
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final imageName = 'wtc-${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/clicks/$imageName';
      final capturedScreen = await capturer.capture(
        mode: CaptureMode.screen,
        imagePath: imagePath,
      );

      setState(() {
        screenshots.add((event, File(capturedScreen!.imagePath!)));
      });
    });
    _systemTrayToggleSub = _systemTray.trayToggle$.listen((isBusy) async {
      if (isBusy || screenshots.isEmpty) {
        return;
      }

      final extensionConnection = sl<ExtensionConnection>();
      final offer = await extensionConnection.serializedOffer();
      unawaited(
        launchUrlString('https://wtc.wrbl.xyz/connection-test.html#$offer'),
      );
      await extensionConnection.status$.firstWhere(
        (status) => status == ExtensionConnectionStatus.confirmed,
      );
      await extensionConnection.send('should start sending screenshots now');
      for (final (click, screenshotFile) in screenshots) {
        try {
          final bytes = screenshotFile.readAsBytesSync();
          await extensionConnection.send(
            jsonEncode(
              {
                'click': click.toMap(),
                // TODO: split the image into 1kB chunks to avoid
                // overloading the data stream implementation
                'screenshot': base64Encode(bytes.sublist(0, 1024).toList()),
              },
            ),
          );
        } catch (e) {
          log(e.toString());
        }
      }
      await extensionConnection.close();
    });
  }

  @override
  void dispose() {
    _clicksSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current session'),
      ),
      body: ListView.builder(
        itemCount: screenshots.length,
        itemBuilder: (context, index) {
          return RecordedClick(click: screenshots[index]);
        },
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  const FullScreenImage({
    super.key,
    required this.file,
  });
  final File file;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: InteractiveViewer(child: Image.file(file)),
      );
}

extension on ClickPosition {
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
    };
  }
}
