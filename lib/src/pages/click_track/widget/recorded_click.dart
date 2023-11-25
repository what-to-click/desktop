import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:click_tracker/click_tracker_platform_interface.dart';
import 'package:flutter/material.dart';

class RecordedClick extends StatelessWidget {
  const RecordedClick({required this.click, super.key});
  final (ClickPosition click, File imageFile) click;

  @override
  Widget build(BuildContext context) {
    final (click, file) = this.click;
    final rect = Rect.fromLTWH(
      click.x,
      click.y,
      click.screenWidth * .2,
      click.screenWidth * .2,
    );
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: click.screenWidth / click.screenHeight,
          child: ClickPainter(
            image: FileImage(file),
            rect: rect,
            clickPosition: click,
          ),
        ),
      ],
    );
  }
}

class ClickPainter extends StatefulWidget {
  const ClickPainter({
    required this.image,
    required this.rect,
    required this.clickPosition,
    super.key,
  });
  final ImageProvider image;
  final ClickPosition clickPosition;
  final Rect rect;

  @override
  ClickPainterState createState() => ClickPainterState();
}

class ClickPainterState extends State<ClickPainter> {
  Future<ui.Image> getImage(ImageProvider img) async {
    Completer<ImageInfo> completer = Completer();
    img
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: getImage(widget.image),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return paintImage(snapshot.data);
        } else {
          // Otherwise, display a loading indicator.
          return const Center(child: CircularProgressIndicator());
        }
      });

  CustomPaint paintImage(image) => CustomPaint(
        painter: ImagePainter(image, widget.rect, widget.clickPosition),
        child: SizedBox(
          width: widget.rect.width,
          height: widget.rect.height,
        ),
      );
}

class ImagePainter extends CustomPainter {
  ImagePainter(this.resImage, this.rectCrop, this.clickPosition);
  final ui.Image resImage;
  final Rect rectCrop;
  final ClickPosition clickPosition;

  final _imagePaint = Paint();
  final _paint = Paint()
    ..color = Colors.red.withOpacity(.8)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.butt;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      resImage,
      Rect.fromLTWH(
          0, 0, resImage.width.toDouble(), resImage.height.toDouble()),
      Offset.zero & size,
      _imagePaint,
    );
    final scale = size.longestSide / clickPosition.screenWidth;
    final scaledClickPosition = Offset(
      clickPosition.x * scale,
      clickPosition.y * scale,
    );
    canvas.drawCircle(scaledClickPosition, 8, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
