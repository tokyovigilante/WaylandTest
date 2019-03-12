//
//  main.swift
//  Spitfire
//
//  Created by Ryan Walklin on 2018-11-17.
//  Copyright © 2018 Test Toast. All rights reserved.
//

import CWaylandClient
import Dispatch
import Foundation

public class WaylandWSIWindow {

    var _compositor: UnsafeMutableRawPointer! = nil

}

func handleGlobal(userdata: UnsafeMutableRawPointer?,
                          registry: OpaquePointer?, name: UInt32,
                          interface: UnsafePointer<Int8>?, version: UInt32) {
    guard let interfaceCString = interface, let userdata = userdata else {
        return
    }
    let window = Unmanaged<WaylandWSIWindow>.fromOpaque(userdata).takeUnretainedValue()
    let interfaceString = String(cString: interfaceCString)
    print("\(name): \(interfaceString) \(version)")
/*    if strcmp(interfaceCString, wl_compositor_interface.name) == 0 {

        withUnsafePointer(to: wl_compositor_interface) { interfacePointer in
            window._compositor = wl_registry_bind(registry, name,
                                                  interfacePointer, 1)
        }
        print("Bound wl_compositor")
    }*/
}

func handleGlobalRemove(data: UnsafeMutableRawPointer?,
                        registry: OpaquePointer?, name: UInt32) {
}

var registryListener = wl_registry_listener(
    global: handleGlobal,
    global_remove: handleGlobalRemove
)

let window = WaylandWSIWindow()

let unsafeSelf = Unmanaged.passUnretained(window).toOpaque()

guard let display = wl_display_connect(nil) else {
    print("Failed to create wl_display")
    exit(-1_)
}
print("Created wl_display")

let registry = wl_display_get_registry(display)
wl_registry_add_listener(registry, &registryListener, unsafeSelf)
wl_display_dispatch(display)
wl_display_roundtrip(display)

/*
        struct wl_registry *registry = wl_display_get_registry(display);
        wl_registry_add_listener(registry, &registry_listener, NULL);
        wl_display_dispatch(display);
        wl_display_roundtrip(display);

        if (shm == NULL || compositor == NULL || xdg_wm_base == NULL) {
            fprintf(stderr, "no wl_shm, wl_compositor or xdg_wm_base support\n");
            return EXIT_FAILURE;
        }

        struct wl_buffer *buffer = create_buffer();
        if (buffer == NULL) {
            return EXIT_FAILURE;
        }

        struct wl_surface *surface = wl_compositor_create_surface(compositor);
        struct xdg_surface *xdg_surface =
            xdg_wm_base_get_xdg_surface(xdg_wm_base, surface);
        xdg_toplevel = xdg_surface_get_toplevel(xdg_surface);

        xdg_surface_add_listener(xdg_surface, &xdg_surface_listener, NULL);
        xdg_toplevel_add_listener(xdg_toplevel, &xdg_toplevel_listener, NULL);

        wl_surface_commit(surface);
        wl_display_roundtrip(display);

        wl_surface_attach(surface, buffer, 0, 0);
        */

signal(SIGINT) { _ in
    exit(0)
}

dispatchMain()

