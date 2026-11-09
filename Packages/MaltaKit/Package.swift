// swift-tools-version:5.9
// Core of Malta 2027: money, settlement, trip seeds, live FX and Supabase sync.
// Foundation only: runs `swift test` on the Mac and targets iOS 17.
import PackageDescription

let package = Package(
    name: "MaltaKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "MaltaKit", targets: ["MaltaKit"])],
    targets: [
        .target(name: "MaltaKit"),
        .testTarget(name: "MaltaKitTests", dependencies: ["MaltaKit"]),
    ]
)
