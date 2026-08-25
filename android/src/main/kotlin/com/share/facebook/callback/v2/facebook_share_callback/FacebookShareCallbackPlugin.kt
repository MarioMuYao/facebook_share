package com.share.facebook.callback.v2.facebook_share_callback

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.share.Sharer
import com.facebook.share.model.ShareLinkContent
import com.facebook.share.model.SharePhoto
import com.facebook.share.model.SharePhotoContent
import com.facebook.share.widget.ShareDialog
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/** Shares links and photos through the Facebook SDK share dialog. */
class FacebookShareCallbackPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {
        private const val CHANNEL_NAME = "share_facebook_callback"
        private const val METHOD_FACEBOOK = "facebook_share"
        private const val LINK_TYPE = "shareLinksFacebook"
        private const val PHOTO_TYPE = "sharePhotoFacebook"
        private const val INVALID_ARGUMENTS = "invalid_arguments"
        private const val ACTIVITY_UNAVAILABLE = "activity_unavailable"
        private const val SHARE_UNAVAILABLE = "share_unavailable"
        private const val SHARE_FAILED = "share_failed"
        private const val INVALID_IMAGE = "invalid_image"
        private const val SHARE_IN_PROGRESS = "share_in_progress"
    }

    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var callbackManager: CallbackManager? = null
    private var shareInProgress = false

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
        callbackManager = CallbackManager.Factory.create()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        detachFromActivity()
        channel?.setMethodCallHandler(null)
        channel = null
        callbackManager = null
        shareInProgress = false
    }

    override fun onAttachedToActivity(@NonNull binding: ActivityPluginBinding) {
        detachFromActivity()
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(@NonNull binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity()
    }

    private fun detachFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            METHOD_FACEBOOK -> when (call.argument<String>("type")) {
                LINK_TYPE -> shareLinksFacebook(
                    call.argument("url"),
                    call.argument("quote"),
                    result
                )
                PHOTO_TYPE -> sharePhotoFacebook(call.argument("uint8Image"), call.argument("quote"), result)
                else -> result.error(INVALID_ARGUMENTS, "Unsupported Facebook share type.", null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return callbackManager?.onActivityResult(requestCode, resultCode, data) ?: false
    }

    private fun shareLinksFacebook(urlValue: String?, quote: String?, result: MethodChannel.Result) {
        val url = validUrl(urlValue)
        if (url == null) {
            result.error(INVALID_ARGUMENTS, "A valid http or https URL is required.", null)
            return
        }
        val currentActivity = activity ?: run {
            result.error(ACTIVITY_UNAVAILABLE, "No active Activity is available.", null)
            return
        }
        val manager = callbackManager ?: run {
            result.error(SHARE_UNAVAILABLE, "Facebook callback manager is unavailable.", null)
            return
        }
        if (!beginShare(currentActivity, manager, result)) return

        val shareDialog = ShareDialog(currentActivity)
        val content = ShareLinkContent.Builder()
            .setContentUrl(url)
            .setQuote(quote)
            .build()
        if (!ShareDialog.canShow(ShareLinkContent::class.java)) {
            finishError(result, SHARE_UNAVAILABLE, "Facebook cannot show link sharing on this device.")
            return
        }
        registerCallback(shareDialog, manager, result)
        try {
            shareDialog.show(content)
        } catch (error: RuntimeException) {
            finishError(result, SHARE_FAILED, error.message ?: "Facebook share failed.")
        }
    }

    private fun sharePhotoFacebook(imageBytes: ByteArray?, quote: String?, result: MethodChannel.Result) {
        if (imageBytes == null || imageBytes.isEmpty()) {
            result.error(INVALID_ARGUMENTS, "Non-empty image bytes are required.", null)
            return
        }
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        if (bitmap == null) {
            result.error(INVALID_IMAGE, "The image bytes could not be decoded.", null)
            return
        }
        val currentActivity = activity ?: run {
            result.error(ACTIVITY_UNAVAILABLE, "No active Activity is available.", null)
            return
        }
        val manager = callbackManager ?: run {
            result.error(SHARE_UNAVAILABLE, "Facebook callback manager is unavailable.", null)
            return
        }
        if (!beginShare(currentActivity, manager, result)) return

        val shareDialog = ShareDialog(currentActivity)
        val photo = SharePhoto.Builder().setBitmap(bitmap).setCaption(quote).build()
        val content = SharePhotoContent.Builder().addPhoto(photo).build()
        if (!ShareDialog.canShow(SharePhotoContent::class.java)) {
            finishError(result, SHARE_UNAVAILABLE, "Facebook cannot show photo sharing on this device.")
            return
        }
        registerCallback(shareDialog, manager, result)
        try {
            shareDialog.show(content)
        } catch (error: RuntimeException) {
            finishError(result, SHARE_FAILED, error.message ?: "Facebook share failed.")
        }
    }

    private fun beginShare(
        currentActivity: Activity?,
        manager: CallbackManager?,
        result: MethodChannel.Result
    ): Boolean {
        if (shareInProgress) {
            result.error(SHARE_IN_PROGRESS, "Another Facebook share is already in progress.", null)
            return false
        }
        if (currentActivity == null) {
            result.error(ACTIVITY_UNAVAILABLE, "No active Activity is available.", null)
            return false
        }
        if (manager == null) {
            result.error(SHARE_UNAVAILABLE, "Facebook callback manager is unavailable.", null)
            return false
        }
        shareInProgress = true
        return true
    }

    private fun registerCallback(
        shareDialog: ShareDialog,
        manager: CallbackManager,
        result: MethodChannel.Result
    ) {
        shareDialog.registerCallback(manager, object : FacebookCallback<Sharer.Result> {
            override fun onSuccess(callbackResult: Sharer.Result?) {
                finishSuccess(result, "success")
            }

            override fun onCancel() {
                finishSuccess(result, "cancel")
            }

            override fun onError(error: FacebookException) {
                finishError(result, SHARE_FAILED, error.message ?: "Facebook share failed.")
            }
        })
    }

    private fun finishSuccess(result: MethodChannel.Result, value: String) {
        if (!shareInProgress) return
        shareInProgress = false
        Handler(Looper.getMainLooper()).post { result.success(value) }
    }

    private fun finishError(result: MethodChannel.Result, code: String, message: String) {
        if (!shareInProgress) {
            result.error(code, message, null)
            return
        }
        shareInProgress = false
        Handler(Looper.getMainLooper()).post { result.error(code, message, null) }
    }

    private fun validUrl(value: String?): Uri? {
        val uri = value?.let(Uri::parse) ?: return null
        return if (uri.host.isNullOrEmpty() || uri.scheme?.lowercase() !in setOf("http", "https")) {
            null
        } else {
            uri
        }
    }
}
