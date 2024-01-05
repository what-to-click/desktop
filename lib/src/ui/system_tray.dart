import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/subjects.dart';
import 'package:system_tray/system_tray.dart';

const _busyIconPath = 'assets/images/stop.svg';
const _idleIconPath = 'assets/images/record.svg';

@lazySingleton
class SystemTrayManager {
  final _systemTray = SystemTray();

  final _trayToggle = BehaviorSubject.seeded(false);
  Stream<bool> get trayToggle$ => _trayToggle.stream;

  Future<void> init() async {
    await _systemTray.initSystemTray(iconPath: _idleIconPath);
    _systemTray.registerSystemTrayEventHandler((eventName) {
      switch (eventName) {
        case kSystemTrayEventClick:
          _trayToggle.value = !_trayToggle.value;
      }
    });
    trayToggle$.listen((isToggled) {
      final task = isToggled ? showBusy : showIdle;
      unawaited(task());
    });
  }

  Future<void> showIdle() async {
    await _systemTray.setImage(_idleIconPath);
  }

  Future<void> showBusy() async {
    await _systemTray.setImage(_busyIconPath);
  }

  @disposeMethod
  void dispose() {
    unawaited(_trayToggle.close());
    unawaited(_systemTray.destroy());
  }
}
