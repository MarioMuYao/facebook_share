import 'dart:async';
import 'dart:io';

import 'package:facebook_share_callback/facebook_share_callback.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _shareUrl(url: 'https:www.my-url-com', quote: 'This is my quote'),
              child: Text('Share Link to Facebook'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (file != null) {
                  _sharePicture(image: File(file.path));
                }
              },
              child: Text('Share Picture to Facebook'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareUrl({required String url, required String? quote}) async {
    final shareFacebookCallbackPlugin = FacebookShareCallback();

    String? result = await shareFacebookCallbackPlugin.shareFacebook(
      type: ShareType.shareLinksFacebook,
      quote: quote,
      url: url,
    );
  }

  Future<void> _sharePicture({required File image}) async {
    final shareFacebookCallbackPlugin = FacebookShareCallback();
    String? result = await shareFacebookCallbackPlugin.shareFacebook(
      type: ShareType.sharePhotoFacebook,
      quote: 'This is my picture',
      imageName: 'My image name',
      uint8Image: image.readAsBytesSync(),
    );
  }
}
