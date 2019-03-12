// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "WaylandTest",
    products: [
        .executable(name: "WaylandTest", targets: ["WaylandTest"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(
            name: "CWaylandClient",
            pkgConfig: "wayland-client"),
        .target(
            name: "WaylandTest",
            dependencies: ["CWaylandClient"]),
    ]
)
