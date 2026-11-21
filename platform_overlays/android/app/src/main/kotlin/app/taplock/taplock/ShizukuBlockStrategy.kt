package app.taplock.taplock

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Practical Android tier: run `pm suspend <pkg>` with shell-level permission
 * granted through Shizuku (https://github.com/RikkaApps/Shizuku).
 *
 * STATUS: scaffold only. It deliberately reports unavailable so the app never
 * claims enforcement it cannot deliver. See docs/PLATFORM_SETUP.md for the
 * implementation steps and the Gradle dependency to add.
 */
object ShizukuBlockStrategy {
    private const val CHANNEL = "app.taplock/blocks/shizuku"
    private const val NOT_IMPLEMENTED =
        "Shizuku strategy is not implemented yet. See docs/PLATFORM_SETUP.md."

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, context, result) }
    }

    private fun handle(call: MethodCall, context: Context, result: MethodChannel.Result) {
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

    // Implementation sketch (requires `dev.rikka.shizuku:api`):
    //
    // 1. if (Shizuku.checkSelfPermission() != PackageManager.PERMISSION_GRANTED)
    //       Shizuku.requestPermission(REQUEST_CODE)
    // 2. Use Shizuku.newProcess(arrayOf("pm", "suspend", *bundleIds), null, null)
    //    to suspend packages, and `pm unsuspend` on release.
    // 3. Verify with `pm list packages -d` (disabled packages).
    // 4. Persist the suspended list for release after reboot.
    // 5. Report `applied = true` only when every package was suspended.
}
