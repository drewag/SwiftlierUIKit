// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftlierUIKit",
    platforms: [.iOS(.v8)],
    products: [
        .library(name: "SwiftlierUIKit", targets: ["SwiftlierUIKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drewag/Swiftlier.git", from: "6.0.0"),
    ],
    targets: [
        .target(name: "SwiftlierUIKit", dependencies: ["Swiftlier"], path: "Sources"),
        .testTarget(name: "SwiftlierUIKitTests", dependencies: ["SwiftlierUIKit"]),
    ]
)
