import 'package:flutter/widgets.dart';

import 'click_tracker_platform_interface.dart';

class ClickTracker {
  Stream<ClickPosition> clicks$(BuildContext context) =>
      ClickTrackerPlatform.instance.clicks$(context);
}
