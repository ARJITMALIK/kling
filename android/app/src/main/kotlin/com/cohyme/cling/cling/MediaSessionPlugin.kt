package com.cohyme.cling.cling

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the currently-playing media from Spotify, YouTube Music,
 * Apple Music (via Cider/Musickit), and YouTube via MediaSession API.
 *
 * This is exposed to Flutter via MethodChannel "com.cohyme.cling/media_session".
 */
class MediaSessionPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var context: Context? = null

    // Package names of supported music apps
    companion object {
        private val MUSIC_APP_PACKAGES = setOf(
            "com.spotify.music",
            "com.google.android.apps.youtube.music",
            "com.apple.android.music",
            "com.google.android.youtube",
            "com.cider.android",            // Cider (Apple Music client)
            "com.musicolet.app",
        )
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.cohyme.cling/media_session")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasNotificationAccess" -> {
                result.success(hasNotificationListenerPermission())
            }
            "openNotificationSettings" -> {
                openNotificationListenerSettings()
                result.success(null)
            }
            "getCurrentMedia" -> {
                val media = getCurrentPlayingMedia()
                result.success(media)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasNotificationListenerPermission(): Boolean {
        val ctx = context ?: return false
        val flat = Settings.Secure.getString(
            ctx.contentResolver,
            "enabled_notification_listeners"
        )
        return flat != null && flat.contains(ctx.packageName)
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context?.startActivity(intent)
    }

    @Suppress("DEPRECATION")
    private fun getCurrentPlayingMedia(): Map<String, String>? {
        val ctx = context ?: return null
        if (!hasNotificationListenerPermission()) return null

        return try {
            val manager = ctx.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val component = ComponentName(ctx, ClingNotificationListener::class.java)
            val controllers = manager.getActiveSessions(component)

            // Find a controller from a supported music app that is currently playing
            val controller = controllers.firstOrNull { ctrl ->
                val pkg = ctrl.packageName
                MUSIC_APP_PACKAGES.any { pkg.contains(it) || it.contains(pkg) } &&
                ctrl.playbackState?.state ==
                    android.media.session.PlaybackState.STATE_PLAYING
            } ?: controllers.firstOrNull { ctrl ->
                // Fall back: any playing session from a known package prefix
                val pkg = ctrl.packageName
                (pkg.startsWith("com.spotify") ||
                 pkg.startsWith("com.google.android.apps.youtube") ||
                 pkg.startsWith("com.apple") ||
                 pkg.startsWith("com.google.android.youtube")) &&
                ctrl.playbackState?.state ==
                    android.media.session.PlaybackState.STATE_PLAYING
            }

            val metadata = controller?.metadata ?: return null
            val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: return null
            if (title.isBlank()) return null

            val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
                ?: metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
                ?: ""

            mapOf("title" to title, "artist" to artist)
        } catch (e: Exception) {
            null
        }
    }
}

/**
 * Stub NotificationListenerService required for MediaSessionManager
 * to grant access to active media sessions.
 */
class ClingNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {}
    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}
}
