package io.flutter.plugins

import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import com.example.video_compress.VideoCompressPlugin
import com.llfbandit.app_links.AppLinksPlugin
import io.endigo.plugins.pdfviewflutter.PDFViewFlutterPlugin
import io.flutter.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.camera.CameraPlugin
import io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin
import io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin
import io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin
import io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin
import io.flutter.plugins.imagepicker.ImagePickerPlugin
import io.flutter.plugins.pathprovider.PathProviderPlugin
import io.flutter.plugins.sharedpreferences.LegacySharedPreferencesPlugin
import io.flutter.plugins.urllauncher.UrlLauncherPlugin
import io.flutter.plugins.videoplayer.VideoPlayerPlugin
import xyz.luan.audioplayers.AudioplayersPlugin

class GeneratedPluginRegistrant {
    companion object {
        private const val TAG = "GeneratedPluginRegistrant"

        @JvmStatic
        fun registerWith(flutterEngine: FlutterEngine) {
            try {
                flutterEngine.plugins.add(AppLinksPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin app_links, com.llfbandit.app_links.AppLinksPlugin", e)
            }
            try {
                flutterEngine.plugins.add(AudioplayersPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin audioplayers_android, xyz.luan.audioplayers.AudioplayersPlugin", e)
            }
            try {
                flutterEngine.plugins.add(CameraPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin camera_android, io.flutter.plugins.camera.CameraPlugin", e)
            }
            try {
                flutterEngine.plugins.add(FlutterFirebaseFirestorePlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin cloud_firestore, io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin", e)
            }
            try {
                flutterEngine.plugins.add(FlutterFirebaseAuthPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin firebase_auth, io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin", e)
            }
            try {
                flutterEngine.plugins.add(FlutterFirebaseCorePlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin firebase_core, io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin", e)
            }
            try {
                flutterEngine.plugins.add(FlutterFirebaseMessagingPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin firebase_messaging, io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin", e)
            }
            try {
                flutterEngine.plugins.add(FlutterLocalNotificationsPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin flutter_local_notifications, com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin", e)
            }
            try {
                flutterEngine.plugins.add(PDFViewFlutterPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin flutter_pdfview, io.endigo.plugins.pdfviewflutter.PDFViewFlutterPlugin", e)
            }
            try {
                flutterEngine.plugins.add(FlutterAndroidLifecyclePlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin flutter_plugin_android_lifecycle, io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin", e)
            }
            try {
                flutterEngine.plugins.add(ImagePickerPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin image_picker_android, io.flutter.plugins.imagepicker.ImagePickerPlugin", e)
            }
            try {
                flutterEngine.plugins.add(PathProviderPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin path_provider_android, io.flutter.plugins.pathprovider.PathProviderPlugin", e)
            }
            try {
                flutterEngine.plugins.add(LegacySharedPreferencesPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin shared_preferences_android, io.flutter.plugins.sharedpreferences.LegacySharedPreferencesPlugin", e)
            }
            try {
                flutterEngine.plugins.add(UrlLauncherPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin url_launcher_android, io.flutter.plugins.urllauncher.UrlLauncherPlugin", e)
            }
            try {
                flutterEngine.plugins.add(VideoCompressPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin video_compress, com.example.video_compress.VideoCompressPlugin", e)
            }
            try {
                flutterEngine.plugins.add(VideoPlayerPlugin())
            } catch (e: Exception) {
                Log.e(TAG, "Error registering plugin video_player_android, io.flutter.plugins.videoplayer.VideoPlayerPlugin", e)
            }
        }
    }
}
