import CoreNFC
import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate,
    FlutterStreamHandler, NFCNDEFReaderSessionDelegate {

    private let channelName = "app.taplock/nfc"
    private var tagSink: FlutterEventSink?
    private var pendingTag: String?
    private var readerSession: NFCNDEFReaderSession?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController
                as? FlutterViewController else {
            return super.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
        }

        let messenger = controller.binaryMessenger

        FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
            .setMethodCallHandler { [weak self] call, result in
                guard let self = self else { return }
                switch call.method {
                case "isAvailable":
                    result.success(NFCNDEFReaderSession.readingAvailable)
                case "scanOnce":
                    self.startScan()
                    result.success(nil)
                case "consumePendingTag":
                    result.success(self.pendingTag)
                    self.pendingTag = nil
                default:
                    result(FlutterMethodNotImplemented)
                }
            }

        FlutterEventChannel(
            name: "\(channelName)/tags",
            binaryMessenger: messenger
        ).setStreamHandler(self)

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    // MARK: - Background tag reads arrive as universal links, not CoreNFC events.

    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL,
           url.host?.lowercased() == "taplock.example" {
            emit(url.absoluteString)
        }
        return super.application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler
        )
    }

    // MARK: - FlutterEventChannel

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        tagSink = events
        if let tag = pendingTag {
            events(tag)
            pendingTag = nil
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        tagSink = nil
        return nil
    }

    private func emit(_ url: String) {
        if let sink = tagSink {
            sink(url)
        } else {
            pendingTag = url
        }
    }

    // MARK: - Foreground scanning

    private func startScan() {
        guard NFCNDEFReaderSession.readingAvailable else { return }
        readerSession = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        readerSession?.alertMessage = "Hold your phone near a Taplock tag."
        readerSession?.begin()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        for message in messages {
            for record in message.records {
                if let url = url(from: record) {
                    emit(url.absoluteString)
                }
            }
        }
        session.invalidate()
    }

    func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: Error
    ) {
        readerSession = nil
    }

    /// Decodes a well-known URI NDEF record (prefix byte + UTF-8 body).
    private func url(from record: NFCNDEFPayload) -> URL? {
        guard record.typeNameFormat == .URI,
              record.type == Data("U".utf8),
              let identifier = record.payload.first else {
            return nil
        }

        let prefixes = [
            "", "http://www.", "https://www.", "http://", "https://",
            "tel:", "mailto:", "ftp://anonymous:anonymous@", "ftp://ftp.",
            "ftps://", "sftp://", "smb://", "nfs://", "ftp://", "dav://",
            "news:", "telnet://", "imap:", "rtsp://", "urn:", "sip:",
            "sips:", "tftp:", "btspp://", "btl2cap://", "btgoep://",
            "tcpobex://", "irdaobex://", "file://", "urn:epc:id:",
            "urn:epc:tag:", "urn:epc:pat:", "urn:epc:raw:", "urn:epc:",
            "urn:nfc:"
        ]
        let code = Int(identifier)
        guard code < prefixes.count else { return nil }

        let body = String(decoding: record.payload.dropFirst(), as: UTF8.self)
        return URL(string: prefixes[code] + body)
    }
}
