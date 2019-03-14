// swift-tools-version:5.git c0
import PackageDescription

let package = Package(
    name: "WaylandTest",
    products: [
        .executable(name: "WaylandTest", targets: ["WaylandTest"]),
        .library(name: "Airframe", targets: ["Airframe"])
    ],
    dependencies: [],
    targets: [
        .systemLibrary(
            name: "CWaylandClient",
            pkgConfig: "wayland-client"),
        .target(
             name: "XDGShell",
             dependencies: []),
        .target(
            name: "Airframe",
            dependencies: ["CWaylandClient",
                "XDGShell",]),
        .target(
            name: "WaylandTest",
            dependencies: [
                "Airframe"
            ]),
    ]
)
