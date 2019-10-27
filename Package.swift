// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "PagedArray",
    products: [
        .library(name: "PagedArray", targets: ["PagedArray"]),
    ],
    targets: [
        .target(name: "PagedArray", path: "Sources"),
        .testTarget(name: "PagedArrayTests", dependencies: ["PagedArray"], path: "Tests"),
    ]
)
