import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'facebook_share_callback_method_channel.dart';

abstract class FacebookShareCallbackPlatform extends PlatformInterface {
  /// Constructs a FacebookShareCallbackPlatform.
  FacebookShareCallbackPlatform() : super(token: _token);

  static final Object _token = Object();

  static FacebookShareCallbackPlatform _instance = MethodChannelFacebookShareCallback();

  /// The default instance of [FacebookShareCallbackPlatform] to use.
  ///
  /// Defaults to [MethodChannelFacebookShareCallback].
  static FacebookShareCallbackPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FacebookShareCallbackPlatform] when
  /// they register themselves.
  static set instance(FacebookShareCallbackPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> shareFacebook({
    required String type,
    String? quote,
    String? url,
    Uint8List? uint8Image,
    String? imageName,
  });
}
