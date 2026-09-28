// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "job_map",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "job-map", targets: ["job_map"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", "9.0.0"..<"10.0.0")
    ],
    targets: [
        .target(
            name: "job_map",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "GoogleMaps", package: "ios-maps-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(name: "job_mapTests", dependencies: ["job_map"])
    ]
)
