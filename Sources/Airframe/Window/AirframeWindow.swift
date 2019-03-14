import Foundation

public protocol AirframeWindow {
    var width: Double { get }
    var height: Double { get }
    var title: String { get }
    var scaleFactor: Double { get }

    var pixelWidth: Int { get }
    var pixelHeight: Int { get }
}

extension AirframeWindow {

    public var pixelWidth: Int {
        return Int(width * scaleFactor)
    }

    public var pixelHeight: Int {
        return Int(height * scaleFactor)
    }
}
