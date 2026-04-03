//
//  UpdatePasswordView.swift
//  home_mart
//

import LocalAuthentication
import SwiftUI

/// Me → Password: change password with secure fields, validation, optional Face ID / Touch ID, and API call when the backend supports it.
struct UpdatePasswordView: View {
    @Bindable private var auth = AuthStore.shared

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var formError: String?
    @State private var showSuccessAlert = false

    private var mintSave: Color { Color(red: 0.52, green: 0.88, blue: 0.78) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Update password")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Ensure your account is using a long, random password to stay secure.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                passwordField(
                    title: "Current password",
                    placeholder: "Current password",
                    text: $currentPassword,
                    kind: .current
                )
                passwordField(
                    title: "New password",
                    placeholder: "New password",
                    text: $newPassword,
                    kind: .new
                )
                confirmPasswordField(
                    title: "Confirm password",
                    placeholder: "Confirm password",
                    text: $confirmPassword
                )

                if let formError, !formError.isEmpty {
                    Text(formError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await savePassword() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        } else {
                            Text("Save password")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(mintSave, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Password updated", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password was changed successfully.")
        }
    }

    private enum PasswordFieldKind {
        case current
        case new
    }

    private func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        kind: PasswordFieldKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            SecureField(
                placeholder,
                text: text,
                prompt: Text(placeholder).foregroundStyle(.tertiary)
            )
            .textContentType(kind == .current ? .password : .newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(fieldBackground)
        }
    }

    private func confirmPasswordField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            ConfirmPasswordField(text: text, placeholder: placeholder)
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(fieldBackground)
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            )
    }

    @MainActor
    private func savePassword() async {
        formError = nil

        do {
            try await BiometricAuthSettingsStore.shared.requireBiometricIfEnabled(
                localizedReason: "Confirm your identity to change your Home Mart password."
            )
        } catch {
            if let la = error as? LAError, la.code == .userCancel || la.code == .systemCancel || la.code == .userFallback {
                return
            }
            formError = error.localizedDescription
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let ok = await auth.updatePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            passwordConfirmation: confirmPassword
        )

        if ok {
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            showSuccessAlert = true
        } else {
            formError = auth.lastError ?? "Could not update password."
        }
    }
}

#Preview {
    NavigationStack {
        UpdatePasswordView()
    }
}
