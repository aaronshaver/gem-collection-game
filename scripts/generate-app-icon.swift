// Run with `swift scripts/generate-app-icon.swift` from the project root.
// A code-drawn placeholder; attribute artwork belongs to Phase 2.
import AppKit

let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
NSColor(calibratedRed: 0.055, green: 0.10, blue: 0.13, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
for row in 0..<2 {
    for column in 0..<2 {
        let rect = NSRect(x: 214 + column * 310, y: 280 + row * 310, width: 286, height: 286)
        NSColor(calibratedRed: 0.36, green: 0.84, blue: 0.72, alpha: 1).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 38, yRadius: 38).fill()
    }
}
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 54, weight: .bold),
    .foregroundColor: NSColor.white, .paragraphStyle: paragraph
]
("FANTASY TILE MATCHER" as NSString).draw(in: NSRect(x: 60, y: 137, width: 904, height: 80), withAttributes: attributes)
NSGraphicsContext.restoreGraphicsState()
let path = "FantasyTileMatcher/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
