// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RunWalkBreedPlugins",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HealthKitPlugin", type: .dynamic, targets: ["HealthKitPlugin"]),
        .library(name: "LocationPlugin", type: .dynamic, targets: ["LocationPlugin"]),
        .library(name: "MapViewPlugin", type: .dynamic, targets: ["MapViewPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
    ],
    targets: [
        .target(
            name: "HealthKitPlugin",
            dependencies: ["SwiftGodot"],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])],
            plugins: [.plugin(name: "EntryPointGeneratorPlugin", package: "SwiftGodot")]
        ),
        .target(
            name: "LocationPlugin",
            dependencies: ["SwiftGodot"],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])],
            plugins: [.plugin(name: "EntryPointGeneratorPlugin", package: "SwiftGodot")]
        ),
        .target(
            name: "MapViewPlugin",
            dependencies: ["SwiftGodot"],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])],
            plugins: [.plugin(name: "EntryPointGeneratorPlugin", package: "SwiftGodot")]
        ),
    ]
)
