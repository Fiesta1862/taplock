package app.taplock.taplock

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Strong Android tier: DevicePolicyManager.setPackagesSuspended().
 *
 * STATUS: scaffold only. It reports unavailable until device-owner provisioning
 * and an DeviceAdminReceiver are wired up. See docs/PLATFORM_SETUP.md.
 */
object DeviceOwnerBlockStrategy {
    private const val CHANNEL = "app.taplock/blocks/deviceOwner"
    private const val NOT_IMPLEMENTED =
        "Device owner strategy is not provisioned. See docs/PLATFORM_SETUP.md."

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(false)
            "currentState" -> result.success("unavailable")
            "apply", "release" -> result.success(
                mapOf(
                    "applied" to false,
                    "message" to NOT_IMPLEMENTED,
                )
            )
            else -> result.notImplemented()
        }
    }

    // Implementation sketch:
    //
    // val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
    //         as DevicePolicyManager
    // val admin = ComponentName(context, OwnerReceiver::class.java)
    // if (!dpm.isDeviceOwnerApp(context.packageName)) -> unavailable
    // dpm.setPackagesSuspended(admin, bundleIds.toTypedArray(), true)
    // dpm.setPackagesSuspended(admin, bundleIds.toTypedArray(), false) // release
    //
    // Add OwnerReceiver : DeviceAdminReceiver to the manifest and provision with:
    // adb shell dpm set-device-owner app.taplock.taplock/.OwnerReceiver
}
