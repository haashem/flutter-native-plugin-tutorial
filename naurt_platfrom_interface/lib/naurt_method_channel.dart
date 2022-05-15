import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'naurt_platform_interface.dart';

/// An implementation of [NaurtPlatform] that uses method channels.
class MethodChannelNaurt extends NaurtPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.naurt');
}
