import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:naurt_platfrom_interface/naurt_platform_interface.dart';

/// An implementation of [NaurtIOS] that uses method channels.
class NaurtAndroid extends NaurtPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.naurt.ios');
  final eventChannel = const EventChannel('com.naurt.ios/locationChanged');

  /// Registers this class as the default instance of [NaurtPlatform].
  static void registerWith() {
    NaurtPlatform.instance = NaurtAndroid._privateConstructor();
  }

  NaurtAndroid._privateConstructor();

  static final NaurtAndroid shared = NaurtAndroid._privateConstructor();

  /// Returns true if the Naurt SDK is initialized
  @override
  Future<bool> initialize(
      {required String apiKey, required int precision}) async {
    final bool isInitialised = await methodChannel.invokeMethod('initialize', {
      'apiKey': apiKey,
      'precision': precision,
    });

    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onValidation') {
        onValidation?.call(call.arguments);
      } else if (call.method == 'onRunning') {
        onRunning?.call(call.arguments);
      }
    });

    return isInitialised;
  }

  ValueChanged<bool>? onValidation;
  ValueChanged<bool>? onRunning;

  /// Is the API key provided to this state valid with the Naurt API server?
  @override
  Future<bool> isValidated() async {
    final bool isValidated = await methodChannel.invokeMethod('isValidated');
    return isValidated;
  }

  /// Is Naurt's Locomotion running at the moment?
  @override
  Future<bool> isRunning() async {
    final bool isRunning = await methodChannel.invokeMethod('isRunning');
    return isRunning;
  }

  /// Most recent naurt point for the current journey null if no data is available
  @override
  Future<NaurtLocation?> lastNaurtPoint() async {
    final Map<String, dynamic>? resultMap =
        await methodChannel.invokeMapMethod('naurtPoint');
    return resultMap != null ? NaurtLocation.fromMap(resultMap) : null;
  }

  @override
  Stream<NaurtLocation> get onLocationChanged {
    return eventChannel
        .receiveBroadcastStream()
        .where((location) => location != null)
        .map((dynamic location) =>
            NaurtLocation.fromMap(Map<String, dynamic>.from(location)));
  }

  /// The UUID of the Journey - null if no journey data is available
  Future<String?> journeyUuid() async {
    final String? journeyUuid = await methodChannel.invokeMethod('journeyUuid');
    return journeyUuid;
  }

  /// Start Naurt Locomotion
  @override
  void start() {
    methodChannel.invokeMethod('start');
  }

  @override
  void stop() {
    methodChannel.invokeMethod('stop');
  }

  @override
  void pause() {
    methodChannel.invokeMethod('pause');
  }

  @override
  void resume() {
    methodChannel.invokeMethod('resume');
  }
}
