#if os(Linux)

import CWaylandClient
import Foundation
import XDGShell


private var registryListener = wl_registry_listener(
    global: handleGlobal,
    global_remove: handleGlobalRemove
)

private func handleGlobal(userdata: UnsafeMutableRawPointer?,
        registry: OpaquePointer?, name: UInt32, interface: UnsafePointer<Int8>?,
        version: UInt32) {
    guard let interface = interface, let userdata = userdata else {
        return
    }
    let window = Unmanaged<WaylandWSIWindow>.fromOpaque(userdata)
            .takeUnretainedValue()
    print("\(name): \(String(cString: interface)) \(version)")

    if (strcmp(interface, wl_seat_interface.name) == 0) {
        withUnsafePointer(to: wl_seat_interface) { pointer in
            let seat: OpaquePointer! = OpaquePointer(wl_registry_bind(registry, name, pointer, version))
            wl_seat_add_listener(seat, &seatListener, nil)
        }
        print("Bound wl_seat_interface")
    } else if (strcmp(interface, wl_compositor_interface.name) == 0) {
        withUnsafePointer(to: wl_compositor_interface) { pointer in
           window._compositor = OpaquePointer(wl_registry_bind(registry, name, pointer, version))
        }
        print("Bound wl_compositor_interface")
    } else if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
        withUnsafePointer(to: xdg_wm_base_interface) { pointer in
            window._xdg_wm_base = OpaquePointer(wl_registry_bind(registry, name, pointer, version))
        }
        print("Bound xdg_wm_base_interface")
    }
}

private func handleGlobalRemove (data: UnsafeMutableRawPointer?,
        registry: OpaquePointer?, name: UInt32) {
}

private var seatListener = wl_seat_listener(
    capabilities: seatHandleCapabilities,
    name: seatHandleName
)

private func seatHandleCapabilities (data: UnsafeMutableRawPointer?, seat: OpaquePointer?, capabilities: UInt32) {
    if capabilities & WL_SEAT_CAPABILITY_POINTER.rawValue != 0 {
        return
    }
    var pointer = wl_seat_get_pointer(seat)
    wl_pointer_add_listener(pointer, &pointerListener, &pointer)
    print("Added pointer listener")
}

private func seatHandleName (data: UnsafeMutableRawPointer?, seat: OpaquePointer?, name: UnsafePointer<Int8>?) {
    guard let name = name, let nameString = String(cString: name, encoding: .utf8) else {
        return
    }
    print("Seat name: \(nameString)")
}

private var pointerListener = wl_pointer_listener(
    enter: nil,
    leave: nil,
    motion: nil,
    button: nil,
    axis: nil,
    frame: nil,
    axis_source: nil,
    axis_stop: nil,
    axis_discrete: nil
)

public class WaylandWSIWindow: AirframeWindow {

    private (set) public var title: String
    private (set) public var width: Double
    private (set) public var height: Double
    private (set) public var scaleFactor: Double

    internal var _display: OpaquePointer! = nil

    internal var _xdg_wm_base: OpaquePointer! = nil
    fileprivate var _compositor: OpaquePointer! = nil
    internal var _surface: OpaquePointer! = nil
    internal var _xdg_toplevel: OpaquePointer! = nil

    public init? (title: String = "WaylandWSIWindow",
            width: Double = 640.0, height: Double = 480.0, scaleFactor: Double = 1.0) {

        self.title = title
        self.height = height
        self.width = width
        self.scaleFactor = scaleFactor

        let unsafeSelf = Unmanaged.passUnretained(self).toOpaque()

        guard let display = wl_display_connect(nil) else {
            print("Failed to create wl_display")
            return nil
        }
        _display = display

        let registry = wl_display_get_registry(display)
        wl_registry_add_listener(registry, &registryListener, unsafeSelf)
        wl_display_dispatch(display)
        wl_display_roundtrip(display)

        if _compositor == nil || _xdg_wm_base == nil {
            print("no wl_compositor or xdg_wm_base support")
            return nil
        }
    }

}

#endif
