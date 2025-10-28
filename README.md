# facebook_share_callback

Flutter package to share URL or Picture to facebook using facebook share dialog with callbacks.

You can use it share to Facebook. Support Url and Text, Photo

## Getting Started
add facebook_share_callback as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

Please check the latest version before installation.
```
dependencies:
  flutter:
    sdk: flutter
  # add share_facebook_callback
  facebook_share_callback: [LATEST_VERSION]
```

## Setup

#### Android

Add "facebook app id" to the application tag of AndroidManifest.xml
```
    //add this under manifest (oustside <application> tag)
    <queries>
        <provider android:authorities="com.facebook.katana.provider.PlatformProvider" /> 
    </queries>
    <application>
       //add this inside <application> tag
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id" />
        <meta-data 
            android:name="com.facebook.sdk.ClientToken" 
            android:value="@string/facebook_client_token"/>    
            
        <provider
            android:name="com.facebook.FacebookContentProvider"
            android:authorities="com.facebook.app.FacebookContentProvider[FB_APP_ID]"
            android:exported="true" />
    </application>
```

string.xml:
```
<?xml version="1.0" encoding="utf-8"?>
<resources>
<!-- Replace "12345678901234" with your Facebook App ID here. -->
    <string name="facebook_app_id">12345678901234</string>
<!-- Replace "123456789abcdefghimnl" with your Facebook Client Token here. -->
    <string name="facebook_client_token">123456789abcdefghimnl</string>
</resources>
```
#### IOS

make sure you add below deatils in your plist file.

```
    <key>FacebookAppID</key>
    <string>[FB_APP_ID]</string>

    <key>FacebookClientToken</key>
    <string>[FB_CLIENT_TOKEN]</string>

    <key>CFBundleURLTypes</key>
    <array>
      <dict>
        <key>CFBundleURLSchemes</key>
        <array>
          <string>fb[FB_APP_ID]</string>
        </array>
      </dict>
    </array>

    <key>LSApplicationQueriesSchemes</key>
    <array>
      <string>fbapi</string>
      <string>fb-messenger-api</string>
      <string>fbshareextension</string>
    </array>

```

## Usage
#### Link Sharing
import the package
```
import 'package:facebook_share_callback/facebook_share_callback.dart';
```
and then call the function like below:
```
    final shareFacebookCallbackPlugin = FacebookShareCallback();

    String? result = await shareFacebookCallbackPlugin.shareFacebook(
      type: ShareType.shareLinksFacebook,
      quote: quote,
      url: url,
    );
```

#### Picture Sharing
import the package
```
import 'package:facebook_share_callback/facebook_share_callback.dart';
```
and then call the function like below:
```
    final shareFacebookCallbackPlugin = FacebookShareCallback();
    
    String? result = await shareFacebookCallbackPlugin.shareFacebook(
      type: ShareType.sharePhotoFacebook,
      quote: 'This is my picture',
      imageName: 'My image name',
      uint8Image: image.readAsBytesSync(), // pick image from gallery or camera using iamge picker package or file picker or similar
    );
```

#### Callbacks
Result is a **nullable** string, if user successfully shares the link or picture to facebook, its value will be **success**

#### Note
Facebook share dialog for iOS is part of iOS facebook app itself and it will not work on iOS simulators, use real iOS device for testing