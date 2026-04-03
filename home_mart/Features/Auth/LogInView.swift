//
//  LogInView.swift
//  home_mart
//

import SwiftUI

struct LogInView: View {
    @Binding var isShowingSignUp: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isSubmitting = false
    @State private var loginError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HomeMartAuthLogo()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                Text("Log in to your account")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Enter your email and password below to log in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
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

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Password")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 8)
                            Button("Forgot password?") { /* TODO: reset flow */ }
                                .font(.subheadline)
                        }
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.primary)
                            .tint(.primary)
                            .keyboardType(.asciiCapable)
                            .authInputChrome()
                    }
                }
                .padding(.top, 4)

                Toggle("Remember me", isOn: $rememberMe)
                    .padding(.top, 2)

                if let err = loginError, !err.isEmpty {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }

                Button {
                    Task {
                        loginError = nil
                        isSubmitting = true
                        let ok = await AuthStore.shared.login(email: email, password: password)
                        isSubmitting = false
                        if ok {
                            loginError = nil
                        } else {
                            loginError = AuthStore.shared.lastError ?? "Sign in failed."
                        }
                    }
                } label: {
                    Text(isSubmitting ? "Signing in…" : "Log in")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting)
                .padding(.top, 4)

                HStack(spacing: 4) {
                    Text("Don't have an account?").foregroundStyle(.secondary)
                    Button("Sign up") { isShowingSignUp = true }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.never)
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
