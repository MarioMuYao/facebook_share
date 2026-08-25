import 'package:facebook_share_callback/facebook_share_callback_method_channel.dart';
import 'package:facebook_share_callback/facebook_share_callback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('share_facebook_callback');
  final plugin = MethodChannelFacebookShareCallback();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('sends stable link arguments and returns success', () async {
    MethodCall? receivedCall;
    messenger.setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return 'success';
    });

    final value = await plugin.shareFacebook(
      type: 'shareLinksFacebook',
      quote: 'A quote',
      url: 'https://example.com/path',
    );

    expect(value, 'success');
    expect(receivedCall?.method, 'facebook_share');
    expect(receivedCall?.arguments, {
      'type': 'shareLinksFacebook',
      'url': 'https://example.com/path',
      'uint8Image': null,
      'quote': 'A quote',
    });
  });

  test('returns cancellation from the native channel', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'cancel');

    expect(
      await plugin.shareFacebook(
        type: 'sharePhotoFacebook',
        uint8Image: Uint8List.fromList([1, 2, 3]),
      ),
      'cancel',
    );
  });

  test('propagates native platform errors', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
        code: 'share_unavailable',
        message: 'Facebook is not installed.',
      );
    });

    expect(
      () => plugin.shareFacebook(type: 'shareLinksFacebook'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'share_unavailable',
        ),
      ),
    );
  });

  test(
    'rejects invalid public API input before invoking the channel',
    () async {
      final api = FacebookShareCallback();

      await expectLater(
        api.shareFacebook(type: ShareType.shareLinksFacebook, url: 'not-a-url'),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        api.shareFacebook(type: ShareType.sharePhotoFacebook),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
