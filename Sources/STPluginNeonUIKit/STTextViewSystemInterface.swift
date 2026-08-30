import UIKit
import STTextViewUIKit
import Neon

class STTextViewSystemInterface: TextSystemInterface {

    typealias AttributeProvider = (Neon.Token) -> [NSAttributedString.Key: Any]?

    private let textView: STTextView
    private let attributeProvider: AttributeProvider

    init(textView: STTextView, attributeProvider: @escaping AttributeProvider) {
        self.textView = textView
        self.attributeProvider = attributeProvider
    }

    func clearStyle(in range: NSRange) {
        guard NSTextRange(range, in: textView.textContentManager) != nil else {
            assertionFailure()
            return
        }

        // NSTextLayoutManager's temporary rendering attributes crash on iOS
        // when Tree-sitter returns overlapping captures (Markdown commonly
        // does this for headings, links, and inline markup). Keep syntax
        // styling in the backing attributed string instead; character edits
        // are still the only changes observed by the plugin event pipeline.
        textView.addAttributes([
            .font: textView.font,
            .foregroundColor: textView.textColor,
        ], range: range)
    }

    func applyStyle(to token: Neon.Token) {
        guard let attrs = attributeProvider(token),
              NSTextRange(token.range, in: textView.textContentManager) != nil
        else {
            return
        }

        // Keep only the concrete attribute types supported by this adapter.
        var safeAttributes: [NSAttributedString.Key: Any] = [:]
        if let color = attrs[.foregroundColor] as? UIColor {
            safeAttributes[.foregroundColor] = color
        }
        if let font = attrs[.font] as? UIFont {
            safeAttributes[.font] = font
        }
        guard !safeAttributes.isEmpty else { return }
        textView.addAttributes(safeAttributes, range: token.range)
    }

    var length: Int {
        textView.textContentManager.length
    }

    var visibleRange: NSRange {
        guard let viewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange else {
            return .zero
        }

        return NSRange(viewportRange, provider: textView.textContentManager)
    }
}
