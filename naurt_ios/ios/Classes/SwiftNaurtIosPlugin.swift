import Flutter
import Combine
import UIKit
import naurt_framework


public class SwiftNaurtIosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var subscriptions = [AnyCancellable]()
    private var channel: FlutterMethodChannel?
    private var locationUpdateEventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.naurt.ios", binaryMessenger: registrar.messenger())
        let locationUpdateEventChannel = FlutterEventChannel(name: "com.naurt.ios/locationChanged", binaryMessenger: registrar.messenger())
        
        let instance = SwiftNaurtIosPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        locationUpdateEventChannel.setStreamHandler(instance)
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      
      if (call.method == "initialize") {
          let arguments = call.arguments as! Dictionary<String, Any>
          Naurt.shared.initialise(
              apiKey: arguments["apiKey"] as! String,
              precision: arguments["precision"] as! Int
          )
          
          subscriptions.removeAll()
          subscriptions.append(Naurt.shared.$isInitialised.sink { value in
              result(value)
          })
          
          subscriptions.append(Naurt.shared.$isValidated.sink { [weak self ] value in
              self?.channel!.invokeMethod("onValidation", arguments: value)
          })
          subscriptions.append(Naurt.shared.$isRunning.sink { [weak self ] value in
              self?.channel!.invokeMethod("onRunning", arguments: value)
          })
          subscriptions.append(Naurt.shared.$naurtPoint.sink { [weak self ] value in
              self?.locationUpdateEventSink?(value?.encode())
          })
      }
      else if (call.method == "isValidated") {
          result(Naurt.shared.isValidated)
      } else if (call.method == "isRunning") {
          result(Naurt.shared.isRunning)
      } else if (call.method == "naurtPoint") {
          guard let naurtPoint = Naurt.shared.naurtPoint else {
              return result(nil)
          }
          result(naurtPoint.encode())
      } else if (call.method == "naurtPoints") {
          result(Naurt.shared.naurtPoints.map{ $0.encode() })
      } else if (call.method == "journeyUuid") {
          result(Naurt.shared.journeyUuid?.uuidString)
      } else if (call.method == "start") {
          Naurt.shared.start()
      } else if (call.method == "stop") {
          Naurt.shared.stop()
      }  else if (call.method == "pause") {
          Naurt.shared.pause()
      }  else if (call.method == "resume") {
          Naurt.shared.resume()
      }
  }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        locationUpdateEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationUpdateEventSink = nil
        return nil
    }
}

private extension NaurtLocation {
     func encode() -> [String: Any]{
        return ["latitude": latitude, "longitude":longitude, "timestamp": timestamp]
    }
}

