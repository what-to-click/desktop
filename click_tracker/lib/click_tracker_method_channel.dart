import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'click_tracker_platform_interface.dart';

/// An implementation of [ClickTrackerPlatform] that uses method channels.
class EventChannelClickTracker extends ClickTrackerPlatform {
  EventChannelClickTracker();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('click_tracker');

  @override
  Stream<ClickPosition> clicks$(BuildContext context) => eventChannel
      .receiveBroadcastStream('clicks')
      .map<ClickPosition>((event) => ClickPosition.fromMap(event));
}
