#import "NaurtIosPlugin.h"
#if __has_include(<naurt_ios/naurt_ios-Swift.h>)
#import <naurt_ios/naurt_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "naurt_ios-Swift.h"
#endif

@implementation NaurtIosPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNaurtIosPlugin registerWithRegistrar:registrar];
}
@end
