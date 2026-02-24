import Foundation
import ExpoModulesCore
import PaperKit
import PencilKit
import UIKit

public class ExpoPaperkitUiView: ExpoView {
    // The PaperKit view controller
    private var paperViewController: PaperMarkupViewController?
    // Keep a strong reference so PKToolPicker stays alive
    private var toolPicker: PKToolPicker?
    // Whether tool picker is currently visible
    private var isToolPickerVisible: Bool = false
    // Color picker delegate (kept alive)
    private var colorPickerDelegate: ColorPickerDelegate?

    // Static reference to module
    private static weak var moduleInstance: ExpoPaperkitUiModule?

    // Event dispatchers
    let onMarkupChanged = EventDispatcher()
    let onCanUndoChanged = EventDispatcher()
    let onCanRedoChanged = EventDispatcher()
    let onDrawStart = EventDispatcher()
    let onDrawEnd = EventDispatcher()
    let onDrawChange = EventDispatcher()

    // Stored props
    private var isEditableValue: Bool = true
    private var isRulerActiveValue: Bool = false
    private var showsScrollIndicatorsValue: Bool = true
    private var canvasAspectRatio: CGFloat? = nil

    // Track state
    private var isViewAdded: Bool = false
    private var isVCMarried: Bool = false

    // Background Pattern — lives as our own child, never inside PaperKit's hierarchy
    private var patternView: BackgroundPatternView?
    private var activePattern: CanvasBackgroundPattern = .none
    private var patternLineColor: UIColor = UIColor(white: 0.78, alpha: 1.0)
    private var patternSpacing: CGFloat = 32.0

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)

        // Create PaperMarkupViewController
        let markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 800, height: 1000))
        paperViewController = PaperMarkupViewController(
            markup: markup,
            supportedFeatureSet: .latest
        )

        // Add paper VC's view immediately so the canvas is always visible
        if let paperVC = paperViewController {
            addSubview(paperVC.view)
            paperVC.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                paperVC.view.topAnchor.constraint(equalTo: topAnchor),
                paperVC.view.bottomAnchor.constraint(equalTo: bottomAnchor),
                paperVC.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                paperVC.view.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
            isViewAdded = true
        }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            ExpoPaperkitUiView.moduleInstance?.registerView(self)
            marryVCToParentIfNeeded()
        } else {
            ExpoPaperkitUiView.moduleInstance?.unregisterView()
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            marryVCToParentIfNeeded()
            // Auto-setup tool picker once in the window
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setupToolPicker()
            }
        }
    }

    private func marryVCToParentIfNeeded() {
        guard !isVCMarried,
              let paperVC = paperViewController,
              let parentVC = findViewController() else { return }

        parentVC.addChild(paperVC)
        paperVC.didMove(toParent: parentVC)
        isVCMarried = true

        // Apply stored props
        paperVC.isEditable = isEditableValue
        paperVC.isRulerActive = isRulerActiveValue
        if #available(iOS 26.1, *) {
            paperVC.showsHorizontalScrollIndicator = showsScrollIndicatorsValue
            paperVC.showsVerticalScrollIndicator = showsScrollIndicatorsValue
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        paperViewController?.view.frame = bounds
        // Keep pattern view matching our bounds
        patternView?.frame = bounds
    }

    static func setModuleInstance(_ module: ExpoPaperkitUiModule) {
        moduleInstance = module
    }

    // MARK: - Accessors for module
    func getPaperViewController() -> PaperMarkupViewController? {
        return paperViewController
    }

    // MARK: - Tool Picker
    func setupToolPicker() {
        guard let paperVC = paperViewController else { return }
        if toolPicker == nil {
            let picker = PKToolPicker()
            self.toolPicker = picker
        }
        guard let picker = toolPicker else { return }
        picker.addObserver(paperVC)
        picker.setVisible(true, forFirstResponder: paperVC.view)
        paperVC.view.becomeFirstResponder()
        isToolPickerVisible = true
    }

    func toggleToolPicker() {
        guard let paperVC = paperViewController,
              let picker = toolPicker else {
            setupToolPicker()
            return
        }
        isToolPickerVisible.toggle()
        picker.setVisible(isToolPickerVisible, forFirstResponder: paperVC.view)
        if isToolPickerVisible {
            paperVC.view.becomeFirstResponder()
        }
    }

    func hideToolPicker() {
        guard let paperVC = paperViewController,
              let picker = toolPicker else { return }
        picker.setVisible(false, forFirstResponder: paperVC.view)
        isToolPickerVisible = false
    }

    // MARK: - Canvas Background Color (the actual paper)
    func setCanvasBackgroundColor(_ colorString: String) {
        let color = colorFromHexString(colorString)
        applyBackgroundColorToCanvas(color)
    }

    func getCanvasBackgroundColor() -> String {
        guard let bgColor = paperViewController?.view.backgroundColor else {
            return "FFFFFF"
        }
        return hexStringFromColor(bgColor)
    }

    // MARK: - View Background Color (the area behind the canvas)
    func setViewBackgroundColor(_ colorString: String) {
        self.backgroundColor = colorFromHexString(colorString)
    }

    func getViewBackgroundColor() -> String {
        return hexStringFromColor(self.backgroundColor ?? .white)
    }

    /// Applies background color to all internal views of PaperKit's view hierarchy
    private func applyBackgroundColorToCanvas(_ color: UIColor) {
        guard let paperView = paperViewController?.view else { return }
        paperView.backgroundColor = color
        setBackgroundColorRecursively(view: paperView, color: color)
    }

    private func setBackgroundColorRecursively(view: UIView, color: UIColor) {
        for subview in view.subviews {
            if subview.tag == 9999 { continue }
            if let bg = subview.backgroundColor {
                var white: CGFloat = 0
                var alpha: CGFloat = 0
                bg.getWhite(&white, alpha: &alpha)
                if alpha > 0.5 {
                    subview.backgroundColor = color
                }
            }
            setBackgroundColorRecursively(view: subview, color: color)
        }
    }

    // MARK: - Color Picker
    func showColorPicker() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }

        let picker = UIColorPickerViewController()
        colorPickerDelegate = ColorPickerDelegate { [weak self] color in
            self?.applyBackgroundColorToCanvas(color)
        }
        picker.delegate = colorPickerDelegate
        topVC.present(picker, animated: true)
    }

    // MARK: - Background Pattern
    // Strategy: pattern view is our own child at index 0 (below paper VC's view).
    // When a pattern is active, we make PaperKit's internal views transparent
    // so the pattern shows through from below. This is stable because PaperKit
    // never touches our own children, only its internal hierarchy.

    func setBackgroundPattern(_ patternString: String) {
        let pat = CanvasBackgroundPattern(rawValue: patternString) ?? .none
        activePattern = pat

        if pat == .none {
            removePatternView()
            restorePaperKitBackgrounds()
            return
        }

        ensurePatternView()
        patternView?.pattern = pat
        makePaperKitTransparent()
    }

    func setBackgroundLineColor(_ colorString: String) {
        patternLineColor = colorFromHexString(colorString)
        patternView?.lineColor = patternLineColor
    }

    func setBackgroundSpacing(_ spacing: CGFloat) {
        patternSpacing = spacing
        patternView?.spacing = spacing
    }

    /// Creates the pattern view as our own child at index 0 (below paper VC's view).
    private func ensurePatternView() {
        if patternView != nil { return }

        let pv = BackgroundPatternView(frame: bounds)
        pv.backgroundColor = .white   // solid background under the pattern
        pv.isOpaque = true
        pv.lineColor = patternLineColor
        pv.spacing = patternSpacing
        insertSubview(pv, at: 0)       // below the paper VC's view
        patternView = pv
    }

    private func removePatternView() {
        patternView?.removeFromSuperview()
        patternView = nil
        activePattern = .none
    }

    /// Make PaperKit's internal views transparent so the pattern shows through.
    private func makePaperKitTransparent() {
        guard let paperView = paperViewController?.view else { return }
        paperView.backgroundColor = .clear
        paperView.isOpaque = false
        setTransparentRecursively(view: paperView)
    }

    private func setTransparentRecursively(view: UIView) {
        for subview in view.subviews {
            if subview.tag == 9999 { continue }
            if let bg = subview.backgroundColor {
                var white: CGFloat = 0
                var alpha: CGFloat = 0
                bg.getWhite(&white, alpha: &alpha)
                if alpha > 0.5 && white > 0.8 {
                    subview.backgroundColor = .clear
                    subview.isOpaque = false
                }
            }
            setTransparentRecursively(view: subview)
        }
    }

    /// Restore PaperKit's internal views to white (when pattern is removed)
    private func restorePaperKitBackgrounds() {
        guard let paperView = paperViewController?.view else { return }
        paperView.backgroundColor = .white
        paperView.isOpaque = true
        setWhiteRecursively(view: paperView)
    }

    private func setWhiteRecursively(view: UIView) {
        for subview in view.subviews {
            if subview.tag == 9999 { continue }
            if subview.backgroundColor == .clear || subview.backgroundColor == nil {
                subview.backgroundColor = .white
                subview.isOpaque = true
            }
            setWhiteRecursively(view: subview)
        }
    }

    // MARK: - Canvas Aspect Ratio
    func setAspectRatio(_ ratio: CGFloat) {
        canvasAspectRatio = ratio
        guard let paperVC = paperViewController else { return }
        let width: CGFloat = 800
        let height = width / ratio
        paperVC.markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: width, height: height))

        // Refresh pattern after markup replacement
        if activePattern != .none {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.patternView?.frame = self.bounds
                self.patternView?.setNeedsDisplay()
                self.makePaperKitTransparent()
            }
        }
    }

    // MARK: - Data Persistence
    func captureDrawing() -> String {
        guard let paperVC = paperViewController else { return "" }
        let renderer = UIGraphicsImageRenderer(bounds: paperVC.view.bounds)
        let image = renderer.image { _ in
            paperVC.view.drawHierarchy(in: paperVC.view.bounds, afterScreenUpdates: false)
        }
        return image.pngData()?.base64EncodedString() ?? ""
    }

    func getCanvasDataAsBase64() -> String {
        guard let paperVC = paperViewController,
              let markup = paperVC.markup else { return "" }
        var result = ""
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                let data = try await markup.dataRepresentation()
                result = data.base64EncodedString()
            } catch {
                result = ""
            }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    func setCanvasDataFromBase64(_ base64String: String) -> Bool {
        guard let data = Data(base64Encoded: base64String) else { return false }
        do {
            let markup = try PaperMarkup(dataRepresentation: data)
            paperViewController?.markup = markup
            return true
        } catch {
            return false
        }
    }

    // MARK: - Props
    func setIsEditable(_ editable: Bool) {
        isEditableValue = editable
        paperViewController?.isEditable = editable
    }

    func setIsRulerActive(_ active: Bool) {
        isRulerActiveValue = active
        paperViewController?.isRulerActive = active
    }

    func setShowsScrollIndicators(_ shows: Bool) {
        showsScrollIndicatorsValue = shows
        if #available(iOS 26.1, *) {
            paperViewController?.showsHorizontalScrollIndicator = shows
            paperViewController?.showsVerticalScrollIndicator = shows
        }
    }

    // MARK: - Undo/Redo state emit
    func emitUndoRedoState() {
        let canUndo = paperViewController?.undoManager?.canUndo ?? false
        let canRedo = paperViewController?.undoManager?.canRedo ?? false
        onCanUndoChanged(["canUndo": canUndo])
        onCanRedoChanged(["canRedo": canRedo])
    }

    // MARK: - Color Helpers
    private func colorFromHexString(_ hexString: String) -> UIColor {
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red, green, blue, alpha: CGFloat

        if hexSanitized.count <= 6 {
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
            alpha = 1.0
        } else {
            red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(rgb & 0x000000FF) / 255.0
        }

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func hexStringFromColor(_ color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let redInt = Int(red * 255.0)
        let greenInt = Int(green * 255.0)
        let blueInt = Int(blue * 255.0)

        return String(format: "%02X%02X%02X", redInt, greenInt, blueInt)
    }

    // MARK: - Helpers
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let vc = nextResponder as? UIViewController { return vc }
            responder = nextResponder
        }
        return nil
    }
}

// MARK: - Color Picker Delegate Helper

private class ColorPickerDelegate: NSObject, UIColorPickerViewControllerDelegate {
    private let onColorSelected: (UIColor) -> Void

    init(onColorSelected: @escaping (UIColor) -> Void) {
        self.onColorSelected = onColorSelected
        super.init()
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        onColorSelected(viewController.selectedColor)
        viewController.dismiss(animated: true)
    }

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        onColorSelected(viewController.selectedColor)
    }
}
