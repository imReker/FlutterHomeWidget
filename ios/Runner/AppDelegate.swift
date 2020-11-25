import UIKit
import Flutter
import WidgetKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        if #available(iOS 14.0, *) {
            let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
            let widgetChannel = FlutterMethodChannel(name: "Widget/Native",
                binaryMessenger: controller.binaryMessenger)
            widgetChannel.setMethodCallHandler({
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                if call.method == "getConfigs" {
//                    self.receiveBatteryLevel(result: result)
                } else {
                    result(FlutterMethodNotImplemented)
                    return
                }
            })
        }
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.getCurrentConfigurations { (result) in
                guard let widgets = try? result.get() else { return }
                widgets.forEach { (widget) in
                    print(widget.debugDescription)
                }
            }
        }
    }
}
