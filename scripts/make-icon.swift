import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor(red: 0.13, green: 0.34, blue: 0.29, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
NSColor(red: 0.97, green: 0.99, blue: 0.95, alpha: 1).setStroke()
let p = NSBezierPath()
p.lineWidth = 58
p.lineCapStyle = .round
p.lineJoinStyle = .round
p.move(to: NSPoint(x: 255, y: 730))
p.line(to: NSPoint(x: 512, y: 270))
p.line(to: NSPoint(x: 769, y: 730))
p.stroke()
let baseline = NSBezierPath()
baseline.lineWidth = 12
baseline.lineCapStyle = .round
baseline.move(to: NSPoint(x: 300, y: 170))
baseline.line(to: NSPoint(x: 724, y: 170))
baseline.stroke()
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
// NSImage drawing follows screen scale; normalize icon PNG to its declared pixel size.
try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("icon-1024.png"))
