// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Afterthought",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "Afterthought",
            path: "Afterthought",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("SwiftData"),
                .linkedFramework("AppKit"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ImageIO"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("NaturalLanguage"),
            ]
        )
    ]
)
