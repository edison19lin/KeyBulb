// 產生 App 圖示（電燈泡 + 鍵盤）：swift tools/make_icon.swift AppIcon.png
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}
func circle(_ c: CGPoint, _ r: CGFloat) -> CGRect { CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2) }
func roundRect(_ rect: CGRect, _ r: CGFloat) -> CGPath { CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil) }

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// 左上角為原點
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

// macOS 圖示規格：1024 畫布內 824 的圓角方形
ctx.addPath(roundRect(CGRect(x: 100, y: 100, width: 824, height: 824), 185))
ctx.clip()
ctx.translateBy(x: 100, y: 100)
ctx.scaleBy(x: 824.0 / 1024, y: 824.0 / 1024)

func fillGradient(_ path: CGPath, _ colors: [CGColor], from: CGPoint, to: CGPoint) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let g = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

// 1. 背景：深酒紅漸層（跟其他電火 App 區別）
let bg = CGGradient(colorsSpace: space, colors: [rgb(0x2A0C16), rgb(0x8A2238)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])

// 2. 燈泡光暈
let center = CGPoint(x: 512, y: 410)
let glow = CGGradient(colorsSpace: space, colors: [rgb(0xFFE9A0, 0.75), rgb(0xFFE9A0, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: center, startRadius: 290, endCenter: center, endRadius: 560, options: [])

// 3. 燈泡
let bulb = CGMutablePath()
bulb.addEllipse(in: circle(center, 335))
bulb.move(to: CGPoint(x: 300, y: 665))
bulb.addLine(to: CGPoint(x: 724, y: 665))
bulb.addQuadCurve(to: CGPoint(x: 636, y: 815), control: CGPoint(x: 640, y: 730))
bulb.addLine(to: CGPoint(x: 388, y: 815))
bulb.addQuadCurve(to: CGPoint(x: 300, y: 665), control: CGPoint(x: 384, y: 730))
bulb.closeSubpath()
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 8), blur: 24, color: rgb(0x000000, 0.35))
ctx.addPath(bulb)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.95))
ctx.setLineWidth(20)
ctx.strokePath()
ctx.restoreGState()
fillGradient(bulb, [rgb(0xFFF8D6), rgb(0xFFCF47)], from: CGPoint(x: 512, y: 75), to: CGPoint(x: 512, y: 815))

// 4. 燈座
for (i, y) in [824, 870, 916].enumerated() {
    ctx.setFillColor(rgb(i == 1 ? 0xAEB8CC : 0xD5DCE8))
    let w: CGFloat = 256 - CGFloat(i) * 14
    ctx.addPath(roundRect(CGRect(x: 512 - w / 2, y: CGFloat(y), width: w, height: 40), 20))
    ctx.fillPath()
}
ctx.setFillColor(rgb(0x8C96AA))
ctx.addPath(roundRect(CGRect(x: 452, y: 960, width: 120, height: 44), 22))
ctx.fillPath()

// 5. 鍵盤：取代燈絲
let kb = CGRect(x: 512 - 250, y: 420 - 150, width: 500, height: 300)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 18, color: rgb(0x5A1020, 0.45))
ctx.setFillColor(rgb(0x3B1424))
ctx.addPath(roundRect(kb, 40))
ctx.fillPath()
ctx.restoreGState()

let pad: CGFloat = 30, gap: CGFloat = 12
let inner = kb.insetBy(dx: pad, dy: pad)
let rows = 4
let keyH = (inner.height - gap * CGFloat(rows - 1)) / CGFloat(rows)
func key(_ r: CGRect, _ color: UInt32) {
    ctx.setFillColor(rgb(color))
    ctx.addPath(roundRect(r, 10))
    ctx.fillPath()
}
// 前三排：一般按鍵
let counts = [8, 7, 7]
for (row, n) in counts.enumerated() {
    let y = inner.minY + CGFloat(row) * (keyH + gap)
    let indent: CGFloat = row == 0 ? 0 : (row == 1 ? 18 : 36)
    let width = inner.width - indent * 2
    let w = (width - gap * CGFloat(n - 1)) / CGFloat(n)
    for i in 0..<n {
        let x = inner.minX + indent + CGFloat(i) * (w + gap)
        key(CGRect(x: x, y: y, width: w, height: keyH), 0xFFF3D6)
    }
}
// 最後一排：⌘ 鍵 + 空白鍵 + ⌘ 鍵
let y4 = inner.minY + 3 * (keyH + gap)
let side: CGFloat = 70
key(CGRect(x: inner.minX, y: y4, width: side, height: keyH), 0xFFB347)
key(CGRect(x: inner.minX + side + gap, y: y4, width: inner.width - 2 * (side + gap), height: keyH), 0xFFF3D6)
key(CGRect(x: inner.maxX - side, y: y4, width: side, height: keyH), 0xFFB347)

// 6. 玻璃反光
ctx.setFillColor(rgb(0xFFFFFF, 0.75))
ctx.saveGState()
ctx.translateBy(x: 305, y: 215)
ctx.rotate(by: 0.75)
ctx.fillEllipse(in: CGRect(x: -26, y: -66, width: 52, height: 132))
ctx.restoreGState()

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
