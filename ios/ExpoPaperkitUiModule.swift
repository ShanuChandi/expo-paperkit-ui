import Foundation
import ExpoModulesCore
import PaperKit
import PencilKit
import UIKit

public class ExpoPaperkitUiModule: Module {
    private weak var currentView: ExpoPaperkitUiView?

    public func definition() -> ModuleDefinition {
        Name("ExpoPaperkitUi")

        OnCreate {
            ExpoPaperkitUiView.setModuleInstance(self)
        }

        // MARK: - View Definition
        View(ExpoPaperkitUiView.self) {
            Events(
                "onMarkupChanged",
                "onCanUndoChanged",
                "onCanRedoChanged",
                "onDrawStart",
                "onDrawEnd",
                "onDrawChange"
            )

            Prop("isEditable") { (view: ExpoPaperkitUiView, value: Bool) in
                view.setIsEditable(value)
            }
            Prop("isRulerActive") { (view: ExpoPaperkitUiView, value: Bool) in
                view.setIsRulerActive(value)
            }
            Prop("showsScrollIndicators") { (view: ExpoPaperkitUiView, value: Bool) in
                view.setShowsScrollIndicators(value)
            }
        }

        // MARK: - Tool Picker
        AsyncFunction("setupToolPicker") { (viewTag: Int) in
            await MainActor.run { self.currentView?.setupToolPicker() }
        }
        AsyncFunction("toggleToolPicker") { (viewTag: Int) in
            await MainActor.run { self.currentView?.toggleToolPicker() }
        }
        AsyncFunction("hideToolPicker") { (viewTag: Int) in
            await MainActor.run { self.currentView?.hideToolPicker() }
        }

        // MARK: - Undo / Redo / Clear
        AsyncFunction("undo") { (viewTag: Int) in
            await MainActor.run {
                self.currentView?.getPaperViewController()?.undoManager?.undo()
                self.currentView?.emitUndoRedoState()
            }
        }
        AsyncFunction("redo") { (viewTag: Int) in
            await MainActor.run {
                self.currentView?.getPaperViewController()?.undoManager?.redo()
                self.currentView?.emitUndoRedoState()
            }
        }
        AsyncFunction("clearDrawing") { (viewTag: Int) in
            await MainActor.run { self.clearCanvas() }
        }
        AsyncFunction("clearMarkup") { (viewTag: Int) in
            await MainActor.run { self.clearCanvas() }
        }
        AsyncFunction("canUndo") { (viewTag: Int) -> Bool in
            return await MainActor.run {
                self.currentView?.getPaperViewController()?.undoManager?.canUndo ?? false
            }
        }
        AsyncFunction("canRedo") { (viewTag: Int) -> Bool in
            return await MainActor.run {
                self.currentView?.getPaperViewController()?.undoManager?.canRedo ?? false
            }
        }

        // MARK: - Data Persistence
        AsyncFunction("captureDrawing") { (viewTag: Int) -> String in
            return await MainActor.run { self.currentView?.captureDrawing() ?? "" }
        }
        AsyncFunction("captureMarkup") { (viewTag: Int) -> String in
            return await MainActor.run { self.currentView?.captureDrawing() ?? "" }
        }
        AsyncFunction("getCanvasDataAsBase64") { (viewTag: Int) -> String in
            return await MainActor.run { self.currentView?.getCanvasDataAsBase64() ?? "" }
        }
        AsyncFunction("getMarkupDataAsBase64") { (viewTag: Int) -> String in
            return await MainActor.run { self.currentView?.getCanvasDataAsBase64() ?? "" }
        }
        AsyncFunction("setCanvasDataFromBase64") { (viewTag: Int, base64String: String) -> Bool in
            return await MainActor.run { self.currentView?.setCanvasDataFromBase64(base64String) ?? false }
        }
        AsyncFunction("setMarkupDataFromBase64") { (viewTag: Int, base64String: String) -> Bool in
            return await MainActor.run { self.currentView?.setCanvasDataFromBase64(base64String) ?? false }
        }

        // MARK: - Background Color
        AsyncFunction("setCanvasBackgroundColor") { (viewTag: Int, colorString: String) in
            await MainActor.run { self.currentView?.setCanvasBackgroundColor(colorString) }
        }
        AsyncFunction("getCanvasBackgroundColor") { (viewTag: Int) -> String in
            return await MainActor.run { self.currentView?.getCanvasBackgroundColor() ?? "FFFFFF" }
        }

        // MARK: - Color Picker
        AsyncFunction("showColorPicker") { (viewTag: Int) in
            await MainActor.run { self.currentView?.showColorPicker() }
        }

        // MARK: - View Background Color (area behind the canvas)
        AsyncFunction("setViewBackgroundColor") { (viewTag: Int, colorString: String) in
            await MainActor.run { self.currentView?.setViewBackgroundColor(colorString) }
        }
        AsyncFunction("getViewBackgroundColor") { (viewTag: Int) -> String in
            return await MainActor.run { self.currentView?.getViewBackgroundColor() ?? "FFFFFF" }
        }

        // MARK: - Canvas Aspect Ratio
        AsyncFunction("setCanvasAspectRatio") { (viewTag: Int, ratio: Double) in
            await MainActor.run { self.currentView?.setAspectRatio(CGFloat(ratio)) }
        }

        // MARK: - Background Pattern
        AsyncFunction("setBackgroundPattern") { (viewTag: Int, pattern: String) in
            await MainActor.run { self.currentView?.setBackgroundPattern(pattern) }
        }
        AsyncFunction("setBackgroundLineColor") { (viewTag: Int, color: String) in
            await MainActor.run { self.currentView?.setBackgroundLineColor(color) }
        }
        AsyncFunction("setBackgroundSpacing") { (viewTag: Int, spacing: Double) in
            await MainActor.run { self.currentView?.setBackgroundSpacing(CGFloat(spacing)) }
        }

        // MARK: - Add Elements Menu
        AsyncFunction("showAddMenu") { (viewTag: Int) in
            await MainActor.run { self.showAddMenu() }
        }

        // MARK: - Quick Add (programmatic, auto-switches to selection mode)
        AsyncFunction("insertShape") { (viewTag: Int, params: [String: Any]) in
            await MainActor.run { self.insertShape(params) }
        }
        AsyncFunction("insertTextbox") { (viewTag: Int, params: [String: Any]) in
            await MainActor.run { self.insertTextbox(params) }
        }
        AsyncFunction("insertLine") { (viewTag: Int, params: [String: Any]) in
            await MainActor.run { self.insertLine(params) }
        }
        AsyncFunction("insertImage") { (viewTag: Int, params: [String: Any]) in
            await MainActor.run { self.insertImage(params) }
        }

        // MARK: - Configuration
        AsyncFunction("setTouchMode") { (viewTag: Int, mode: String) in
            await MainActor.run { self.setTouchMode(mode) }
        }
        AsyncFunction("setZoomRange") { (viewTag: Int, min: Double, max: Double) in
            await MainActor.run { self.setZoomRange(min: min, max: max) }
        }
    }

