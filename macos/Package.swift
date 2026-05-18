// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Rakshak",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Rakshak", targets: ["RakshakApp"]),
        .executable(name: "RakshakDaemon", targets: ["RakshakDaemon"]),
        .library(name: "RakshakCore", targets: ["RakshakCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
    ],
    targets: [
        .target(
            name: "RakshakCore",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "Sources/RakshakCore"
        ),
        .target(
            name: "RakshakIPC",
            dependencies: ["RakshakCore"],
            path: "Sources/RakshakIPC"
        ),
        .target(
            name: "RakshakDNS",
            dependencies: ["RakshakCore"],
            path: "Sources/RakshakDNS",
            resources: [.process("Resources")]
        ),
        .target(
            name: "RakshakNetwork",
            dependencies: ["RakshakCore"],
            path: "Sources/RakshakNetwork"
        ),
        .target(
            name: "RakshakFirewall",
            dependencies: ["RakshakCore"],
            path: "Sources/RakshakFirewall"
        ),
        .target(
            name: "RakshakDaemonLib",
            dependencies: [
                "RakshakCore", "RakshakIPC", "RakshakDNS",
                "RakshakNetwork", "RakshakFirewall",
            ],
            path: "Sources/RakshakDaemonLib"
        ),
        .executableTarget(
            name: "RakshakDaemon",
            dependencies: ["RakshakDaemonLib"],
            path: "Sources/RakshakDaemon"
        ),
        .executableTarget(
            name: "RakshakApp",
            dependencies: ["RakshakCore", "RakshakIPC"],
            path: "Sources/RakshakApp",
            resources: [.process("Resources")]
        ),
    ]
)
