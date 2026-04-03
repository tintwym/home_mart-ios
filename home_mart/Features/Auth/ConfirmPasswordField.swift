//
//  ConfirmPasswordField.swift
//  home_mart
//

import SwiftUI
import UIKit

/// Matches a `SecureField` visually, but does **not** use `textContentType.password`.
/// iOS otherwise pairs two SwiftUI password fields and breaks typing / autofill on sign-up.
struct ConfirmPasswordField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.isSecureTextEntry = true
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .asciiCapable
        tf.smartDashesType = .no
        tf.smartQuotesType = .no
        tf.smartInsertDeleteType = .no
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.borderStyle = .none
        tf.backgroundColor = .clear
        tf.textContentType = nil
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 8; allowed: ascii-printable;")
        tf.tintColor = .label
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.setContentHuggingPriority(.required, for: .vertical)
        tf.setContentCompressionResistancePriority(.required, for: .vertical)
        tf.inputAssistantItem.leadingBarButtonGroups = []
        tf.inputAssistantItem.trailingBarButtonGroups = []
        if #available(iOS 17.0, *) {
            tf.inlinePredictionType = .no
        }
        applyPlaceholder(tf, placeholder)
        tf.text = text
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.binding = $text
        applyPlaceholder(uiView, placeholder)
        if uiView.text != text, !uiView.isFirstResponder {
            uiView.text = text
        }
    }

    private func applyPlaceholder(_ tf: UITextField, _ string: String) {
        tf.attributedPlaceholder = NSAttributedString(
            string: string,
            attributes: [.foregroundColor: UIColor.placeholderText]
        )
    }

    final class Coordinator: NSObject {
        var binding: Binding<String>

        init(binding: Binding<String>) {
            self.binding = binding
        }

        @objc func editingChanged(_ sender: UITextField) {
            binding.wrappedValue = sender.text ?? ""
        }
    }

    /// Single-line height; without this, SwiftUI often gives the representable unbounded vertical space.
    static func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        let font = uiView.font ?? UIFont.preferredFont(forTextStyle: .body)
        let height = max(22, ceil(font.lineHeight))
        guard let width = proposal.width, width > 0, width.isFinite else { return nil }
        return CGSize(width: width, height: height)
    }
}