    // MARK: - View Registration
    func registerView(_ view: ExpoPaperkitUiView) {
        self.currentView = view
    }
    func unregisterView() {
        self.currentView = nil
    }

    // MARK: - Private Implementations

    private func clearCanvas() {
        guard let paperVC = currentView?.getPaperViewController() else { return }
        let bounds = paperVC.markup?.bounds ?? CGRect(x: 0, y: 0, width: 800, height: 1000)
        paperVC.markup = PaperMarkup(bounds: bounds)
    }

    /// Shows the native PaperKit add menu by presenting the paper VC's
    /// edit controller FROM the paper VC itself, so the delegate
    /// connection is handled internally by PaperKit.
    private func showAddMenu() {
        guard let paperVC = currentView?.getPaperViewController() else { return }

        // Create MarkupEditViewController
        let editVC = MarkupEditViewController(supportedFeatureSet: .latest)
        editVC.modalPresentationStyle = .automatic

        // Present FROM the paper VC so PaperKit can connect them internally
        if let popover = editVC.popoverPresentationController {
            popover.sourceView = paperVC.view
            popover.sourceRect = CGRect(
                x: paperVC.view.bounds.midX,
                y: paperVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        paperVC.present(editVC, animated: true)
    }

    private func setTouchMode(_ mode: String) {
        guard let paperVC = currentView?.getPaperViewController() else { return }
        switch mode {
        case "drawing":
            paperVC.directTouchMode = .drawing
        case "selection":
            paperVC.directTouchMode = .selection
        default:
            paperVC.directTouchMode = .drawing
        }
    }

    private func setZoomRange(min: Double, max: Double) {
        guard let paperVC = currentView?.getPaperViewController() else { return }
        paperVC.zoomRange = CGFloat(min)...CGFloat(max)
    }

    // MARK: - Quick Add Shape
    private func insertShape(_ params: [String: Any]) {
        guard let paperVC = currentView?.getPaperViewController(),
              var markup = paperVC.markup else { return }

        let shapeType = mapShapeType(params["type"] as? String ?? "rectangle")
        let x = params["x"] as? CGFloat ?? 100
        let y = params["y"] as? CGFloat ?? 100
        let width = params["width"] as? CGFloat ?? 200
        let height = params["height"] as? CGFloat ?? 200
        let rotation = params["rotation"] as? CGFloat ?? 0
        let lineWidth = params["lineWidth"] as? CGFloat ?? 2.0

        let strokeColor = colorFromHex(params["strokeColor"] as? String ?? "000000")
        let fillColor: UIColor? = colorFromHexOptional(params["fillColor"] as? String)

        let config = ShapeConfiguration(
            type: shapeType,
            fillColor: fillColor?.cgColor,
            strokeColor: strokeColor.cgColor,
            lineWidth: lineWidth
        )

        markup.insertNewShape(
            configuration: config,
            frame: CGRect(x: x, y: y, width: width, height: height),
            rotation: rotation
        )
        paperVC.markup = markup

        // Auto-switch to selection mode so the user can immediately
        // tap, move, resize, and rotate the just-added shape
        paperVC.directTouchMode = .selection
    }

    // MARK: - Quick Add Textbox
    private func insertTextbox(_ params: [String: Any]) {
        guard let paperVC = currentView?.getPaperViewController(),
              var markup = paperVC.markup else { return }

        let text = params["text"] as? String ?? ""
        let x = params["x"] as? CGFloat ?? 100
        let y = params["y"] as? CGFloat ?? 100
        let width = params["width"] as? CGFloat ?? 200
        let height = params["height"] as? CGFloat ?? 50
        let rotation = params["rotation"] as? CGFloat ?? 0

        let attrString = NSAttributedString(string: text)
        markup.insertNewTextbox(
            attributedText: attrString,
            frame: CGRect(x: x, y: y, width: width, height: height),
            rotation: rotation
        )
        paperVC.markup = markup

        // Auto-switch to selection mode
        paperVC.directTouchMode = .selection
    }

    // MARK: - Quick Add Line
    private func insertLine(_ params: [String: Any]) {
        guard let paperVC = currentView?.getPaperViewController(),
              var markup = paperVC.markup else { return }

        let fromX = params["fromX"] as? CGFloat ?? 0
        let fromY = params["fromY"] as? CGFloat ?? 0
        let toX = params["toX"] as? CGFloat ?? 200
        let toY = params["toY"] as? CGFloat ?? 200
        let lineWidth = params["lineWidth"] as? CGFloat ?? 2.0
        let startMarker = params["startMarker"] as? Bool ?? false
        let endMarker = params["endMarker"] as? Bool ?? false

        let strokeColor = colorFromHex(params["strokeColor"] as? String ?? "000000")
        let config = ShapeConfiguration(
            type: .line,
            fillColor: nil,
            strokeColor: strokeColor.cgColor,
            lineWidth: lineWidth
        )

        markup.insertNewLine(
            configuration: config,
            from: CGPoint(x: fromX, y: fromY),
            to: CGPoint(x: toX, y: toY),
            startMarker: startMarker,
            endMarker: endMarker
        )
        paperVC.markup = markup

        // Auto-switch to selection mode
        paperVC.directTouchMode = .selection
    }

    // MARK: - Quick Add Image
    private func insertImage(_ params: [String: Any]) {
        guard let paperVC = currentView?.getPaperViewController(),
              var markup = paperVC.markup else { return }

        let x = params["x"] as? CGFloat ?? 100
        let y = params["y"] as? CGFloat ?? 100
        let width = params["width"] as? CGFloat ?? 200
        let height = params["height"] as? CGFloat ?? 200
        let rotation = params["rotation"] as? CGFloat ?? 0

        var cgImage: CGImage?

        // Option 1: base64 encoded image data
        if let base64String = params["base64"] as? String,
           let imageData = Data(base64Encoded: base64String),
           let uiImage = UIImage(data: imageData) {
            cgImage = uiImage.cgImage
        }

        // Option 2: URL (file:// or http(s)://)
        if cgImage == nil, let urlString = params["uri"] as? String,
           let url = URL(string: urlString),
           let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData) {
            cgImage = uiImage.cgImage
        }

        guard let finalImage = cgImage else { return }

        markup.insertNewImage(
            finalImage,
            frame: CGRect(x: x, y: y, width: width, height: height),
            rotation: rotation
        )
        paperVC.markup = markup

        // Auto-switch to selection mode
        paperVC.directTouchMode = .selection
    }

    // MARK: - Helpers
    private func mapShapeType(_ name: String) -> ShapeConfiguration.Shape {
        switch name {
        case "rectangle": return .rectangle
        case "roundedRectangle": return .roundedRectangle
        case "ellipse": return .ellipse
        case "line": return .line
        case "arrowShape": return .arrowShape
        case "chatBubble": return .chatBubble
        case "regularPolygon": return .regularPolygon
        case "star": return .star
        default: return .rectangle
        }
    }

    private func colorFromHex(_ hex: String) -> UIColor {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        if sanitized.count <= 6 {
            return UIColor(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            return UIColor(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgb & 0x000000FF) / 255.0
            )
        }
    }

    private func colorFromHexOptional(_ hex: String?) -> UIColor? {
        guard let hex = hex else { return nil }
        return colorFromHex(hex)
    }
}
