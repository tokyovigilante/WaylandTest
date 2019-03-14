#if os(Linux)

//mport CEGL
import CWaylandClient
//import CWaylandEGL
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
            //var seat: OpaquePointer! = OpaquePointer(wl_registry_bind(registry, name, pointer, version))
            //wl_seat_add_listener(seat, &seatListener, nil)
        }
        print("Bound wl_seat_interface")
    } else if (strcmp(interface, wl_compositor_interface.name) == 0) {
        withUnsafePointer(to: wl_compositor_interface) { pointer in
           window._compositor = OpaquePointer(wl_registry_bind(registry, name, pointer, version))
        }
        print("Bound wl_compositor_interface")
    } else if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
        withUnsafePointer(to: xdg_wm_base_interface) { pointer in
            //window._xdg_wm_base = wl_registry_bind(registry, name, pointer, 1)
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
    let pointer = wl_seat_get_pointer(seat)
    /*withUnsafeMutablePointer(to: seat) { seatPointer in
        _ = wl_pointer_add_listener(pointer, &pointerListener, seatPointer)
    }*/
    print("Added pointer listener")
}

//var seatHandleName: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UnsafePointer<Int8>?) -> Void)? = { (data, seat, name) in
private func seatHandleName (data: UnsafeMutableRawPointer?, seat: OpaquePointer?, name: UnsafePointer<Int8>?) {
    guard let name = name, let nameString = String(cString: name, encoding: .utf8) else {
        return
    }
    print("Seat name: \(nameString)")
}

private func pointerHandleButton (data: UnsafeMutableRawPointer?, pointer: OpaquePointer?, serial: UInt32, time: UInt32, button: UInt32, state: UInt32) {
    //if button == BTN_LEFT && state == WL_POINTER_BUTTON_STATE_PRESSED {
        //xdg_toplevel_move(xdg_toplevel, data, serial)
    //}
}
/*
enter: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, OpaquePointer?, wl_fixed_t, wl_fixed_t) -> Void)?, leave: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, OpaquePointer?) -> Void)?, motion: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, wl_fixed_t, wl_fixed_t) -> Void)?, button: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, UInt32, UInt32, UInt32) -> Void)?, axis: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, UInt32, wl_fixed_t) -> Void)?, frame: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void)?, axis_source: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32) -> Void)?, axis_stop: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, UInt32) -> Void)?, axis_discrete: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt32, Int32) -> Void)?)
*/
private var pointerListener = wl_pointer_listener(
    enter: nil,
    leave: nil,
    motion: nil,
    button: pointerHandleButton,
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

    internal var _xdg_wm_base: UnsafeMutableRawPointer! = nil
    fileprivate var _compositor: OpaquePointer! = nil
    internal var _surface: OpaquePointer! = nil
    internal var _xdg_toplevel: OpaquePointer! = nil

    //static bool running = true;

    //private var eglDisplay: EGLDisplay? = nil
    //private var eglContext: EGLContext? = nil
    //private var eglSurface: EGLSurface? = nil

    /*static struct timespec last_frame = {0};
    static float color[3] = {0};
    static size_t dec = 0;*/

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
        /*egl_display = eglGetDisplay((EGLNativeDisplayType)display);
        if (egl_display == EGL_NO_DISPLAY) {
            fprintf(stderr, "failed to create EGL display\n");
            return EXIT_FAILURE;
        }*/
/*
        EGLint major, minor;
        if (!eglInitialize(egl_display, &major, &minor)) {
            fprintf(stderr, "failed to initialize EGL\n");
            return EXIT_FAILURE;
        }

        EGLint count;
        eglGetConfigs(egl_display, NULL, 0, &count);

        EGLint config_attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_RED_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_BLUE_SIZE, 8,
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
            EGL_NONE,
        };
        EGLint n = 0;
        EGLConfig *configs = calloc(count, sizeof(EGLConfig));
        eglChooseConfig(egl_display, config_attribs, configs, count, &n);
        if (n == 0) {
            fprintf(stderr, "failed to choose an EGL config\n");
            return EXIT_FAILURE;
        }
        EGLConfig egl_config = configs[0];

        EGLint context_attribs[] = {
            EGL_CONTEXT_CLIENT_VERSION, 2,
            EGL_NONE,
        };
        egl_context = eglCreateContext(egl_display, egl_config,
            EGL_NO_CONTEXT, context_attribs);

        surface = wl_compositor_create_surface(compositor);
        struct xdg_surface *xdg_surface =
            xdg_wm_base_get_xdg_surface(xdg_wm_base, surface);
        xdg_toplevel = xdg_surface_get_toplevel(xdg_surface);

        xdg_surface_add_listener(xdg_surface, &xdg_surface_listener, NULL);
        xdg_toplevel_add_listener(xdg_toplevel, &xdg_toplevel_listener, NULL);

        struct wl_egl_window *egl_window =
            wl_egl_window_create(surface, width, height);
        egl_surface = eglCreateWindowSurface(egl_display, egl_config,
            (EGLNativeWindowType)egl_window, NULL);

        wl_surface_commit(surface);
        wl_display_roundtrip(display);

        // Draw the first frame
        render();

        while (wl_display_dispatch(display) != -1 && running) {
            // This space intentionally left blank
        }

        xdg_toplevel_destroy(xdg_toplevel);
        xdg_surface_destroy(xdg_surface);
        wl_surface_destroy(surface);

        return EXIT_SUCCESS;*/
/*
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

        wl_surface_attach(surface, buffer, 0, 0);*/

    }


