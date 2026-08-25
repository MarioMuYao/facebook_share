import FBSDKShareKit
import Flutter
import UIKit

public final class FacebookShareCallbackPlugin: NSObject, FlutterPlugin, SharingDelegate {
    private static let shareMethod = "facebook_share"
    private static let linkType = "shareLinksFacebook"
    private static let photoType = "sharePhotoFacebook"

    private weak var viewController: UIViewController?
    private var pendingResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "share_facebook_callback",
            binaryMessenger: registrar.messenger()
        )
        let instance = FacebookShareCallbackPlugin()
        instance.viewController = registrar.viewController
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case Self.shareMethod:
            handleShare(arguments: call.arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleShare(arguments: Any?, result: @escaping FlutterResult) {
        guard pendingResult == nil else {
            result(FlutterError(
                code: "share_in_progress",
                message: "Another Facebook share is already in progress.",
                details: nil
            ))
            return
        }

        guard let arguments = arguments as? [String: Any],
              let type = arguments["type"] as? String
        else {
            result(FlutterError(
                code: "invalid_arguments",
                message: "The share type is required.",
                details: nil
            ))
            return
        }

        pendingResult = result
        switch type {
        case Self.linkType:
            guard let urlString = arguments["url"] as? String,
                  let url = validURL(from: urlString)
            else {
                complete(errorCode: "invalid_arguments", message: "A valid http or https URL is required.")
                return
            }
            shareLinksFacebook(withQuote: arguments["quote"] as? String, withURL: url)
        case Self.photoType:
            guard let imageData = arguments["uint8Image"] as? FlutterStandardTypedData,
                  !imageData.data.isEmpty
            else {
                complete(errorCode: "invalid_arguments", message: "Non-empty image bytes are required.")
                return
            }
            sharePhotoFacebook(withImageData: imageData)
        default:
            complete(errorCode: "invalid_arguments", message: "Unsupported Facebook share type.")
        }
    }

    // MARK: - SharingDelegate

    @objc public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
        complete(value: "success")
    }

    @objc public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        complete(errorCode: "share_failed", message: error.localizedDescription)
    }

    @objc public func sharerDidCancel(_ sharer: Sharing) {
        complete(value: "cancel")
    }

    private func shareLinksFacebook(withQuote quote: String?, withURL url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let viewController = self.viewController else {
                self.complete(errorCode: "activity_unavailable", message: "No active view controller is available.")
                return
            }

            let content = ShareLinkContent()
            content.contentURL = url
            content.quote = quote
            let shareDialog = ShareDialog(viewController: viewController, content: content, delegate: self)
            guard shareDialog.canShow else {
                self.complete(errorCode: "share_unavailable", message: "Facebook cannot show link sharing on this device.")
                return
            }
            shareDialog.show()
        }
    }

    private func sharePhotoFacebook(withImageData imageData: FlutterStandardTypedData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let viewController = self.viewController else {
                self.complete(errorCode: "activity_unavailable", message: "No active view controller is available.")
                return
            }
            guard let image = UIImage(data: imageData.data) else {
                self.complete(errorCode: "invalid_image", message: "The image bytes could not be decoded.")
                return
            }

            let photo = SharePhoto(image: image, isUserGenerated: true)
            let content = SharePhotoContent()
            content.photos = [photo]
            let shareDialog = ShareDialog(viewController: viewController, content: content, delegate: self)
            guard shareDialog.canShow else {
                self.complete(errorCode: "share_unavailable", message: "Facebook cannot show photo sharing on this device.")
                return
            }
            shareDialog.show()
        }
    }

    private func validURL(from value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else {
            return nil
        }
        return url
    }

    private func complete(value: Any? = nil, errorCode: String? = nil, message: String? = nil) {
        guard let result = pendingResult else { return }
        pendingResult = nil
        let callback = {
            if let errorCode {
                result(FlutterError(code: errorCode, message: message, details: nil))
            } else {
                result(value)
            }
        }
        if Thread.isMainThread {
            callback()
        } else {
            DispatchQueue.main.async(execute: callback)
        }
    }
}
