import UIKit

/// Pattern types supported as canvas backgrounds
enum CanvasBackgroundPattern: String {
    case none
    case lines
    case grid
    case dots
}

/// A non-interactive, transparent UIView that draws a tiling
/// ruled/grid/dot pattern using CoreGraphics.
/// It is inserted INTO PaperKit's internal paper surface view
/// so it scrolls, zooms, and resizes with the canvas.
class BackgroundPatternView: UIView {
    var pattern: CanvasBackgroundPattern = .none { didSet { setNeedsDisplay() } }
    var lineColor: UIColor = UIColor(white: 0.78, alpha: 1.0) { didSet { setNeedsDisplay() } }
    var spacing: CGFloat = 32.0 { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear       // transparent — only draws pattern lines
        isOpaque = false
        isUserInteractionEnabled = false  // does not intercept touches
        contentMode = .redraw
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tag = 9999  // unique tag to find/remove later
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        guard pattern != .none,
              let ctx = UIGraphicsGetCurrentContext() else { return }

        switch pattern {
        case .none:
            break
        case .lines:
            drawHorizontalLines(ctx: ctx, rect: rect)
        case .grid:
            drawHorizontalLines(ctx: ctx, rect: rect)
            drawVerticalLines(ctx: ctx, rect: rect)
        case .dots:
            drawDots(ctx: ctx, rect: rect)
        }
    }

    private func drawHorizontalLines(ctx: CGContext, rect: CGRect) {
        ctx.setStrokeColor(lineColor.cgColor)
        ctx.setLineWidth(0.5)

        let start = (rect.minY / spacing).rounded(.up) * spacing
        var y = start
        while y <= rect.maxY {
            ctx.move(to: CGPoint(x: rect.minX, y: y))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        ctx.strokePath()
    }

    private func drawVerticalLines(ctx: CGContext, rect: CGRect) {
        ctx.setStrokeColor(lineColor.cgColor)
        ctx.setLineWidth(0.5)

        let start = (rect.minX / spacing).rounded(.up) * spacing
        var x = start
        while x <= rect.maxX {
            ctx.move(to: CGPoint(x: x, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }
        ctx.strokePath()
    }

    private func drawDots(ctx: CGContext, rect: CGRect) {
        ctx.setFillColor(lineColor.cgColor)
        let dotR: CGFloat = 1.5

        let startY = (rect.minY / spacing).rounded(.up) * spacing
        var y = startY
        while y <= rect.maxY {
            let startX = (rect.minX / spacing).rounded(.up) * spacing
            var x = startX
            while x <= rect.maxX {
                ctx.fillEllipse(in: CGRect(
                    x: x - dotR, y: y - dotR,
                    width: dotR * 2, height: dotR * 2
                ))
                x += spacing
            }
            y += spacing
        }
    }
}
