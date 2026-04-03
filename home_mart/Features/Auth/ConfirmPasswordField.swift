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
        tf.autocapitalizationType = .none
        tf.keyboardType = .asciiCapable
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.borderStyle = .none
        tf.backgroundColor = .clear
        tf.textContentType = nil
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 8; allowed: ascii-printable;")
        tf.tintColor = .systemBlue
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
}
