package app.taplock.taplock

import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val nfcChannelName = "app.taplock/nfc"
    private var tagSink: EventChannel.EventSink? = null
    private var pendingTag: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, nfcChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(
                    NfcAdapter.getDefaultAdapter(this)?.isEnabled == true
                )
                // Android is always listening for matching NDEF tags; there is
                // no scan session to start like on iOS.
                "scanOnce" -> result.success(null)
                "consumePendingTag" -> {
                    result.success(pendingTag)
                    pendingTag = null
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "$nfcChannelName/tags").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    tagSink = events
                    pendingTag?.let {
                        events.success(it)
                        pendingTag = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    tagSink = null
                }
            }
        )

        ShizukuBlockStrategy.register(flutterEngine, this)
        DeviceOwnerBlockStrategy.register(flutterEngine, this)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let(::handleNfcIntent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNfcIntent(intent)
    }

    private fun handleNfcIntent(intent: Intent) {
        val action = intent.action
        if (action != NfcAdapter.ACTION_NDEF_DISCOVERED &&
            action != NfcAdapter.ACTION_TAG_DISCOVERED
        ) return

        val messages = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            ?.filterIsInstance<NdefMessage>()
            ?: return

        for (message in messages) {
            for (record in message.records) {
                val url = parseUriRecord(record) ?: continue
                val sink = tagSink
                if (sink == null) pendingTag = url else sink.success(url)
            }
        }
    }

    /** Decodes a TNF_WELL_KNOWN / RTD_URI NDEF record into an https URL. */
    private fun parseUriRecord(record: NdefRecord): String? {
        if (record.tnf != NdefRecord.TNF_WELL_KNOWN ||
            !record.type.contentEquals(NdefRecord.RTD_URI)
        ) return null

        val payload = record.payload
        if (payload.isEmpty()) return null

        val prefixes = arrayOf(
            "", "http://www.", "https://www.", "http://", "https://",
            "tel:", "mailto:", "ftp://anonymous:anonymous@", "ftp://ftp.",
            "ftps://", "sftp://", "smb://", "nfs://", "ftp://", "dav://",
            "news:", "telnet://", "imap:", "rtsp://", "urn:", "sip:",
            "sips:", "tftp:", "btspp://", "btl2cap://", "btgoep://",
            "tcpobex://", "irdaobex://", "file://", "urn:epc:id:",
            "urn:epc:tag:", "urn:epc:pat:", "urn:epc:raw:", "urn:epc:",
            "urn:nfc:"
        )
        val identifierCode = (payload[0].toInt() and 0xFF)
        if (identifierCode >= prefixes.size) return null

        val body = String(payload.copyOfRange(1, payload.size), Charsets.UTF_8)
        return prefixes[identifierCode] + body
    }
}
