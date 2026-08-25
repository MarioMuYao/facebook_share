## 1.1.0

* Migrate the iOS Facebook SDK dependency from CocoaPods to Swift Package Manager.
* Use Facebook iOS SDK 18.1.0 or a compatible 18.x release.
* Use Facebook Android Share SDK 18.1.3.
* Validate share input and standardize native errors as `PlatformException` codes.
* Validate iOS Facebook configuration before opening the share dialog and forward SDK lifecycle callbacks.
* Validate Android Facebook metadata before sharing and include native exception details in failures.
* Remove the unsupported `ShareType.more` option and unused `imageName` argument.

## 0.0.1

* TODO: Describe initial release.
