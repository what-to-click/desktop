import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'click_tracker_method_channel.dart';

abstract class ClickTrackerPlatform extends PlatformInterface {
  /// Constructs a ClickTrackerPlatform.
  ClickTrackerPlatform() : super(token: _token);

  Stream<ClickPosition> clicks$(BuildContext context);

  static final Object _token = Object();

  static ClickTrackerPlatform _instance = EventChannelClickTracker();

  /// The default instance of [ClickTrackerPlatform] to use.
  ///
  /// Defaults to [EventChannelClickTracker].
  static ClickTrackerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ClickTrackerPlatform] when
  /// they register themselves.
  static set instance(ClickTrackerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}

@immutable
class ClickPosition {
  final double x;
  final double y;
  final double screenWidth;
  final double screenHeight;

  Offset get relative => Offset(x / screenWidth, y / screenHeight);

  const ClickPosition({
    required this.x,
    required this.y,
    required this.screenWidth,
    required this.screenHeight,
  });

  ClickPosition.fromMap(Map<Object?, Object?> map)
      : x = map['x'] as double,
        y = map['y'] as double,
        screenWidth = map['screenWidth'] as double,
        screenHeight = map['screenHeight'] as double;

  @override
  String toString() =>
      'ClickPosition(x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)}, screenWidth: $screenWidth, screenHeight: $screenHeight, relative: $relative)';
}
