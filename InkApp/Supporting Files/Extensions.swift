//
//  Extensions.swift
//  Ink - Pattern Drawing App
//
//  Useful extensions for common operations
//  Created on November 10, 2025.
//

import UIKit
import CoreGraphics

// MARK: - CGPoint Extensions

extension CGPoint {
    /// Calculate distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt(dx * dx + dy * dy)
    }

    /// Linear interpolation between two points
    static func lerp(from: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t
        )
    }

    /// Add two points
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    /// Subtract two points
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /// Multiply point by scalar
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    /// Get center point of rect
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }

    /// Create rect from center and size
    init(center: CGPoint, size: CGSize) {
        self.init(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    /// Create color from hex string
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// Convert to hex string
    var hexString: String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        let a = components.count >= 4 ? Int(components[3] * 255.0) : 255

        if a < 255 {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

// MARK: - CGPath Extensions for Pattern Rendering

extension CGPath {
    /// Create path from line
    static func from(line: Line) -> CGPath {
        let path = CGMutablePath()
        path.move(to: line.start)
        path.addLine(to: line.end)
        return path
    }

    /// Create path from circle
    static func from(circle: Circle) -> CGPath {
        return CGPath(
            ellipseIn: CGRect(
                center: circle.center,
                size: CGSize(width: circle.radius * 2, height: circle.radius * 2)
            ),
            transform: nil
        )
    }

    /// Create path from arc
    static func from(arc: Arc) -> CGPath {
        let path = CGMutablePath()
        path.addArc(
            center: arc.center,
            radius: arc.radius,
            startAngle: arc.startAngle,
            endAngle: arc.endAngle,
            clockwise: false
        )
        return path
    }

    /// Create path from wave points
    static func from(wavePoints: [CGPoint]) -> CGPath {
        guard wavePoints.count >= 2 else { return CGMutablePath() }

        let path = CGMutablePath()
        path.move(to: wavePoints[0])

        for i in 1..<wavePoints.count {
            path.addLine(to: wavePoints[i])
        }

        return path
    }
}

// MARK: - Array Extensions

extension Array where Element == StrokePoint {
    /// Get simplified stroke (Douglas-Peucker algorithm)
    func simplified(tolerance: CGFloat = 2.0) -> [StrokePoint] {
        guard count > 2 else { return self }

        // Find point with maximum distance from line
        var maxDistance: CGFloat = 0
        var maxIndex = 0

        let start = first!.position
        let end = last!.position

        for i in 1..<count - 1 {
            let distance = self[i].position.distanceToLine(from: start, to: end)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        // If max distance is greater than tolerance, split
        if maxDistance > tolerance {
            let leftPoints = Array(self[0...maxIndex])
            let rightPoints = Array(self[maxIndex..<count])

            let leftSimplified = leftPoints.simplified(tolerance: tolerance)
            let rightSimplified = rightPoints.simplified(tolerance: tolerance)

            return leftSimplified.dropLast() + rightSimplified
        } else {
            return [first!, last!]
        }
    }
}

extension CGPoint {
    /// Calculate perpendicular distance from point to line
    func distanceToLine(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let lineLength = start.distance(to: end)
        if lineLength == 0 { return distance(to: start) }

        let dx = end.x - start.x
        let dy = end.y - start.y

        let numerator = abs(dy * x - dx * y + end.x * start.y - end.y * start.x)
        return numerator / lineLength
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format as readable string
    var readableString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Time ago string
    var timeAgoString: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
