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
  bool get trayToggle => _trayToggle.value;
  Stream<bool> get trayToggle$ => _trayToggle.stream;

  Future<void> init() async {
    await _systemTray.initSystemTray(iconPath: _idleIconPath);

    trayToggle$.listen((isToggled) {
      final task = isToggled ? showBusy : showIdle;
      unawaited(task());
    });

    final AppWindow appWindow = AppWindow();
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      switch (eventName) {
        case kSystemTrayEventClick:
          _trayToggle.value = !_trayToggle.value;
        case kSystemTrayEventRightClick:
          _systemTray.popUpContextMenu();
      }
    });
  }

  Future<void> showIdle() async {
    await _systemTray.setImage(_idleIconPath);
    await _systemTray.setTitle('');
  }

  Future<void> showBusy() async {
    await _systemTray.setImage(_busyIconPath);
    await _systemTray.setTitle('Live');
  }

  @disposeMethod
  void dispose() {
    unawaited(_trayToggle.close());
    unawaited(_systemTray.destroy());
  }
}
