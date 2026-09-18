# GossipStone (Swift)

The Swift client for [Gossip Stone](https://github.com/iamjason/gossip-stone), the self-hosted usage analytics behind the Hyrule Compendium apps. It records one `app_launched` event per launch and nothing else.

## Add it

Swift Package Manager, `https://github.com/iamjason/gossip-stone-swift.git`, from `0.1.0`. Requires macOS 14.

```swift
import GossipStone

@main
struct DekuApp: App {
    init() { GossipStone.start(app: "deku") }
    var body: some Scene { /* ... */ }
}
```

The `app` id must be registered with the collector. Sandboxed apps need `com.apple.security.network.client`.

## What is sent

One JSON POST per launch:

```json
{ "app": "deku", "event": "app_launched", "ts": "2026-09-17T15:04:05.000Z",
  "user": "6b1f...-install-uuid", "props": { "version": "0.2.38", "os": "26.0", "arch": "arm64" } }
```

- `user` is a random UUID created once per install and stored in `UserDefaults` under `GossipStone.installID`. The collector stores only a salted hash of it.
- Debug builds send nothing unless `GOSSIP_STONE_DEBUG=1` is set. Nothing is sent under XCTest.
- Requests time out after 5 seconds and failures are ignored; launch is never blocked.