/*
        vkCreateWaylandSurfaceKHR()
            VkResult vkCreateWaylandSurfaceKHR(
                VkInstance                                  instance,
                const VkWaylandSurfaceCreateInfoKHR*        pCreateInfo,
                const VkAllocationCallbacks*                pAllocator,
                VkSurfaceKHR*                               pSurface);*/


/*
        typedef struct VkWaylandSurfaceCreateInfoKHR {
            VkStructureType                   sType;
            const void*                       pNext;
            VkWaylandSurfaceCreateFlagsKHR    flags;
            struct wl_display*                display;
            struct wl_surface*                surface;
        } VkWaylandSurfaceCreateInfoKHR;*/
}

#endif
/*

#define _POSIX_C_SOURCE 199309L
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>
#include <wayland-client-protocol.h>
#include <wayland-egl.h>
#ifdef __linux__
#include <linux/input-event-codes.h>
#elif __FreeBSD__
#include <dev/evdev/input-event-codes.h>
#endif

#include "xdg-shell-client-protocol.h"

static const int width = 128;
static const int height = 128;

static bool running = true;

static struct wl_compositor *compositor = NULL;
static struct xdg_wm_base *xdg_wm_base = NULL;

static struct wl_surface *surface = NULL;
static struct xdg_toplevel *xdg_toplevel = NULL;

static EGLDisplay egl_display = NULL;
static EGLContext egl_context = NULL;
static EGLSurface egl_surface = NULL;

static struct timespec last_frame = {0};
static float color[3] = {0};
static size_t dec = 0;



static void xdg_surface_handle_configure(void *data,
        struct xdg_surface *xdg_surface, uint32_t serial) {
    xdg_surface_ack_configure(xdg_surface, serial);
}

static const struct xdg_surface_listener xdg_surface_listener = {
    .configure = xdg_surface_handle_configure,
};

static void xdg_toplevel_handle_close(void *data,
        struct xdg_toplevel *xdg_toplevel) {
    running = false;
}

static const struct xdg_toplevel_listener xdg_toplevel_listener = {
    .configure = noop,
    .close = xdg_toplevel_handle_close,
};









static void render(void);

static void frame_handle_done(void *data, struct wl_callback *callback,
        uint32_t time) {
    wl_callback_destroy(callback);
    render();
}

static const struct wl_callback_listener frame_listener = {
    .done = frame_handle_done,
};

static void render(void) {
    // Update color
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);

    long ms = (ts.tv_sec - last_frame.tv_sec) * 1000 +
        (ts.tv_nsec - last_frame.tv_nsec) / 1000000;
    size_t inc = (dec + 1) % 3;
    color[inc] += ms / 2000.0f;
    color[dec] -= ms / 2000.0f;
    if (color[dec] < 0.0f) {
        color[inc] = 1.0f;
        color[dec] = 0.0f;
        dec = inc;
    }
    last_frame = ts;

    // And draw a new frame
    if (!eglMakeCurrent(egl_display, egl_surface, egl_surface, egl_context)) {
        fprintf(stderr, "eglMakeCurrent failed\n");
        exit(EXIT_FAILURE);
    }

    glClearColor(color[0], color[1], color[2], 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // By default, eglSwapBuffers blocks until we receive the next frame event.
    // This is undesirable since it makes it impossible to process other events
    // (such as input events) while waiting for the next frame event. Setting
    // the swap interval to zero and managing frame events manually prevents
    // this behavior.
    eglSwapInterval(egl_display, 0);

    // Register a frame callback to know when we need to draw the next frame
    struct wl_callback *callback = wl_surface_frame(surface);
    wl_callback_add_listener(callback, &frame_listener, NULL);

    // This will attach a new buffer and commit the surface
    if (!eglSwapBuffers(egl_display, egl_surface)) {
        fprintf(stderr, "eglSwapBuffers failed\n");
        exit(EXIT_FAILURE);
    }
}
*/
