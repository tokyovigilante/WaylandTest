import Airframe
import Foundation
import Dispatch

#if os(Linux)

signal(SIGINT) { _ in
    exit(0)
}

guard let window = WaylandWSIWindow() else {
    exit(-1)
}
dispatchMain()

#endif

