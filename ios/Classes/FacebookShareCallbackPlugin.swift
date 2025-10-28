import FBSDKShareKit
import Flutter
import UIKit

public class FacebookShareCallbackPlugin: NSObject, FlutterPlugin, SharingDelegate {

    var result: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "share_facebook_callback", binaryMessenger: registrar.messenger())
        let instance = FacebookShareCallbackPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        if call.method == "getPlatformVersion" {
            result("iOS " + UIDevice.current.systemVersion)
        } else if call.method == "facebook_share" {
            if let arguments = call.arguments as? [String: Any] {
                let type = arguments["type"] as? String ?? "ShareType.more"
                let shareQuote = arguments["quote"] as? String ?? ""
                let shareUrl = arguments["url"] as? String ?? ""
                let uint8Image = arguments["uint8Image"] as? FlutterStandardTypedData
                _ = arguments["imageName"] as? String ?? ""

                switch type {
                case "ShareType.shareLinksFacebook":
                    shareLinksFacebook(withQuote: shareQuote, withUrl: shareUrl)
                case "ShareType.sharePhotoFacebook":
                    sharePhotoFacebook(withuint8Image: uint8Image, withQuote: shareQuote)
                default:
                    self.result?("Method not implemented")
                }
            }
        }
    }

    // MARK: - SharingDelegate Methods
    @objc public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
        NSLog("--------------------success")
        self.result?("success")
    }

    @objc public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        NSLog("-----------------onError")
        self.result?("error")
    }

    @objc public func sharerDidCancel(_ sharer: Sharing) {
        NSLog("-----------------onCancel")
        self.result?("cancel")
    }

    private func shareLinksFacebook(withQuote quote: String?, withUrl urlString: String?) {
        DispatchQueue.main.async {
            let viewController = UIApplication.shared.delegate?.window??.rootViewController
            let shareContent = ShareLinkContent()

            if let url = urlString, let covertURL = URL(string: url) {
                shareContent.contentURL = covertURL
            }

            if let quoteString = quote {
                shareContent.quote = quoteString
            }

            let shareDialog = ShareDialog(
                viewController: viewController, content: shareContent, delegate: self)
            if shareDialog.canShow {
                shareDialog.show()
            } else {
                NSLog("Facebook ShareDialog cannot be shown on this device")
                self.result?("error")  // Or a better error message like "not supported on simulator"
            }
            //            shareDialog.show()
        }
    }

    private func sharePhotoFacebook(
        withuint8Image uint8Image: FlutterStandardTypedData?, withQuote quote: String?
    ) {
        DispatchQueue.main.async {
            guard let data = uint8Image else {
                self.result?("error: No image data provided")
                return
            }

            let viewController = UIApplication.shared.delegate?.window??.rootViewController
            guard let uiImage = UIImage(data: data.data) else {
                self.result?("error: Invalid image data")
                return
            }

            let photo = SharePhoto(image: uiImage, isUserGenerated: true)
            let content = SharePhotoContent()
            content.photos = [photo]

            let shareDialog = ShareDialog(
                viewController: viewController, content: content, delegate: self)
            if shareDialog.canShow {
                shareDialog.show()
            } else {
                NSLog("Facebook ShareDialog cannot be shown on this device")
                self.result?("error")  // Or a better error message like "not supported on simulator"
            }
            //            shareDialog.show()
        }
    }
}
