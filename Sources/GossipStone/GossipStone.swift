import Foundation

/// Minimal usage telemetry client for the Hyrule Compendium apps.
///
/// Call ``start(app:endpoint:)`` once from your `App.init()`. It records one
/// `app_launched` event carrying the bundle version, macOS version and CPU
/// architecture, keyed by a random id generated once per install and stored in
/// `UserDefaults`. Nothing else is collected. Requests are fire-and-forget and
/// never block launch.
///
/// - Debug builds send nothing unless `GOSSIP_STONE_DEBUG=1` is in the environment.
/// - Nothing is sent while running under XCTest.
public enum GossipStone {
    /// The production collector.
    public static let defaultEndpoint = URL(string: "https://gossip-stone.iamjason.workers.dev/v1/events")!

    private static let installIDKey = "GossipStone.installID"
    private static let state = State()

    /// Configure the client and record an `app_launched` event.
    /// - Parameters:
    ///   - app: The app id registered with the collector (for example `"deku"`).
    ///   - endpoint: Override the collector URL, mainly for local testing.
    public static func start(app: String, endpoint: URL = defaultEndpoint) {
        state.configure(app: app, endpoint: endpoint)
        track("app_launched", launchProperties())
    }

    /// Record a custom event. The collector only accepts events it knows about,
    /// so add new event names to the registry first.
    public static func track(_ event: String, _ props: [String: String] = [:]) {
        guard isEnabled, let config = state.config else { return }
        let payload = Payload(app: config.app, event: event, ts: Self.isoNow(), user: installID, props: props)
        guard let body = try? JSONEncoder().encode(payload) else { return }
        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 5
        URLSession.shared.dataTask(with: request).resume()
    }

    /// The per-install identifier. Created on first use, never sent anywhere else.
    public static var installID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: installIDKey) { return existing }
        let fresh = UUID().uuidString.lowercased()
        defaults.set(fresh, forKey: installIDKey)
        return fresh
    }

    /// Whether events will actually be sent in this process.
    public static var isEnabled: Bool {
        let env = ProcessInfo.processInfo.environment
        if env["XCTestConfigurationFilePath"] != nil { return false }
        #if DEBUG
        return env["GOSSIP_STONE_DEBUG"] == "1"
        #else
        return true
        #endif
    }

    /// The properties attached to `app_launched`. Exposed for tests.
    public static func launchProperties(bundle: Bundle = .main) -> [String: String] {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let osString = os.patchVersion == 0
            ? "\(os.majorVersion).\(os.minorVersion)"
            : "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        return ["version": version, "os": osString, "arch": architecture]
    }

    static var architecture: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    static func isoNow() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    struct Payload: Encodable {
        let app: String
        let event: String
        let ts: String
        let user: String
        let props: [String: String]
    }

    struct Config: Sendable {
        let app: String
        let endpoint: URL
    }

    /// Lock-guarded configuration so `start` and `track` are safe from any thread.
    final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Config?

        var config: Config? {
            lock.lock(); defer { lock.unlock() }
            return stored
        }

        func configure(app: String, endpoint: URL) {
            lock.lock(); defer { lock.unlock() }
            stored = Config(app: app, endpoint: endpoint)
        }
    }
}
