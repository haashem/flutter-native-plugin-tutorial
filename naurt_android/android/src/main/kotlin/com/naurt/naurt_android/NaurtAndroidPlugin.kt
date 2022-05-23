package com.naurt.naurt_android

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.databinding.Observable

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.naurt_kotlin_sdk.Naurt.INSTANCE as Naurt
import com.naurt_kotlin_sdk.*

import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.atomic.AtomicInteger
import kotlin.coroutines.resume

/** Utility function to clean up ObservableField in Kotlin,
 * See: https://proandroiddev.com/the-ugly-onpropertychangedcallback-63c78c762394
 * For details & Rationale
 * */
fun <T: Observable> T.addOnPropertyChanged(callback: (T) -> Unit) =
  object: Observable.OnPropertyChangedCallback() {
    override fun onPropertyChanged(observable: Observable?, i: Int) =
      callback(observable as T)
  }.also { addOnPropertyChangedCallback(it) }



/** NaurtAndroidPlugin */
class NaurtAndroidPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private  lateinit var applicationContext: Context
  private var locationUpdateEventSink: EventChannel.EventSink? = null
  private var currentActivity: Activity? = null

  private val permissionRequestCounter = AtomicInteger(0)
  private val uid: Int
    get() = permissionRequestCounter.getAndIncrement()
  private val permissionListeners: MutableMap<Int, CancellableContinuation<Boolean>> = mutableMapOf()

  private val requiredPermissions = arrayOf(
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_NETWORK_STATE,
    Manifest.permission.WRITE_EXTERNAL_STORAGE,
  )

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.naurt.ios")
    val locationUpdateEventChannel = EventChannel(flutterPluginBinding.binaryMessenger,"com.naurt.ios/locationChanged")
    channel.setMethodCallHandler(this)
    locationUpdateEventChannel.setStreamHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> {
        val apiKey = call.argument<String>("apiKey")!!
        val precisions = call.argument<Int>("precision")!!
        GlobalScope.launch {
          val hasPermissions = requestPermissions(*requiredPermissions)
          if (hasPermissions) {
            Naurt.initialise(
              apiKey,
              applicationContext,
              precisions
            )
          } else {
            result.error("PERMISSIONS_REQUIRED", "required permissions are not granted by user", null )
          }
        }

        Naurt.isInitialised.addOnPropertyChanged { isInitialised ->
          result.success(isInitialised.get())
        }

        Naurt.isValidated.addOnPropertyChanged { isValidated ->
          // invokeMethod must be called on the UI thread in Android
          Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onValidation", isValidated.get())
          }
        }

        Naurt.isRunning.addOnPropertyChanged { isRunning ->
          // invokeMethod must be called on the UI thread in Android
          Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onRunning", isRunning.get())
          }
        }

        Naurt.naurtPoint.addOnPropertyChanged { observableLocation ->
          val location = observableLocation.get()
          if (location != null) {
            locationUpdateEventSink?.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude, "timestamp" to location.timestamp ));
          }
        }
      }
      "isValidated" -> {
        result.success(Naurt.isValidated.get())
      }
      "isRunning" -> {
        result.success(Naurt.isRunning.get())
      }
      "naurtPoint" -> {
        val lastLocation = Naurt.naurtPoint.get()
        if (lastLocation != null) {
          result.success(mapOf("latitude" to lastLocation.latitude, "longitude" to lastLocation.longitude, "timestamp" to lastLocation.timestamp ))
        } else {
          result.success(null)
        }
      }
      "naurtPoints" -> {
        val locationsMap = Naurt.naurtPoints.map { location -> mapOf("latitude" to location.latitude, "longitude" to location.longitude, "timestamp" to location.timestamp ) }
        result.success(locationsMap)
      }
      "journeyUuid" -> {
        result.success(Naurt.journeyUuid.toString())
      }
      "start" -> {
        Naurt.start()
      }
      "stop" -> {
        Naurt.start()
      }
      "pause" -> {
        Naurt.pause()
      }
      "resume" -> {
        Naurt.resume(applicationContext)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    locationUpdateEventSink = events
  }

  override fun onCancel(arguments: Any?) {
    locationUpdateEventSink = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    currentActivity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    currentActivity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    currentActivity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    currentActivity = null
  }

  private suspend fun requestPermissions(vararg permissions: String): Boolean =
    suspendCancellableCoroutine { continuation -> requestPermissions(*permissions, continuation = continuation) }

  private fun requestPermissions(vararg permissions: String, continuation: CancellableContinuation<Boolean>) {
    val isRequestRequired =
      permissions
        .map { ActivityCompat.checkSelfPermission(applicationContext, it) }
        .any { result -> result == PackageManager.PERMISSION_DENIED }

    if(isRequestRequired) {
      val id = uid
      permissionListeners[id] = continuation
      ActivityCompat.requestPermissions(currentActivity!!, permissions, id)
    } else {
      continuation.resume(true)
    }
  }
  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    val isGranted = grantResults?.all { result -> result == PackageManager.PERMISSION_GRANTED } ?: false
    permissionListeners
      .remove(requestCode)
      ?.resume(isGranted)
    return isGranted
  }
}
