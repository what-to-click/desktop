import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:click_tracker/click_tracker.dart';
import 'package:click_tracker/click_tracker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:objectid/objectid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:what_to_click/src/domain/connection/extension.dart';
import 'package:what_to_click/src/injectable.dart';
import 'package:what_to_click/src/ui/click_track/widget/recorded_click.dart';
import 'package:what_to_click/src/ui/system_tray.dart';
import 'package:image/image.dart' as img;

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
        launchUrlString(
          'https://wtc.wrbl.xyz/desktop-session-decoder.html#$offer',
        ),
      );
      await extensionConnection.status$.firstWhere(
        (status) => status == ExtensionConnectionStatus.confirmed,
      );
      for (final (click, screenshotFile) in screenshots) {
        final bytes = await screenshotFile.readAsBytesAndCrop(click);
        final encodedBytes = base64Encode(bytes.toList());
        final sendId = ObjectId();
        var index = 0;
        final encodedChunks = encodedBytes.chunks.join();
        assert(encodedBytes == encodedChunks);
        for (final chunk in encodedBytes.chunks) {
          await extensionConnection.send(
            jsonEncode(
              {
                '_id': sendId.toString(),
                'order': index,
                'click': click.toMap(),
                'screenshot': chunk,
                'type': 'data',
              },
            ),
          );
          index++;
        }
      }
      await extensionConnection.send(jsonEncode({'type': 'end'}));
      // Make sure the last message is sent before closing the connection
      await Future.delayed(const Duration(seconds: 2));
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

extension on String {
  Iterable<String> get chunks sync* {
    const chunkLength = 4 * 1024;
    var cursor = 0;
    while (cursor != length) {
      final end = math.min(cursor + chunkLength, length);
      yield substring(cursor, end);
      cursor = end;
    }
  }
}

extension on File {
  Future<Uint8List> readAsBytesAndCrop(ClickPosition click) async {
    final image = await img.decodePngFile(path);
    final imageData = image!.data!;
    final ratio = imageData.width / click.screenWidth;
    const size = 300;
    final rect = _calcRect(click, size.toDouble());

    final cmd = img.Command()
      ..decodePngFile(path)
      ..copyCrop(
        x: (rect.left * ratio).toInt(),
        y: (rect.top * ratio).toInt(),
        width: (size * ratio).toInt(),
        height: (size * ratio).toInt(),
      )
      ..encodePng();

    return (await cmd.executeThread()).outputBytes!;
  }

  Rect _calcRect(ClickPosition click, double size) {
    final (x, y) = (click.x - size / 2, click.y - size / 2);
    final clickRect = Rect.fromLTWH(
      x,
      y,
      size,
      size,
    );
    final screenRect = Rect.fromLTWH(
      0,
      0,
      click.screenWidth,
      click.screenHeight,
    );
    final offset = Rect.fromLTRB(
      // how much to push it in from the left
      math.min(0.0, screenRect.left + clickRect.left).abs(),
      math.min(0.0, screenRect.top + clickRect.top).abs(),
      math.min(0.0, screenRect.right - clickRect.right).abs(),
      math.min(0.0, screenRect.bottom - clickRect.bottom).abs(),
    );
    final correctedX = x + offset.left - offset.right;
    final correctedY = y + offset.top - offset.bottom;
    return Rect.fromLTWH(correctedX, correctedY, size, size);
  }
}
