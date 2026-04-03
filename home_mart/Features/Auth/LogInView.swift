//
//  LogInView.swift
//  home_mart
//

import SwiftUI
import UIKit

struct LogInView: View {
    @Binding var isShowingSignUp: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isSubmitting = false
    @State private var loginError: String?

    var body: some View {
        VStack(spacing: 16) {
                HomeMartAuthLogo()
                    .padding(.top, 6)

                Text("Log in to your account").font(.title2).bold()
                Text("Enter your email and password below to log in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email").font(.subheadline).foregroundStyle(.primary)
                        TextField("email@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Email")
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password").font(.subheadline)
                            Spacer()
                            Button("Forgot password?") { /* action */ }
                                .font(.subheadline)
                        }
                        SecureField(
                            "Password",
                            text: $password,
                            prompt: Text("Password").foregroundStyle(Color(uiColor: .placeholderText))
                        )
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .tint(.primary)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                    }
                    Toggle("Remember me", isOn: $rememberMe)
                }
                .padding(.horizontal)

                if let err = loginError, !err.isEmpty {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
                .padding(.horizontal)
                .disabled(isSubmitting)

                HStack(spacing: 4) {
                    Text("Don't have an account?").foregroundStyle(.secondary)
                    Button("Sign up") { isShowingSignUp = true }
                }
                .font(.subheadline)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.bottom, 8)
    }
}
