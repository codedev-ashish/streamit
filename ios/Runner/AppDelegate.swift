import UIKit
import Flutter
import flutter_downloader

import AVFoundation


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var url = "";
    var navigationController = UINavigationController()
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
       UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    print("Enter in iOS");
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let webviewChannel = FlutterMethodChannel(name: "webviewChannel",binaryMessenger: controller.binaryMessenger)

      navigationController = UINavigationController(rootViewController: controller)
    navigationController.setNavigationBarHidden(true, animated: false)
    self.window!.rootViewController = navigationController
    self.window!.makeKeyAndVisible()

    webviewChannel.setMethodCallHandler({ [self]
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

        if(call.method == "webview"){
            var dic = NSDictionary();
            dic = call.arguments as! NSDictionary;
            print("URL" ,dic["url"] ?? "");

            let vc = WKWViewController(nibName: "WKWViewController", bundle: nil)
             vc.dic = dic as! NSMutableDictionary
            navigationController.pushViewController(vc, animated: false)

            self.window!.rootViewController = navigationController
            self.window!.makeKeyAndVisible()
        }else {
            result("")
        }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    func SwitchViewController() {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let navigationController = UINavigationController(rootViewController: controller)
        self.window.rootViewController = navigationController
        self.window.makeKeyAndVisible()
   }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}

