import 'package:flutter/services.dart';

import 'facebook_share_callback_platform_interface.dart';

enum ShareType { shareLinksFacebook, sharePhotoFacebook }

class FacebookShareCallback {
  Future<String?> shareFacebook({
    required ShareType type,
    String? quote,
    String? url,
    Uint8List? uint8Image,
  }) {
    switch (type) {
      case ShareType.shareLinksFacebook:
        final parsedUrl = Uri.tryParse(url ?? '');
        if (parsedUrl == null ||
            (parsedUrl.scheme.toLowerCase() != 'http' &&
                parsedUrl.scheme.toLowerCase() != 'https') ||
            parsedUrl.host.isEmpty) {
          return Future<String?>.error(
            PlatformException(
              code: 'invalid_arguments',
              message:
                  'A valid http or https URL is required for link sharing.',
            ),
          );
        }
      case ShareType.sharePhotoFacebook:
        if (uint8Image == null || uint8Image.isEmpty) {
          return Future<String?>.error(
            PlatformException(
              code: 'invalid_arguments',
              message: 'Non-empty image bytes are required for photo sharing.',
            ),
          );
        }
    }

    return FacebookShareCallbackPlatform.instance.shareFacebook(
      type: type.name,
      quote: quote,
      url: url,
      uint8Image: uint8Image,
    );
  }
}
