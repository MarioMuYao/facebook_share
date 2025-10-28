import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'facebook_share_callback_platform_interface.dart';

/// An implementation of [FacebookShareCallbackPlatform] that uses method channels.
class MethodChannelFacebookShareCallback extends FacebookShareCallbackPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('share_facebook_callback');

  @override
  Future<String?> shareFacebook({
    required String type,
    String? quote,
    String? url,
    Uint8List? uint8Image,
    String? imageName,
  }) async {
    final result = await methodChannel.invokeMethod<String?>('facebook_share', {
      'type': type,
      'url': url,
      'uint8Image': uint8Image,
      'imageName': imageName,
      'quote': quote,
    });
    return result;
  }
}
