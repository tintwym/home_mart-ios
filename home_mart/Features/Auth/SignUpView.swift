//
//  SignUpView.swift
//  home_mart
//

import SwiftUI

struct SignUpView: View {
    @Binding var isShowingSignUp: Bool
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSubmitting = false
    @State private var signUpError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HomeMartAuthLogo()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                Text("Create an account")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Enter your details below to create your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    labeledField(title: "Full name") {
                        TextField("Your name", text: $name, axis: .horizontal)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .foregroundStyle(.primary)
                            .accessibilityLabel("Full name")
                            .authInputChrome()
                    }

                    labeledField(title: "Email") {
                        TextField("email@example.com", text: $email, axis: .horizontal)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.primary)
                            .tint(.primary)
                            .accessibilityLabel("Email")
                            .authInputChrome()
                    }

                    labeledField(title: "Password") {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.primary)
                            .tint(.primary)
                            .authInputChrome()
                    }

                    labeledField(title: "Confirm password") {
                        ConfirmPasswordField(text: $confirmPassword, placeholder: "Confirm password")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .authInputChrome()
                    }
                }
                .padding(.top, 4)

                if let err = signUpError, !err.isEmpty {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }

                Button {
                    Task {
                        signUpError = nil
                        isSubmitting = true
                        let ok = await AuthStore.shared.register(
                            name: name,
                            email: email,
                            password: password,
                            passwordConfirmation: confirmPassword
                        )
                        isSubmitting = false
                        if ok {
                            isShowingSignUp = false
                        } else {
                            signUpError = AuthStore.shared.lastError ?? "Could not create account."
                        }
                    }
                } label: {
                    Text(isSubmitting ? "Creating account…" : "Create account")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting)
                .padding(.top, 4)

                HStack(spacing: 4) {
                    Text("Already have an account?").foregroundStyle(.secondary)
                    Button("Log in") { isShowingSignUp = false }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
