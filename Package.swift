// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PanelDesignKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "PanelDesignKit", targets: ["PanelDesignKit"]),
        .executable(name: "PanelDesignDemo", targets: ["PanelDesignDemo"])
    ],
    targets: [
        .target(
            name: "PanelDesignKit",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .executableTarget(
            name: "PanelDesignDemo",
            dependencies: ["PanelDesignKit"],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "PanelDesignKitTests",
            dependencies: ["PanelDesignKit"]
        )
    ]
)
