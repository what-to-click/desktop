import 'dart:async';
import 'dart:io';

import 'package:click_tracker/click_tracker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:click_tracker/click_tracker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:what_to_click/src/pages/click_track/widget/recorded_click.dart';

class ClickTrackPage extends StatefulWidget {
  const ClickTrackPage({super.key});

  @override
  State<ClickTrackPage> createState() => _ClickTrackPageState();
}

class _ClickTrackPageState extends State<ClickTrackPage> {
  late final StreamSubscription<ClickPosition> _clicksSub;
  final ScreenCapturer capturer = ScreenCapturer.instance;
  List<(ClickPosition, File)> screenshots = [];

  @override
  void initState() {
    super.initState();
    _clicksSub = ClickTracker().clicks$(context).listen((event) async {
      final directory = await getApplicationDocumentsDirectory();
      final imageName = 'wtc-${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/clicks/$imageName';
      final capturedScreen = await capturer.capture(
        mode: CaptureMode.screen,
        imagePath: imagePath,
        silent: true,
      );

      setState(() {
        screenshots.add((event, File(capturedScreen!.imagePath!)));
      });
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
