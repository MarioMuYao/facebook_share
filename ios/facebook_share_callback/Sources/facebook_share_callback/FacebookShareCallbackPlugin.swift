import FBSDKShareKit
import FacebookCore
import Flutter
import UIKit

public final class FacebookShareCallbackPlugin: NSObject, FlutterPlugin, SharingDelegate, FlutterSceneLifeCycleDelegate {
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
        registrar.addApplicationDelegate(instance)
        if #available(iOS 13.0, *) {
            registrar.addSceneDelegate(instance)
        }
        // Flutter may register plugins after UIApplicationDelegate launch callbacks.
        _ = ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: nil
        )
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(application, open: url, options: options)
    }

    @available(iOS 13.0, *)
    public func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) -> Bool {
        var handled = false
        for context in URLContexts {
            handled = ApplicationDelegate.shared.application(
                UIApplication.shared,
                open: context.url,
                options: [:]
            ) || handled
        }
        return handled
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
        complete(
            errorCode: "share_failed",
            message: message(for: error),
            details: details(for: error)
        )
    }

    @objc public func sharerDidCancel(_ sharer: Sharing) {
        complete(value: "cancel")
    }

    private func shareLinksFacebook(withQuote quote: String?, withURL url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let configurationError = self.facebookConfigurationError() {
                self.complete(
                    errorCode: "configuration_error",
                    message: configurationError.message,
                    details: configurationError.details
                )
                return
            }
            guard let viewController = self.presentingViewController() else {
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
            do {
                try shareDialog.validate()
            } catch {
                self.complete(
                    errorCode: "invalid_share_content",
                    message: self.message(for: error),
                    details: self.details(for: error)
                )
                return
            }
            let didShow = shareDialog.show()
            if !didShow {
                self.complete(
                    errorCode: "share_failed",
                    message: "Facebook could not start the share dialog. Verify the Facebook app configuration and URL scheme.",
                    details: ["reason": "share_dialog_not_started"]
                )
            }
        }
    }

    private func sharePhotoFacebook(withImageData imageData: FlutterStandardTypedData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let configurationError = self.facebookConfigurationError() {
                self.complete(
                    errorCode: "configuration_error",
                    message: configurationError.message,
                    details: configurationError.details
                )
                return
            }
            guard let viewController = self.presentingViewController() else {
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
            do {
                try shareDialog.validate()
            } catch {
                self.complete(
                    errorCode: "invalid_share_content",
                    message: self.message(for: error),
                    details: self.details(for: error)
                )
                return
            }
            let didShow = shareDialog.show()
            if !didShow {
                self.complete(
                    errorCode: "share_failed",
                    message: "Facebook could not start the share dialog. Verify the Facebook app configuration and URL scheme.",
                    details: ["reason": "share_dialog_not_started"]
                )
            }
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

    private func presentingViewController() -> UIViewController? {
        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let window = activeScenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
            ?? activeScenes
                .flatMap(\.windows)
                .first(where: { !$0.isHidden && $0.alpha > 0 })

        return topViewController(window?.rootViewController) ?? viewController
    }

    private func topViewController(_ viewController: UIViewController?) -> UIViewController? {
        guard let viewController else { return nil }

        if let presented = viewController.presentedViewController,
           !presented.isBeingDismissed {
            return topViewController(presented)
        }
        if let navigationController = viewController as? UINavigationController {
            return topViewController(navigationController.visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController {
            return topViewController(tabBarController.selectedViewController)
        }
        return viewController
    }

    private func message(for error: Error) -> String {
        let nsError = error as NSError
        let localized = nsError.localizedDescription
        guard nsError.code == 0 || localized.isEmpty else { return localized }
        return "Facebook returned an unspecified share error (\(nsError.domain), code \(nsError.code)). Verify the Facebook App ID, URL schemes, and Facebook app configuration."
    }

    private func details(for error: Error) -> [String: Any] {
        let nsError = error as NSError
        var details: [String: Any] = [
            "domain": nsError.domain,
            "code": nsError.code,
        ]
        if let reason = nsError.localizedFailureReason {
            details["failureReason"] = reason
        }
        if let suggestion = nsError.localizedRecoverySuggestion {
            details["recoverySuggestion"] = suggestion
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            details["underlyingError"] = "\(underlying.domain) (code \(underlying.code)): \(underlying.localizedDescription)"
        }
        return details
    }

    private func facebookConfigurationError() -> (message: String, details: [String: Any])? {
        let appID = Settings.shared.appID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let clientToken = Settings.shared.clientToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var missingKeys: [String] = []

        if appID.isEmpty {
            missingKeys.append("FacebookAppID")
        }
        if clientToken.isEmpty {
            missingKeys.append("FacebookClientToken")
        }

        guard missingKeys.isEmpty else {
            return (
                "Facebook SDK is not configured. Add valid FacebookAppID and FacebookClientToken values to Info.plist.",
                ["missingKeys": missingKeys]
            )
        }

        let expectedScheme = "fb\(appID)\(Settings.shared.appURLSchemeSuffix ?? "")"
        let configuredSchemes = (Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? [])
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }

        guard configuredSchemes.contains(expectedScheme) else {
            return (
                "Facebook URL scheme is not configured. Add fb\(appID) to CFBundleURLSchemes in Info.plist.",
                [
                    "expectedScheme": expectedScheme,
                    "configuredSchemes": configuredSchemes,
                ]
            )
        }

        return nil
    }

    private func complete(
        value: Any? = nil,
        errorCode: String? = nil,
        message: String? = nil,
        details: Any? = nil
    ) {
        guard let result = pendingResult else { return }
        pendingResult = nil
        let callback = {
            if let errorCode {
                result(FlutterError(code: errorCode, message: message, details: details))
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
