import SwiftUI
import GameplayKit
import UIKit

struct SoilBackground: View {
    var body: some View {
        Image(uiImage: SoilTexture.image)
            .resizable(resizingMode: .tile)
            .accessibilityHidden(true)
    }
}

/// Bake the seamless soil once; dragging only composites this cached texture.
private enum SoilTexture {
    static let image: UIImage = makeImage()

    private static func makeImage() -> UIImage {
        let side = 384
        let random = GKLinearCongruentialRandomSource(seed: 0x5011)
        func samples(_ count: Int) -> [Double] {
            (0..<count).map { _ in Double(random.nextUniform()) }
        }
        let broad = samples(8 * 8)
        let clods = samples(32 * 32)
        let grit = samples(128 * 128)
        func noise(_ grid: [Double], count: Int, x: Int, y: Int) -> Double {
            let fx = Double(x) / Double(side) * Double(count)
            let fy = Double(y) / Double(side) * Double(count)
            let ix = Int(fx), iy = Int(fy)
            let tx = fx - Double(ix), ty = fy - Double(iy)
            let sx = tx * tx * (3 - 2 * tx), sy = ty * ty * (3 - 2 * ty)
            func sample(_ x: Int, _ y: Int) -> Double { grid[(y % count) * count + x % count] }
            let a = sample(ix, iy) * (1 - sx) + sample(ix + 1, iy) * sx
            let b = sample(ix, iy + 1) * (1 - sx) + sample(ix + 1, iy + 1) * sx
            return a * (1 - sy) + b * sy
        }
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        for y in 0..<side {
            for x in 0..<side {
                let large = noise(broad, count: 8, x: x, y: y)
                let medium = noise(clods, count: 32, x: x, y: y)
                let fine = noise(grit, count: 128, x: x, y: y)
                let grain = Double(random.nextUniform())
                let level = 0.035 + large * 0.055 + medium * 0.065 + fine * 0.06 + grain * 0.04
                let index = (y * side + x) * 4
                pixels[index] = UInt8(level * 255)
                pixels[index + 1] = UInt8(level * 0.69 * 255)
                pixels[index + 2] = UInt8(level * 0.43 * 255)
            }
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let bitmap = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
                             bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                             bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                             provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let result = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { renderer in
            UIImage(cgImage: bitmap).draw(in: CGRect(x: 0, y: 0, width: side, height: side))
            let context = renderer.cgContext
            for _ in 0..<900 {
                let x = CGFloat(random.nextUniform()) * CGFloat(side)
                let y = CGFloat(random.nextUniform()) * CGFloat(side)
                let radius = 0.6 + CGFloat(random.nextUniform()) * 2.7
                // Wrap marks at tile boundaries, preserving a seamless repeat.
                for dx in [-CGFloat(side), 0, CGFloat(side)] {
                    for dy in [-CGFloat(side), 0, CGFloat(side)] {
                        let rect = CGRect(x: x + dx, y: y + dy, width: radius * 2, height: radius)
                        context.setFillColor(UIColor(white: 0, alpha: 0.30).cgColor)
                        context.fillEllipse(in: rect.offsetBy(dx: 0, dy: 1))
                        context.setFillColor(UIColor(red: 0.30, green: 0.21, blue: 0.13, alpha: 0.32).cgColor)
                        context.fillEllipse(in: rect)
                    }
                }
            }
        }
        return UIImage(cgImage: result.cgImage!, scale: 2, orientation: .up)
    }
}
