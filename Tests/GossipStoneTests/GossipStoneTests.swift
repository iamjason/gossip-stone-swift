import XCTest
@testable import GossipStone

final class GossipStoneTests: XCTestCase {
    func testInstallIDIsStableAndLowercaseUUID() {
        let a = GossipStone.installID
        let b = GossipStone.installID
        XCTAssertEqual(a, b)
        XCTAssertEqual(a, a.lowercased())
        XCTAssertNotNil(UUID(uuidString: a))
    }

    func testLaunchPropertiesCarryOnlyAllowedKeys() {
        let props = GossipStone.launchProperties()
        XCTAssertEqual(Set(props.keys), ["version", "os", "arch"])
        XCTAssertFalse(props["os"]!.isEmpty)
        XCTAssertTrue(["arm64", "x86_64", "unknown"].contains(props["arch"]!))
    }

    func testPayloadEncodesToCollectorShape() throws {
        let payload = GossipStone.Payload(app: "deku", event: "app_launched", ts: GossipStone.isoNow(), user: GossipStone.installID, props: ["version": "1.0", "os": "26.0", "arch": "arm64"])
        let data = try JSONEncoder().encode(payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["app", "event", "ts", "user", "props"])
        XCTAssertNotNil(ISO8601DateFormatter().date(from: (json["ts"] as! String).replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)))
    }

    func testDisabledUnderXCTest() {
        XCTAssertFalse(GossipStone.isEnabled)
    }
}
