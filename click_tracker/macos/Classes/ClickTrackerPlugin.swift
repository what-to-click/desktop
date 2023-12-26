import Cocoa
import FlutterMacOS

public class ClickTrackerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown], handler: { (event: NSEvent) -> Void in
            let screenFrame = NSScreen.main?.frame
            events([
                "x": event.locationInWindow.x,
                "y": abs(event.locationInWindow.y - (screenFrame?.height ?? 0)),
                "screenWidth": screenFrame?.width,
                "screenHeight": screenFrame?.height
            ])
        })
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let eventChannel = FlutterEventChannel(name: "click_tracker", binaryMessenger: registrar.messenger)
    let instance = ClickTrackerPlugin()
    eventChannel.setStreamHandler(instance)
  }
}
