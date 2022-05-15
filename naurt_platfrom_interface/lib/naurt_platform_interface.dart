import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'naurt_method_channel.dart';
part 'naurt_location.dart';

abstract class NaurtPlatform extends PlatformInterface {
  /// Constructs a NaurtPlatform.
  NaurtPlatform() : super(token: _token);

  static final Object _token = Object();

  static NaurtPlatform _instance = MethodChannelNaurt();

  /// The default instance of [NaurtPlatform] to use.
  ///
  /// Defaults to [MethodChannelNaurt].
  static NaurtPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NaurtPlatform] when
  /// they register themselves.
  static set instance(NaurtPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns true if the Naurt SDK is initialized
  Future<bool> initialize(
      {required String apiKey, required int precision}) async {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Is the API key provided to this state valid with the Naurt API server?
  Future<bool> isValidated() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  ValueChanged<bool>? onValidation;

  /// Is Naurt's Locomotion running at the moment?
  Future<bool> isRunning() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  ValueChanged<bool>? onRunning;

  /// Most recent Naurt point for the current journey null if no data is available
  Future<NaurtLocation?> lastNaurtPoint() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Streams location changes
  Stream<NaurtLocation> get onLocationChanged {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Start Naurt Locomotion
  void start() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  void stop() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  void pause() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  void resume() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
